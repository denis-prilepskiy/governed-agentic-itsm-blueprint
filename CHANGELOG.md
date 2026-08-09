# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.3.0] - 2026-08-09

Closes the gap between the four runtime invariants described in the accompanying
article and what this repository actually enforces. Two of the four — freshness as
an admission criterion, and approval bound to a concrete plan — previously had no
artefact behind them. They now do, with CI assertions to keep them honest.

### Added

- `policies/enforce_context_freshness.rego` — the fourth runtime invariant as executable policy. Compares `context.cmdb_as_of` and `context.metrics_as_of` against `context.evaluated_at`, using thresholds from the workflow declaration (defaults 300 s / 60 s). Ages are computed against the admission timestamp rather than wall-clock time, so fixtures stay reproducible.
- `examples/test-incidents/stale-context-restart.json` — reproduces the failure class behind the article's opening case: a correct plan built on a dependency map 36 hours old. Low risk score, single declared service, allowed category, inside the change window. Only the freshness gate catches it.
- `examples/evidence/example-evidence-bundle-approval.json` — second reference bundle covering the approval path, showing an operator approval that carries the plan hash it authorises and an explicit expiry.
- `pre_execution.workflow_version`, `pre_execution.plan_hash`, `pre_execution.tool_contract_versions`, and `pre_execution.context_freshness` in `schemas/evidence-bundle.schema.json`, all required. The article describes the bundle as binding these together; until now the schema did not carry them.
- `approval.plan_hash` and `approval.valid_until` in `schemas/policy-decision.schema.json`, both required when an approval is present.
- `guardrails.context_freshness` and `guardrails.approval_binding` in `schemas/workflow.schema.json` and `examples/workflow.yaml`.
- `observability.semantic_conventions` in the workflow declaration, plus `context_freshness_seconds` and `stale_context_denials` metrics.
- Four new CI assertions: approval binds to plan hash and stays inside its window; the pre-execution record is complete and precedes the first tool call; recorded context ages are arithmetically consistent with their timestamps and within declared thresholds; and the stale fixture is denied *by the freshness gate specifically*, not merely denied.
- CI now validates every bundle in `examples/evidence/`, not just the first.

### Changed

- `policies/guardrails.rego` aggregates freshness violations into `_module_deny_violations`. Stale context denies the autonomous plan and hands the incident to the named human owner. It is deliberately not routed to `needs-human-approval`: an operator signing off on a plan derived from stale data reproduces the original failure with a signature attached.
- Policy decisions now return richer obligations alongside every admitting verdict — `required_evidence_fields`, `approval_binds_to_plan_hash`, `fallback_on_timeout`, and `timeout_seconds` — so the engine answers "under what conditions", not only "may this run".
- `guardrails.rego` header documents the mapping between this repository's decision enum (`deny` / `needs-human-approval` / `auto-approve`) and the verdict vocabulary used in the article and diagrams (`deny` / `require approval` / `admit with obligations`).
- Existing test incidents carry `evaluated_at`, `cmdb_as_of`, `metrics_as_of`, and `plan_hash`. Their expected decisions are unchanged.
- `examples/workflow.yaml` bumped to `1.1.0`.

### Notes

- Freshness enforcement requires the full policy pack (`opa eval --data policies/`). It is not part of the standalone fallback logic in `guardrails.rego`.
- Incidents that declare no context timestamps produce no freshness violation, so existing integrations continue to evaluate as before.

## [0.2.0] - 2026-04-19

### Added

- Modular policy pack: 7 focused Rego modules (`deny_prohibited_tools`, `require_approval_by_risk`, `require_approval_by_blast_radius`, `enforce_dry_run`, `enforce_change_window`, `enforce_environment_exclusions`, `enforce_tool_call_budget`)
- Governance schemas: `evidence-bundle.schema.json`, `policy-decision.schema.json`, `validation-result.schema.json`
- Additional tool contracts: `tool-renew-certificate.json`, `tool-drain-connections.json`, `tool-rollback-deployment.json`, `tool-notify-stakeholders.json`, `tool-open-change-record.json`, `tool-restart-service-rollback.json`
- Example evidence bundle: `examples/evidence/example-evidence-bundle.json`
- CI validation workflow (GitHub Actions): JSON, YAML, and Rego validation on every push/PR
- Repo hygiene: `.gitignore`, `.github/ISSUE_TEMPLATE/adaptation-report.md`, `CONTRIBUTING.md`, `SECURITY.md`, `CHANGELOG.md`
- Status badge and "What this repo is / is not" section in README

### Changed

- `policies/guardrails.rego` updated with cleaner syntax and consistent helpers
- README expanded with status section, contributor guidance, and repo maturity context

### Fixed

- Added missing `tool-restart-service-rollback.json` (previously referenced by `tool-restart-service.json` but absent)

## [0.1.0] - 2026-04-19

### Added

- Initial release: reference architecture, auto-remediation pipeline, governance layer diagrams
- Workflow declaration (`examples/workflow.yaml`)
- Tool contracts: `tool-restart-service.json`, `tool-validate-health.json`, `tool-schema-template.json`
- OPA/Rego guardrails policy
- Change risk prompt template
- Maturity model (L0–L4)
- Test incidents: low-risk, medium-risk, high-risk
