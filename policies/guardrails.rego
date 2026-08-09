# Main guardrails policy — aggregates decisions from all policy modules
#
# Two modes of operation:
#
# 1. Standalone (single file):
#    opa eval --data policies/guardrails.rego \
#             --input examples/test-incidents/low-risk-cert-expiry.json \
#             "data.itsm.guardrails.decision"
#
#    Fallback logic (risk score, blast radius, prohibited tools, category)
#    is always active and sufficient for basic evaluation. Context-freshness
#    enforcement is NOT part of the fallback logic — it requires the full pack.
#
# 2. Full policy pack (recommended):
#    opa eval --data policies/ \
#             --input examples/test-incidents/low-risk-cert-expiry.json \
#             "data.itsm.guardrails.decision"
#
#    All modules are loaded; their violations are aggregated into the
#    final decision. Module violations can only escalate (make decisions
#    more restrictive), never relax them.
#
# Decision vocabulary
# -------------------
# This policy emits the three verdicts defined by
# schemas/policy-decision.schema.json. They map onto the conceptual verdicts
# used in the accompanying article and architecture diagrams as follows:
#
#   deny                  ←→ deny
#   needs-human-approval  ←→ require approval
#   auto-approve          ←→ admit with obligations
#
# In every case the decision carries `constraints`: the obligations under
# which an admitted plan may execute.

package itsm.guardrails

import rego.v1

# ─── Configuration ───────────────────────────────────────────────────────────
# Concrete tool contract names — kept in sync with schemas/tool-*.json

_allowed_categories := {"cert-expiry", "svc-restart", "dns-misconfig"}

_high_risk_tools := {"rollback_deployment", "iam_change", "dns_write"}

_prohibited_tools := {"delete_data", "disable_audit", "mass_restart"}

# Evidence fields that must be persisted before any side-effecting call.
# Mirrors workflow.evidence_bundle.must_attach_before_execute.
_required_evidence_fields := [
	"workflow_version",
	"plan_hash",
	"tool_contract_versions",
	"context_freshness",
	"signal_context",
	"service_context",
	"diagnostics_summary",
	"remediation_plan",
	"policy_decision",
	"rollback_plan",
]

# ─── Module aggregation ──────────────────────────────────────────────────────
# When loaded with --data policies/, these collect violations from all modules.
# When loaded standalone, module packages are undefined and sets are empty —
# the fallback checks below handle evaluation in that case.

_module_deny_violations contains v if {
	v := data.itsm.guardrails.deny_prohibited_tools.violation[_]
}

_module_deny_violations contains v if {
	v := data.itsm.guardrails.enforce_environment_exclusions.violation[_]
}

# Stale context denies the autonomous plan and hands the incident to the
# named human owner. It is a deny, not an approval request: a human
# signing off on a plan derived from stale data reproduces the original
# failure with a signature attached.
_module_deny_violations contains v if {
	v := data.itsm.guardrails.enforce_context_freshness.violation[_]
}

_module_soft_violations contains v if {
	v := data.itsm.guardrails.enforce_change_window.violation[_]
}

_module_soft_violations contains v if {
	v := data.itsm.guardrails.enforce_tool_call_budget.violation[_]
}

_module_soft_violations contains v if {
	v := data.itsm.guardrails.enforce_dry_run.violation[_]
}

_module_soft_violations contains v if {
	data.itsm.guardrails.require_approval_by_risk.needs_approval
	v := data.itsm.guardrails.require_approval_by_risk.reason
}

_module_soft_violations contains v if {
	data.itsm.guardrails.require_approval_by_blast_radius.needs_approval
	v := data.itsm.guardrails.require_approval_by_blast_radius.reason
}

# ─── Fallback checks (always active) ─────────────────────────────────────────
# These ensure the policy works standalone AND supplement module output
# when inputs lack workflow / plan.tool_calls structure.

_fallback_deny_violations contains "prohibited tool in plan" if {
	some t in input.plan.tools
	t in _prohibited_tools
}

_fallback_soft_violations contains "risk_score >= 0.60" if {
	input.risk_score >= 0.60
}

_fallback_soft_violations contains "multi-service blast radius" if {
	input.blast_radius.services_affected > 1
}

_fallback_soft_violations contains "plan contains high-risk tool" if {
	some t in input.plan.tools
	t in _high_risk_tools
}

_fallback_soft_violations contains "incident category not in allowlist" if {
	not input.incident.category in _allowed_categories
}

# ─── Aggregation ─────────────────────────────────────────────────────────────

_all_deny_violations := _module_deny_violations | _fallback_deny_violations

_all_soft_violations := _module_soft_violations | _fallback_soft_violations

# ─── Obligations ─────────────────────────────────────────────────────────────
# Constraints returned alongside every admitting verdict. The policy engine
# does not only answer "may this run?" — it answers "under what conditions".

_constraints(max_calls) := {
	"max_tool_calls": max_calls,
	"must_use_dry_run_first": true,
	"must_validate_after": true,
	"timeout_seconds": 180,
	"required_evidence_fields": _required_evidence_fields,
	"approval_binds_to_plan_hash": true,
	"fallback_on_timeout": "escalate_to_named_owner",
}

# ─── Decision ────────────────────────────────────────────────────────────────
# Outputs the `decision` field required by schemas/policy-decision.schema.json:
#   deny                 — plan must not proceed
#   needs-human-approval — plan may proceed after sign-off
#   auto-approve         — plan may proceed automatically

default decision := {
	"decision": "deny",
	"allow": false,
	"require_approval": false,
	"reasons": ["default-deny: no matching rule"],
	"constraints": {},
}

decision := {
	"decision": "deny",
	"allow": false,
	"require_approval": false,
	"reasons": [v | v := _all_deny_violations[_]],
	"constraints": {"fallback_on_timeout": "escalate_to_named_owner"},
} if {
	count(_all_deny_violations) > 0
}

decision := {
	"decision": "needs-human-approval",
	"allow": true,
	"require_approval": true,
	"reasons": [v | v := _all_soft_violations[_]],
	"constraints": _constraints(3),
} if {
	count(_all_deny_violations) == 0
	count(_all_soft_violations) > 0
}

decision := {
	"decision": "auto-approve",
	"allow": true,
	"require_approval": false,
	"reasons": ["all policy checks passed"],
	"constraints": _constraints(5),
} if {
	count(_all_deny_violations) == 0
	count(_all_soft_violations) == 0
}
