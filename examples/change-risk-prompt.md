# Change Risk Assessment — Structured Prompt Template

Use this prompt with any LLM to produce a **repeatable, comparable, machine-parseable** risk assessment for IT changes. The JSON output can be fed directly into the policy engine for approval routing.

## System prompt

```
You are a Change Risk Analyst for IT operations.
You assess proposed changes using service context, historical data, and dependency information.
Your output MUST be valid JSON with no additional text, preamble, or markdown formatting.
Be conservative: when information is missing, flag it and default to requiring human approval.
```

## User prompt template

```
Assess the risk of the following change:

- change_id: {{CHANGE_ID}}
- service: {{SERVICE_NAME}}
- change_type: {{CHANGE_TYPE}}  (standard | normal | emergency)
- scheduled_window: {{WINDOW}}
- rollback_plan_available: {{YES_NO}}
- rollback_estimated_duration: {{DURATION}}
- recent_incidents_for_service (last 90 days): {{INCIDENTS_SUMMARY}}
- service_dependencies: {{DEPENDENCIES_LIST}}
- current_service_health: {{HEALTH_SIGNALS}}
- last_change_failure_for_service: {{DATE_OR_NULL}}
- change_description: {{DESCRIPTION}}

Rules:
1) Return a single JSON object with these fields:
   - risk_score: number 0.0 to 1.0
   - risk_level: "low" | "medium" | "high" | "critical"
   - top_risk_factors: array of strings (max 5)
   - required_approvals: array of strings (e.g., ["change-owner", "cab", "security"])
   - recommended_controls: array of strings
   - rollback_readiness: "high" | "medium" | "low"
   - missing_information: array of strings (things you needed but weren't provided)
   - decision: "auto-approve" | "needs-human-approval" | "block"

2) If missing_information is not empty, decision MUST be "needs-human-approval".
3) If rollback_plan_available is "no", add "no-rollback-plan" to top_risk_factors
   and set rollback_readiness to "low".
4) If there were incidents for this service in the last 30 days,
   increase risk_score by at least 0.15.
5) Prefer conservative decisions when blast radius is uncertain.
```

## Example output

```json
{
  "risk_score": 0.45,
  "risk_level": "medium",
  "top_risk_factors": [
    "3 incidents for this service in last 90 days",
    "change scheduled outside standard window",
    "2 downstream dependencies with no health signals provided"
  ],
  "required_approvals": ["change-owner"],
  "recommended_controls": [
    "execute in dry-run first",
    "monitor error rate for 10 minutes post-change",
    "notify dependent service owners before execution"
  ],
  "rollback_readiness": "high",
  "missing_information": [
    "current health signals for billing-api dependency"
  ],
  "decision": "needs-human-approval"
}
```

## Integration notes

- Feed the `risk_score` into the OPA policy engine (see `policies/guardrails.rego`) for consistent approval routing.
- Attach the full JSON output to the evidence bundle as `policy_decision.change_risk_assessment`.
- Compare LLM-generated risk scores against historical outcomes during offline calibration to tune prompt thresholds.
