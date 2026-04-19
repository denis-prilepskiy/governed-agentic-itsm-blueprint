# Enforce environment exclusions
#
# Some environments (e.g., production-critical-tier0) are excluded
# from automated remediation entirely. Actions targeting these
# environments are always denied.

package itsm.guardrails.enforce_environment_exclusions

import rego.v1

violation contains msg if {
  some env in input.context.environments
  env in input.workflow.scope.excluded_environments
  msg := sprintf("environment '%s' is excluded from automated remediation", [env])
}
