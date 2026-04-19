# Security Policy

## Scope

This repository contains **reference artefacts** (schemas, policies, prompts, and diagrams) — not production software. There are no running services, APIs, or deployed infrastructure.

That said, the artefacts are designed to be used in security-sensitive contexts (ITSM automation, production tool execution, policy enforcement), so we take accuracy and safety seriously.

## Reporting a concern

If you find a security-relevant issue — for example, a policy rule that fails to deny a dangerous action, a tool contract that omits safety metadata, or an example that could lead to unsafe automation if used as-is — please:

1. **Open a GitHub issue** describing the concern. Since this repo contains no secrets or deployed services, public disclosure is appropriate.
2. If you believe the issue is sensitive for any reason, email the maintainer directly at D.A.Prilepskiy@gmail.com.

## Response

I aim to acknowledge security-relevant issues within 72 hours and address them within one week.

## Responsible use

The artefacts in this repository are starting points, not production-ready configurations. Before deploying any policy, tool contract, or workflow declaration in a production environment:

- Review and adapt all thresholds, allowlists, and tool permissions to your specific context.
- Test policies against historical incidents using offline replay before enabling execution.
- Ensure your deployment meets your organisation's security, governance, and compliance requirements.
