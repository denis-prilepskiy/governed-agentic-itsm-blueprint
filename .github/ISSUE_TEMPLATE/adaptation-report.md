---
name: Adaptation report
about: Share how you adapted this blueprint to your environment
title: "[Adaptation] "
labels: adaptation-report
assignees: ''
---

## Your environment

- **ITSM platform**: (e.g., ServiceNow, Jira Service Management, BMC Helix, Freshservice, other)
- **Observability stack**: (e.g., Dynatrace, Datadog, Grafana/Prometheus, Splunk, other)
- **LLM / AI layer**: (e.g., Azure OpenAI, AWS Bedrock, self-hosted, vendor-native)
- **Approximate incident volume**: (e.g., 5,000/month)

## What you adapted

Describe which artefacts from this repo you used and how you modified them:

- [ ] Workflow declaration (`examples/workflow.yaml`)
- [ ] Tool contracts (`schemas/`)
- [ ] OPA/Rego policies (`policies/`)
- [ ] Change risk prompt (`examples/change-risk-prompt.md`)
- [ ] Architecture diagrams (`diagrams/`)
- [ ] Maturity model (`MATURITY.md`)

## What worked

Describe what went well. Include metrics if possible (e.g., MTTR reduction, auto-resolution rate, deflection rate).

## What didn't work or needed significant changes

Describe surprises, gaps, or areas where the blueprint didn't match your reality.

## Suggestions for improvement

Any changes you'd recommend for the repo based on your experience.
