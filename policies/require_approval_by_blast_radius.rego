# Require human approval when blast radius spans multiple services
#
# Single-service incidents within allowlist can auto-resolve.
# Multi-service incidents always require human judgement.

package itsm.guardrails.require_approval_by_blast_radius

import rego.v1

default max_auto_services := 1

needs_approval if {
  input.blast_radius.services_affected > max_auto_services
}

reason := sprintf("blast radius spans %d services (max auto: %d)", [
  input.blast_radius.services_affected,
  max_auto_services,
]) if {
  needs_approval
}
