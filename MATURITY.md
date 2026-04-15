# Maturity Model: From Chatbot to Governed Autonomous Agent

This model ties **autonomy** to **required controls** — you cannot safely advance a level without the governance infrastructure to support it.

## Levels

| Level | Capability | Autonomy | Controls required | Typical KPI |
|-------|-----------|----------|-------------------|-------------|
| **L0: Manual** | Ticket routing, KB search | None | SLA timers | MTTA |
| **L1: Assist** | Summarisation, KB retrieval, draft responses | Suggest only | Human approval on every action | Time-to-triage |
| **L2: Co-pilot** | Auto-categorise, propose runbooks, draft changes | Act with approval | Policy engine, evidence bundle | Deflection rate |
| **L3: Supervised agent** | Execute runbooks, validate, rollback | Act within allowlist | Risk scoring, blast-radius limits, audit trail | Auto-resolution rate, MTTR |
| **L4: Governed autonomy** | E2E pipeline: detect–resolve–learn | Act within policy; escalate exceptions | Full governance stack (ISO 42001, NIST, EU AI Act) | Cost/incident, SLO adherence, zero automation-caused incidents |

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
