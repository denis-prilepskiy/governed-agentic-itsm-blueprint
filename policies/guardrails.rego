# Main guardrails policy — orchestrates all policy modules
#
# This is the entry point for policy evaluation. It aggregates
# decisions from individual modules and returns a single verdict.
#
# Usage (standalone, without modules):
#   opa eval --data policies/guardrails.rego \
#            --input examples/test-incidents/low-risk-cert-expiry.json \
#            "data.itsm.guardrails.decision"
#
# Usage (with modules):
#   opa eval --data policies/ \
#            --input examples/test-incidents/low-risk-cert-expiry.json \
#            "data.itsm.guardrails.decision"

package itsm.guardrails

# ───────────────────────────────────────────
# Configuration
# ───────────────────────────────────────────

allowed_categories := {"cert-expiry", "svc-restart", "dns-misconfig"}

high_risk_tools := {"deploy", "iam_change", "dns_write"}

prohibited_tools := {"delete_data", "disable_audit", "mass_restart"}

# ───────────────────────────────────────────
# Default: deny everything (fail-closed)
# ───────────────────────────────────────────

default decision := {
  "allow": false,
  "require_approval": true,
  "reasons": ["default-deny: no matching rule"],
  "constraints": {},
}

# ───────────────────────────────────────────
# Hard deny: prohibited tools
# ───────────────────────────────────────────

decision := {
  "allow": false,
  "require_approval": false,
  "reasons": ["hard-deny: prohibited tool in plan"],
  "constraints": {},
} if {
  _contains_prohibited_tool
}

# ───────────────────────────────────────────
# Auto-approve: low risk + allowlisted
# ───────────────────────────────────────────

decision := {
  "allow": true,
  "require_approval": false,
  "reasons": ["low-risk, allowlisted category and tools"],
  "constraints": {
    "max_tool_calls": 5,
    "must_use_dry_run_first": true,
    "must_validate_after": true,
  },
} if {
  not _contains_prohibited_tool
  not _contains_high_risk_tool
  input.incident.category in allowed_categories
  input.risk_score < 0.60
  input.blast_radius.services_affected <= 1
}

# ───────────────────────────────────────────
# Require approval: elevated risk
# ───────────────────────────────────────────

decision := {
  "allow": true,
  "require_approval": true,
  "reasons": _approval_reasons,
  "constraints": {
    "max_tool_calls": 3,
    "must_use_dry_run_first": true,
    "must_validate_after": true,
  },
} if {
  not _contains_prohibited_tool
  _needs_approval
}

# ───────────────────────────────────────────
# Internal helpers
# ───────────────────────────────────────────

_needs_approval if { input.risk_score >= 0.60 }
_needs_approval if { input.blast_radius.services_affected > 1 }
_needs_approval if { _contains_high_risk_tool }
_needs_approval if { not input.incident.category in allowed_categories }

_approval_reasons := array.concat(
  array.concat(
    array.concat(_risk_reasons, _blast_reasons),
    _tool_reasons,
  ),
  _category_reasons,
)

_risk_reasons := ["risk_score >= 0.60"] if {
  input.risk_score >= 0.60
} else := []

_blast_reasons := ["multi-service blast radius"] if {
  input.blast_radius.services_affected > 1
} else := []

_tool_reasons := ["plan contains high-risk tool"] if {
  _contains_high_risk_tool
} else := []

_category_reasons := ["incident category not in allowlist"] if {
  not input.incident.category in allowed_categories
} else := []

_contains_high_risk_tool if {
  some t in input.plan.tools
  t in high_risk_tools
}

_contains_prohibited_tool if {
  some t in input.plan.tools
  t in prohibited_tools
}
