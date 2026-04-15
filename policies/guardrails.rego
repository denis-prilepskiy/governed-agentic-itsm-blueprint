# Governed agentic ITSM — risk gating policy
#
# This policy evaluates an agent's remediation plan and returns
# a decision: allow (auto-execute), require approval, or deny.
#
# Usage:
#   opa eval --data policies/guardrails.rego \
#            --input examples/test-incidents/low-risk-cert-expiry.json \
#            "data.itsm.guardrails.decision"

package itsm.guardrails

# ───────────────────────────────────────────
# Default: deny everything (fail-closed)
# ───────────────────────────────────────────

default decision = {
  "allow": false,
  "require_approval": true,
  "reasons": ["default-deny: no matching rule"],
  "constraints": {}
}

# ───────────────────────────────────────────
# Hard deny: never allow these tools
# ───────────────────────────────────────────

decision = {
  "allow": false,
  "require_approval": false,
  "reasons": ["hard-deny: prohibited tool in plan"],
  "constraints": {}
} {
  contains_prohibited_tool
}

# ───────────────────────────────────────────
# Auto-approve: low risk + allowlisted
# ───────────────────────────────────────────

decision = {
  "allow": true,
  "require_approval": false,
  "reasons": ["low-risk, allowlisted category and tools"],
  "constraints": {
    "max_tool_calls": 5,
    "must_use_dry_run_first": true,
    "must_validate_after": true
  }
} {
  not contains_prohibited_tool
  not contains_high_risk_tool
  input.incident.category in allowed_categories
  input.risk_score < 0.60
  input.blast_radius.services_affected <= 1
}

# ───────────────────────────────────────────
# Require approval: elevated risk
# ───────────────────────────────────────────

decision = {
  "allow": true,
  "require_approval": true,
  "reasons": approval_reasons,
  "constraints": {
    "max_tool_calls": 3,
    "must_use_dry_run_first": true,
    "must_validate_after": true
  }
} {
  not contains_prohibited_tool
  needs_approval
  approval_reasons := compute_approval_reasons
}

# ───────────────────────────────────────────
# Helper: determine if approval is needed
# ───────────────────────────────────────────

needs_approval {
  input.risk_score >= 0.60
}

needs_approval {
  input.blast_radius.services_affected > 1
}

needs_approval {
  contains_high_risk_tool
}

needs_approval {
  not input.incident.category in allowed_categories
}

# ───────────────────────────────────────────
# Helper: compute human-readable reasons
# ───────────────────────────────────────────

compute_approval_reasons = reasons {
  reasons := array.concat(
    array.concat(
      array.concat(
        risk_score_reasons,
        blast_radius_reasons
      ),
      tool_reasons
    ),
    category_reasons
  )
}

risk_score_reasons = ["risk_score >= 0.60"] {
  input.risk_score >= 0.60
} else = []

blast_radius_reasons = ["multi-service blast radius"] {
  input.blast_radius.services_affected > 1
} else = []

tool_reasons = ["plan contains high-risk tool"] {
  contains_high_risk_tool
} else = []

category_reasons = ["incident category not in allowlist"] {
  not input.incident.category in allowed_categories
} else = []

# ───────────────────────────────────────────
# Configuration: allowlists
# ───────────────────────────────────────────

allowed_categories = {"cert-expiry", "svc-restart", "dns-misconfig"}

high_risk_tools = {"deploy", "iam_change", "dns_write"}

prohibited_tools = {"delete_data", "disable_audit", "mass_restart"}

# ───────────────────────────────────────────
# Helper: tool classification
# ───────────────────────────────────────────

contains_high_risk_tool {
  some t
  t := input.plan.tools[_]
  t in high_risk_tools
}

contains_prohibited_tool {
  some t
  t := input.plan.tools[_]
  t in prohibited_tools
}
