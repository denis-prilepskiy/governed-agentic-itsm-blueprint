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
#    is always active and sufficient for basic evaluation.
#
# 2. Full policy pack (recommended):
#    opa eval --data policies/ \
#             --input examples/test-incidents/low-risk-cert-expiry.json \
#             "data.itsm.guardrails.decision"
#
#    All modules are loaded; their violations are aggregated into the
#    final decision. Module violations can only escalate (make decisions
#    more restrictive), never relax them.

package itsm.guardrails

import rego.v1

# ─── Configuration ───────────────────────────────────────────────────────────
# Concrete tool contract names — kept in sync with schemas/tool-*.json

_allowed_categories := {"cert-expiry", "svc-restart", "dns-misconfig"}

_high_risk_tools := {"rollback_deployment", "iam_change", "dns_write"}

_prohibited_tools := {"delete_data", "disable_audit", "mass_restart"}

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

# ─── Decision ────────────────────────────────────────────────────────────────
# Outputs the `decision` field required by schemas/policy-decision.schema.json:
#   deny               — plan must not proceed
#   needs-human-approval — plan may proceed after sign-off
#   auto-approve       — plan may proceed automatically

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
  "constraints": {},
} if {
  count(_all_deny_violations) > 0
}

decision := {
  "decision": "needs-human-approval",
  "allow": true,
  "require_approval": true,
  "reasons": [v | v := _all_soft_violations[_]],
  "constraints": {
    "max_tool_calls": 3,
    "must_use_dry_run_first": true,
    "must_validate_after": true,
  },
} if {
  count(_all_deny_violations) == 0
  count(_all_soft_violations) > 0
}

decision := {
  "decision": "auto-approve",
  "allow": true,
  "require_approval": false,
  "reasons": ["all policy checks passed"],
  "constraints": {
    "max_tool_calls": 5,
    "must_use_dry_run_first": true,
    "must_validate_after": true,
  },
} if {
  count(_all_deny_violations) == 0
  count(_all_soft_violations) == 0
}
