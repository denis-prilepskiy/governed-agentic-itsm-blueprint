# Enforce dry-run before live execution
#
# If the workflow declaration requires dry_run_first,
# verify that the plan includes a dry-run step before
# any mutating tool call.

package itsm.guardrails.enforce_dry_run

import rego.v1

violation contains msg if {
  input.workflow.guardrails.must_use_dry_run_first == true
  some i, tool in input.plan.tool_calls
  tool.dry_run != true
  not _preceded_by_dry_run(input.plan.tool_calls, i, tool.tool_name)
  msg := sprintf("tool '%s' at step %d has no preceding dry-run invocation", [tool.tool_name, i])
}

_preceded_by_dry_run(calls, idx, name) if {
  some j
  j < idx
  calls[j].tool_name == name
  calls[j].dry_run == true
}
