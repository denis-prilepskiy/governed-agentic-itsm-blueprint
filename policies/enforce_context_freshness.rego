# Enforce context freshness as an admission criterion
#
# The fourth runtime invariant: an agent must not act on a service graph,
# CMDB record, or telemetry snapshot older than the declared threshold.
# Stale context is the failure mode behind most "the model did exactly what
# it was told" outages — the plan is correct for a topology that no longer
# exists.
#
# Ages are computed against `input.context.evaluated_at` (the moment of
# policy admission), NOT against wall-clock time. This keeps fixtures
# reproducible: a test incident recorded in 2025 evaluates identically
# today and next year.
#
# Thresholds are read from the workflow declaration:
#
#   workflow.guardrails.context_freshness.cmdb_max_age_seconds
#   workflow.guardrails.context_freshness.metrics_max_age_seconds
#
# and fall back to 300 s / 60 s when the declaration is absent.
#
# Violations from this module are aggregated by guardrails.rego into
# `_module_deny_violations`, not `_module_soft_violations`. Stale context
# denies the autonomous plan outright and hands the incident to the named
# human owner via the fallback path. It is deliberately NOT routed to
# "needs-human-approval": asking an operator to sign off on a plan derived
# from stale data reproduces the original failure with a human signature
# attached to it.
#
# NOTE: freshness enforcement requires the full policy pack
# (`opa eval --data policies/`). It is not part of the standalone
# fallback logic in guardrails.rego.

package itsm.guardrails.enforce_context_freshness

import rego.v1

# ─── Thresholds ──────────────────────────────────────────────────────────────

default cmdb_max_age_seconds := 300

cmdb_max_age_seconds := n if {
	n := input.workflow.guardrails.context_freshness.cmdb_max_age_seconds
}

default metrics_max_age_seconds := 60

metrics_max_age_seconds := n if {
	n := input.workflow.guardrails.context_freshness.metrics_max_age_seconds
}

# ─── Age helper ──────────────────────────────────────────────────────────────
# Undefined when either timestamp is missing, so incidents that do not
# declare context timestamps produce no violation (backwards compatible).

age_seconds(as_of) := seconds if {
	now := time.parse_rfc3339_ns(input.context.evaluated_at)
	then := time.parse_rfc3339_ns(as_of)
	seconds := round((now - then) / 1000000000)
}

# ─── Violations ──────────────────────────────────────────────────────────────

violation contains msg if {
	age := age_seconds(input.context.cmdb_as_of)
	age > cmdb_max_age_seconds
	msg := sprintf(
		"stale CMDB context: %v s old, declared freshness threshold is %v s — routing to the human fallback path",
		[age, cmdb_max_age_seconds],
	)
}

violation contains msg if {
	age := age_seconds(input.context.metrics_as_of)
	age > metrics_max_age_seconds
	msg := sprintf(
		"stale telemetry context: %v s old, declared freshness threshold is %v s — routing to the human fallback path",
		[age, metrics_max_age_seconds],
	)
}

# A plan that declares no context provenance at all cannot be admitted
# when the workflow requires freshness checking.

violation contains msg if {
	input.workflow.guardrails.context_freshness
	not input.context.evaluated_at
	msg := "context freshness is required by the workflow declaration but no evaluated_at timestamp was supplied"
}
