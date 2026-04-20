# Enforce dry-run before live execution
#
# If the workflow declaration requires dry_run_first, verify that each
# mutating tool invocation is preceded by a dry-run invocation of the
# same tool.
#
# Tools that do not support dry-run (read-only validators, notification
# tools, record-keeping tools) are exempt. This list mirrors the
# `safety.supports_dry_run == false` flag in the corresponding tool
# contracts under schemas/.
#
# Production adaptation: in a real deployment, this list should be
# generated from tool contract metadata rather than hardcoded.

package itsm.guardrails.enforce_dry_run

import rego.v1

# Tools exempt from dry-run enforcement (supports_dry_run: false in contracts)
_tools_without_dry_run := {
  "validate_service_health",
  "notify_stakeholders",
  "open_change_record",
  "restart_service_rollback",
}

violation contains msg if {
  input.workflow.guardrails.must_use_dry_run_first == true
  some i, tool in input.plan.tool_calls
  tool.dry_run != true
  not tool.tool_name in _tools_without_dry_run
  not _preceded_by_dry_run(input.plan.tool_calls, i, tool.tool_name)
  msg := sprintf("tool '%s' at step %d has no preceding dry-run invocation", [tool.tool_name, i])
}

_preceded_by_dry_run(calls, idx, name) if {
  some j
  j < idx
  calls[j].tool_name == name
  calls[j].dry_run == true
}
