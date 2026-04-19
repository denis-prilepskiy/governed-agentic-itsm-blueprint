# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.2.0] - 2025-XX-XX

### Added

- Modular policy pack: 7 focused Rego modules (`deny_prohibited_tools`, `require_approval_by_risk`, `require_approval_by_blast_radius`, `enforce_dry_run`, `enforce_change_window`, `enforce_environment_exclusions`, `enforce_tool_call_budget`)
- Governance schemas: `evidence-bundle.schema.json`, `policy-decision.schema.json`, `validation-result.schema.json`
- Additional tool contracts: `tool-renew-certificate.json`, `tool-drain-connections.json`, `tool-rollback-deployment.json`, `tool-notify-stakeholders.json`, `tool-open-change-record.json`, `tool-restart-service-rollback.json`
- Example evidence bundle: `examples/evidence/example-evidence-bundle.json`
- CI validation workflow (GitHub Actions): JSON, YAML, and Rego validation on every push/PR
- Repo hygiene: `.gitignore`, `CONTRIBUTING.md`, `SECURITY.md`, `CHANGELOG.md`
- Status badge and "What this repo is / is not" section in README

### Changed

- `policies/guardrails.rego` updated with cleaner syntax and consistent helpers
- README expanded with status section, contributor guidance, and repo maturity context

### Fixed

- Added missing `tool-restart-service-rollback.json` (previously referenced by `tool-restart-service.json` but absent)

## [0.1.0] - 2025-XX-XX

### Added

- Initial release: reference architecture, auto-remediation pipeline, governance layer diagrams
- Workflow declaration (`examples/workflow.yaml`)
- Tool contracts: `tool-restart-service.json`, `tool-validate-health.json`, `tool-schema-template.json`
- OPA/Rego guardrails policy
- Change risk prompt template
- Maturity model (L0–L4)
- Test incidents: low-risk, medium-risk, high-risk
- GitHub issue template for adaptation reports
