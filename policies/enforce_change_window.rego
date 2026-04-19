# Enforce change window restrictions
#
# Blocks or escalates remediation actions attempted outside
# allowed change windows defined in the workflow declaration.

package itsm.guardrails.enforce_change_window

import rego.v1

needs_approval if {
  count(input.workflow.scope.change_windows_allowed) > 0
  not input.context.change_window in cast_set(input.workflow.scope.change_windows_allowed)
}

violation contains msg if {
  needs_approval
  msg := sprintf(
    "current change window '%s' not in allowed windows %v",
    [input.context.change_window, input.workflow.scope.change_windows_allowed],
  )
}
