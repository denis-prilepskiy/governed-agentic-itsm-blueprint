# Require human approval when risk score exceeds threshold
#
# Threshold is configurable. Default: 0.60.
# Returns a reason string for the evidence bundle.

package itsm.guardrails.require_approval_by_risk

import rego.v1

default risk_threshold := 0.60

needs_approval if {
  input.risk_score >= risk_threshold
}

reason := sprintf("risk_score %.2f >= threshold %.2f", [input.risk_score, risk_threshold]) if {
  needs_approval
}
