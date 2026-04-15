# Governed Agentic AI for ITSM — A Practical Blueprint

> **Start with the control plane, not the agent. The agent is the easy part.**

A vendor-neutral reference architecture and ready-to-use engineering artefacts for shipping **governed agentic AI** in IT Service Management — without joining the [40% of agentic AI projects Gartner predicts will be cancelled](https://www.gartner.com/en/newsroom/press-releases/2025-06-25-gartner-predicts-over-40-percent-of-agentic-ai-projects-will-be-canceled-by-end-of-2027) by 2027.

<!-- If your InfoQ article is published, uncomment and update the link below -->
<!-- 📄 **Companion article on InfoQ:** [How to Ship Governed Agentic AI in ITSM Without Joining the 40% That Get Cancelled](https://www.infoq.com/articles/...) -->

---

## What this repo gives you

| Artefact | Path | Purpose |
|----------|------|---------|
| Reference architecture diagram | [`diagrams/`](diagrams/) | Vendor-neutral architecture: agents, control plane, tool layer, evidence store |
| Auto-remediation pipeline | [`diagrams/`](diagrams/) | Sequence diagram: detect → triage → plan → risk-score → approve → execute → validate → rollback |
| Governance layer stack | [`diagrams/`](diagrams/) | ISO 42001 → NIST AI RMF → EU AI Act → runtime enforcement |
| Workflow declaration | [`examples/workflow.yaml`](examples/workflow.yaml) | Autonomy boundaries, guardrails, evidence requirements |
| MCP tool contracts | [`schemas/`](schemas/) | Typed tool schemas with safety metadata (dry-run, idempotency, blast radius, rollback) |
| Validation contract | [`schemas/`](schemas/) | SLO/health-probe verification schema |
| OPA/Rego policies | [`policies/`](policies/) | Risk gating, approval routing, deny rules — executable policy-as-code |
| Change risk prompt | [`examples/change-risk-prompt.md`](examples/change-risk-prompt.md) | Structured prompt template for LLM-driven change risk assessment |
| Maturity model | [`MATURITY.md`](MATURITY.md) | L0–L4 progression from manual ITSM to governed autonomy |

## Architecture overview

### Reference architecture

```
User channels ──► ITSM System of Record
Observability  ──► Event intake ──► Triage Agent ──► Diagnostics Agent ──► Remediation Planner
                                                                                │
                   ┌────────────────────────────────────────────────────────────┘
                   ▼
            ┌─────────────┐
            │ Policy Engine│──► allow ──────────► Tool Runner ──► MCP Tool Servers ──► Systems
            │ (risk score, │──► needs-approval ► Human ──► Tool Runner
            │  SoD, allow- │──► deny ──────────► ITSM record + rationale
            │  lists)      │
            └─────────────┘
                   │
            Evidence Bundle Store ──► Immutable Audit Log
                                  ──► Evaluation Harness
```

Full Mermaid diagrams are in [`diagrams/`](diagrams/).

### Core design principle

Split the **data plane** (agents + tools executing work) from the **control plane** (policy decisions, approvals, audit, evaluation). This lets you swap models, add agents, or add tools — without rewriting governance every time.

## Quick start

### 1. Review the workflow declaration

[`examples/workflow.yaml`](examples/workflow.yaml) defines autonomy boundaries for a starter scope (certificate expiry, service restart, DNS misconfiguration). Adapt `scope.services` and `scope.allowed_categories` to your environment.

### 2. Define your tool contracts

Use [`schemas/tool-restart-service.json`](schemas/tool-restart-service.json) as a template. For each tool your agents can invoke:

- Define typed `input_schema` and `output_schema`
- Add `safety` metadata: `idempotent`, `supports_dry_run`, `max_calls_per_incident`, `rollback_tool`
- Set `dry_run: true` as the default

### 3. Deploy policy-as-code

[`policies/guardrails.rego`](policies/guardrails.rego) is an executable OPA policy. To test locally:

```bash
# Install OPA (https://www.openpolicyagent.org/docs/latest/#running-opa)
# macOS:
brew install opa

# Linux:
curl -L -o opa https://openpolicyagent.org/downloads/v1.4.2/opa_linux_amd64_static
chmod 755 opa && sudo mv opa /usr/local/bin/

# Evaluate a test incident against the policy:
opa eval \
  --data policies/guardrails.rego \
  --input examples/test-incidents/low-risk-cert-expiry.json \
  "data.itsm.guardrails.decision"
```

### 4. Calibrate thresholds with offline replay

Before enabling execution in production:

1. Collect 2–4 weeks of historical incidents for your target categories
2. Run each through the policy engine with the artefacts in this repo
3. Measure: approval rate, false-approval rate, missed-automation rate
4. Adjust `risk_score` thresholds and allowlists based on the data

### 5. Instrument with OpenTelemetry

Propagate `traceparent` through every tool call (the tool contracts include a `traceparent` field for this). Emit stage-level metrics: `triage_duration`, `policy_decision`, `tool_execution_time`, `validation_result`, `rollback_count`.

## Governance mapping

This blueprint maps to three governance frameworks:

| Framework | What it gives you | Where it shows up in this repo |
|-----------|-------------------|-------------------------------|
| **ISO/IEC 42001** | AI management system: roles, lifecycle, continual improvement | Workflow declaration (lifecycle), evidence bundles (documentation) |
| **NIST AI RMF** | Risk vocabulary: reliability, safety, transparency, controllability | Policy engine (risk scoring), validation contracts (reliability) |
| **EU AI Act** | Legal requirements: traceability, oversight, penalties | Audit log (traceability), human approval gates (oversight) |

See [`MATURITY.md`](MATURITY.md) for how governance requirements scale with autonomy level.

## Repo structure

```
governed-agentic-itsm-blueprint/
├── README.md                  ← you are here
├── MATURITY.md                ← L0–L4 maturity model
├── LICENSE                    ← Apache 2.0
├── diagrams/
│   ├── reference-architecture.mermaid
│   ├── auto-remediation-pipeline.mermaid
│   └── governance-layers.mermaid
├── schemas/
│   ├── tool-restart-service.json
│   ├── tool-validate-health.json
│   └── tool-schema-template.json
├── policies/
│   └── guardrails.rego
├── examples/
│   ├── workflow.yaml
│   ├── change-risk-prompt.md
│   └── test-incidents/
│       ├── low-risk-cert-expiry.json
│       ├── medium-risk-multi-service.json
│       └── high-risk-deploy.json
└── .github/
    └── ISSUE_TEMPLATE/
        └── adaptation-report.md
```

## Contributing

This is a living blueprint. If you've adapted it to your stack or discovered edge cases, contributions are welcome:

- **Adaptation reports**: Use the [issue template](.github/ISSUE_TEMPLATE/adaptation-report.md) to share how you applied this in your environment
- **New tool contracts**: Add schemas for tools you've governed (monitoring, CI/CD, IAM, etc.)
- **Policy extensions**: Additional Rego rules for scenarios not covered (e.g., security-sensitive changes, compliance holds)

## Related work

- [Model Context Protocol (MCP) Specification](https://modelcontextprotocol.io/specification/2025-03-26)
- [Agent2Agent Protocol (A2A)](https://developers.googleblog.com/en/a2a-a-new-era-of-agent-interoperability/)
- [Open Policy Agent (OPA)](https://www.openpolicyagent.org/docs)
- [OpenTelemetry](https://opentelemetry.io/docs/)
- [ISO/IEC 42001 Explained](https://www.iso.org/home/insights-news/resources/iso-42001-explained-what-it-is.html)
- [NIST AI RMF 1.0](https://www.nist.gov/publications/artificial-intelligence-risk-management-framework-ai-rmf-10)
- [EU AI Act — Entry into force](https://commission.europa.eu/news-and-media/news/ai-act-enters-force-2024-08-01_en)

## License

Apache 2.0 — see [LICENSE](LICENSE).

---

**Author:** Denis Prilepskiy — AI/ML & Enterprise Architecture, 15+ years in financial services and digital transformation.
[LinkedIn](https://www.linkedin.com/in/denisprilepskiy/)
