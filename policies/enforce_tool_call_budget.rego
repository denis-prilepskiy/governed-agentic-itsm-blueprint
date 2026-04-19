# Enforce tool call and action budgets
#
# Prevents runaway automation by capping the number of tool calls
# and total actions per incident, as declared in the workflow.

package itsm.guardrails.enforce_tool_call_budget

import rego.v1

violation contains msg if {
  max_calls := input.workflow.autonomy_budget.max_tool_calls_per_incident
  actual := count(input.plan.tool_calls)
  actual > max_calls
  msg := sprintf("plan has %d tool calls, budget allows %d", [actual, max_calls])
}

violation contains msg if {
  max_actions := input.workflow.autonomy_budget.max_actions_per_incident
  actual := count(input.plan.steps)
  actual > max_actions
  msg := sprintf("plan has %d actions, budget allows %d", [actual, max_actions])
}

violation contains msg if {
  max_runtime := input.workflow.autonomy_budget.max_runtime_seconds
  estimated := input.plan.estimated_duration_seconds
  estimated > max_runtime
  msg := sprintf("estimated runtime %ds exceeds budget %ds", [estimated, max_runtime])
}
