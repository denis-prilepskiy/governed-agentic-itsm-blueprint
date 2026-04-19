# Enforce environment exclusions
#
# Some environments (e.g., production-critical-tier0) are excluded
# from automated remediation entirely. Actions targeting these
# environments are always denied.
#
# Normalises environment data from multiple possible input shapes:
#   input.context.environments        (array)
#   input.context.environment         (string)
#   input.blast_radius.environments   (array — used in test fixtures)

package itsm.guardrails.enforce_environment_exclusions

import rego.v1

# Collect environments from all possible input locations
_environments contains env if {
  env := input.context.environments[_]
}

_environments contains env if {
  env := input.blast_radius.environments[_]
}

_environments contains env if {
  env := input.context.environment
}

violation contains msg if {
  count(input.workflow.scope.excluded_environments) > 0
  some env in _environments
  env in input.workflow.scope.excluded_environments
  msg := sprintf("environment '%s' is excluded from automated remediation", [env])
}
