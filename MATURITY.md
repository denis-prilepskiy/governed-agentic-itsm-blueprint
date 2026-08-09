# Maturity Model: From Chatbot to Governed Autonomous Agent

This model ties **autonomy** to **required controls** — you cannot safely advance a level without the governance infrastructure to support it.

> **Maturity is organisational; readiness is per incident class.** This model
> describes how far an organisation has built out its control plane. It does not
> decide whether a *particular* incident category may be automated. That is a
> separate, binary test — the readiness gate — and an L4 organisation still
> fails it for incident classes with no rollback path or no fresh service data:
>
> 1. the resolution path is stable and repeatable;
> 2. affected services, ownership, and dependencies are known within declared freshness limits;
> 3. every mutating action is exposed through a versioned tool contract;
> 4. service-level success and rollback can be verified automatically;
> 5. the fallback path has a named human owner and an SLA.
>
> If any gate fails, start with decision support or supervised execution for that
> class, regardless of the maturity level you have reached elsewhere.

## Levels

| Level | Capability | Autonomy | Controls required | Typical KPI |
|-------|-----------|----------|-------------------|-------------|
| **L0: Manual** | Ticket routing, KB search | None | SLA timers | MTTA |
| **L1: Assist** | Summarisation, KB retrieval, draft responses | Suggest only | Human approval on every action | Time-to-triage |
| **L2: Co-pilot** | Auto-categorise, propose runbooks, draft changes | Act with approval | Policy engine, evidence bundle | Deflection rate |
| **L3: Supervised agent** | Execute runbooks, validate, rollback | Act within allowlist | Risk scoring, blast-radius limits, audit trail | Auto-resolution rate, MTTR |
| **L4: Governed autonomy** | E2E pipeline: detect–resolve–learn | Act within policy; escalate exceptions | Full governance stack (ISO 42001, NIST, EU AI Act) | Cost/incident, SLO adherence, zero automation-caused incidents |

## Repo artefacts by maturity level

This table shows which artefacts in this repo become relevant at each maturity level.

| Artefact | Path | Enables |
|----------|------|---------|
| Architecture diagrams | `diagrams/` | L1+ (shared vocabulary for design conversations) |
| Workflow declaration | `examples/workflow.yaml` | L2+ (defines autonomy boundaries before building) |
| Tool contract template | `schemas/tool-schema-template.json` | L2+ (formalise tool interfaces before execution) |
| Tool contracts (8) | `schemas/tool-*.json` | L2–L3 (typed, testable contracts for each action) |
| Policy engine (main) | `policies/guardrails.rego` | L2–L3 (risk-gate every action; require approval) |
| Policy modules (8) | `policies/enforce_*.rego`, `policies/require_*.rego` | L3+ (extend policy for change windows, budgets, dry-run, context freshness) |
| Context-freshness gate | `policies/enforce_context_freshness.rego` | L3+ (readiness gate 2: refuse to act on stale service data) |
| Evidence bundle schema | `schemas/evidence-bundle.schema.json` | L3 (pre-execution evidence required before acting) |
| Validation contract | `schemas/tool-validate-health.json` | L3 (validate service health before closing incident) |
| Policy decision schema | `schemas/policy-decision.schema.json` | L3 (structured, auditable policy output) |
| Test incidents | `examples/test-incidents/` | L3 (offline calibration before production) |
| Example evidence bundles | `examples/evidence/` | L3 (reference records for the auto-approve and plan-hash-bound approval paths) |
| CI validation | `.github/workflows/validate.yml` | L3–L4 (automated correctness checks, semantic assertions) |
| Maturity model | `MATURITY.md` | All levels |
| Governance mapping | README governance section | L3–L4 (ISO 42001, NIST, EU AI Act) |

## How to use this model

### Assess your current level

For each dimension below, identify where you are today:

| Dimension | L0 | L1 | L2 | L3 | L4 |
|-----------|----|----|----|----|-----|
| **Agent capability** | No AI | Summarisation/suggestion | Classification + KB retrieval | Runbook execution | E2E remediation |
| **Tool contracts** | N/A | N/A | Informal | Typed schemas + safety metadata | Versioned + tested + audited |
| **Policy engine** | None | None | Basic rules | Risk scoring + allowlists | Policy-as-code with offline calibration |
| **Evidence trail** | Manual notes | AI-generated summaries | Partial automation | Full pre-execution bundle | Immutable, compliance-grade |
| **Observability** | Ticket metrics | Basic dashboards | Stage-level metrics | Distributed traces + safety metrics | Full eval harness + regression testing |
| **Governance** | SLA management | Ad hoc | Documented process | Mapped to ISO 42001 / NIST AI RMF | Auditable compliance with EU AI Act |
| **Service model** | Asset list | Basic CMDB | Service mapping (partial) | Live discovery + dependency graphs | Continuously validated, agent-consumable |

### Plan your next level

Moving from L1 to L2 requires: a policy engine (even a simple one), evidence bundling, and at least partial tool contracts.

Moving from L2 to L3 requires: the artefacts in this repository — typed tool contracts with safety metadata, OPA/Rego policies, a validation contract, and distributed tracing.

Moving from L3 to L4 requires: offline evaluation harness, governance framework mapping, continuous service model validation, and a proven track record of zero automation-caused incidents.

## Common traps

- **Jumping from L1 to L4**: every skipped level represents missing controls that will surface as incidents or project cancellations.
- **Measuring L3 with L1 metrics**: "tickets deflected" doesn't tell you whether your automation is safe. Measure auto-resolution rate, rollback rate, and automation-caused incidents.
- **Treating L4 as "fully autonomous"**: even at L4, policy gates and human escalation paths exist. The difference is that they are exception-based rather than default.
