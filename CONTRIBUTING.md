# Contributing

Thank you for your interest in improving this blueprint. Contributions that make the repo more useful for practitioners are welcome.

## What we're looking for

- **Adaptation reports**: If you've applied this blueprint in your environment, open an issue using the [adaptation report template](.github/ISSUE_TEMPLATE/adaptation-report.md). Real-world feedback is the most valuable contribution.
- **New tool contracts**: Schemas for tools not yet covered (monitoring, CI/CD, IAM, database, cloud infrastructure).
- **Policy extensions**: Additional Rego rules for scenarios not covered — e.g., security-sensitive changes, compliance holds, maintenance windows.
- **Bug fixes**: Typos, broken links, schema validation errors, inconsistencies between artefacts.
- **Documentation improvements**: Clearer explanations, better examples, translations.

## How to contribute

1. Fork the repository.
2. Create a branch for your change: `git checkout -b add-iam-tool-contract`.
3. Make your changes.
4. Validate your changes locally:
   - JSON files: `python3 -c "import json; json.load(open('your-file.json'))"`
   - YAML files: `python3 -c "import yaml; yaml.safe_load(open('your-file.yaml'))"`
   - Rego files: `opa check policies/your-file.rego`
5. Commit with a clear message: `git commit -m "Add IAM role change tool contract"`.
6. Push and open a pull request.

## Conventions

- **Tool contracts** go in `schemas/` and follow the naming pattern `tool-{action}.json`.
- **Policy modules** go in `policies/` and use the package prefix `itsm.guardrails.{module_name}`.
- **Test incidents** go in `examples/test-incidents/` and should include enough context for policy evaluation.
- **British English** for documentation (organisation, behaviour, colour).
- **JSON files** should be formatted with 2-space indentation.

## What we won't merge

- Vendor-specific marketing content.
- Changes that break existing JSON/YAML/Rego validation.
- Policy changes that weaken governance without clear justification.

## Code of conduct

Be professional, be constructive, be kind. This is a practitioner community.
