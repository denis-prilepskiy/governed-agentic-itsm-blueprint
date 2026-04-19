# Deny prohibited tools — hard block, no override
#
# Tools in this list are never allowed regardless of risk score,
# approval status, or incident category.

package itsm.guardrails.deny_prohibited_tools

import rego.v1

prohibited_tools := {"delete_data", "disable_audit", "mass_restart"}

violation contains msg if {
  some t in input.plan.tools
  t in prohibited_tools
  msg := sprintf("prohibited tool in plan: %s", [t])
}
