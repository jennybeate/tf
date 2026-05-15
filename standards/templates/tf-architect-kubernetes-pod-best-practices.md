# How tf-architect Implements Kubernetes Pod Best Practices

## Context

To implement pod-level best practices, tf-architect would create a **new module** — e.g. `modules/kubernetes-workload/v1.0.0/` — using the `hashicorp/kubernetes` provider alongside the `azurerm`/`azapi` providers. This follows the team convention of separating infra-provisioning (AKS) from workload-deployment concerns.

---

## What tf-architect would generate

---

## 1. Single Primary Container (with optional sidecars)

tf-architect structures the pod spec so the main application container comes first as the canonical entrypoint. Sidecars (e.g. a log shipper) are declared separately in the same `container` block list but are clearly secondary.

**main.tf excerpt:**
```hcl
resource "kubernetes_deployment" "main" {
  metadata {
    name      = local.deployment_name
    namespace = var.namespace
    labels    = local.common_labels
  }

  spec {
    replicas = var.replica_count

    selector {
      match_labels = local.selector_labels
    }

    template {
      metadata {
        labels = local.common_labels
      }

      spec {
        # --- Primary container (one per pod, always first) ---
        container {
          name  = var.container_name
          image = "${var.container_image}:${var.container_tag}"

          # ... resources, probes go here (see below)
        }

        # --- Optional sidecar (tightly coupled only) ---
        # Example: a Fluent Bit log forwarder co-located with the primary app.
        # Only include when the sidecar shares the pod lifecycle by design.
        dynamic "container" {
          for_each = var.sidecar_containers
          content {
            name  = container.value.name
            image = container.value.image
          }
        }
      }
    }
  }
}
```

**variables.tf addition:**
```hcl
variable "sidecar_containers" {
  type = list(object({
    image = string
    name  = string
  }))
  description = "Tightly coupled sidecar containers to run alongside the primary container. Use only when the sidecar must share the pod lifecycle (e.g., a log forwarder)."
  default     = []
}
```

> **Convention applied:** `default = []` keeps sidecars opt-in. The list type keeps the interface explicit and validatable.

---

## 2. Resource Requests and Limits

tf-architect exposes CPU and memory as typed, validated variables and wires them into the `resources` block. This prevents a single pod from starving neighbors on a node.

**main.tf (inside the primary container block):**
```hcl
resources {
  requests = {
    cpu    = var.container_cpu_request
    memory = var.container_memory_request
  }
  limits = {
    cpu    = var.container_cpu_limit
    memory = var.container_memory_limit
  }
}
```

**variables.tf additions (alphabetical, per team standard):**
```hcl
variable "container_cpu_limit" {
  type        = string
  description = "Maximum CPU the container may consume (e.g. '500m', '1'). Prevents noisy-neighbour resource exhaustion."
  default     = "500m"
}

variable "container_cpu_request" {
  type        = string
  description = "CPU the container is guaranteed at scheduling time (e.g. '100m', '0.5')."
  default     = "100m"
}

variable "container_memory_limit" {
  type        = string
  description = "Maximum memory the container may consume (e.g. '256Mi', '1Gi'). Container is OOMKilled if it exceeds this."
  default     = "256Mi"
}

variable "container_memory_request" {
  type        = string
  description = "Memory the container is guaranteed at scheduling time (e.g. '128Mi')."
  default     = "128Mi"
}
```

> **Validation pattern** (optional but recommended for production modules):
> ```hcl
> validation {
>   condition     = can(regex("^[0-9]+(m|[0-9]*)?$", var.container_cpu_limit))
>   error_message = "container_cpu_limit must be a valid Kubernetes CPU quantity (e.g. '500m', '2')."
> }
> ```

---

## 3. Liveness and Readiness Probes

tf-architect exposes probes as typed objects with sane defaults, following the same pattern used for other optional capabilities (private endpoints, diagnostics, etc.) in the skill.

**main.tf (inside the primary container block):**
```hcl
liveness_probe {
  http_get {
    path = var.liveness_probe.path
    port = var.liveness_probe.port
  }
  initial_delay_seconds = var.liveness_probe.initial_delay_seconds
  period_seconds        = var.liveness_probe.period_seconds
  failure_threshold     = var.liveness_probe.failure_threshold
}

readiness_probe {
  http_get {
    path = var.readiness_probe.path
    port = var.readiness_probe.port
  }
  initial_delay_seconds = var.readiness_probe.initial_delay_seconds
  period_seconds        = var.readiness_probe.period_seconds
  failure_threshold     = var.readiness_probe.failure_threshold
}
```

**variables.tf additions:**
```hcl
variable "liveness_probe" {
  type = object({
    failure_threshold     = optional(number, 3)
    initial_delay_seconds = optional(number, 10)
    path                  = optional(string, "/healthz")
    period_seconds        = optional(number, 10)
    port                  = optional(number, 8080)
  })
  description = "Liveness probe configuration. Kubelet restarts the container when this probe fails. Path must return HTTP 2xx."
  default     = {}
}

variable "readiness_probe" {
  type = object({
    failure_threshold     = optional(number, 3)
    initial_delay_seconds = optional(number, 5)
    path                  = optional(string, "/ready")
    period_seconds        = optional(number, 5)
    port                  = optional(number, 8080)
  })
  description = "Readiness probe configuration. Pod is removed from Service endpoints when this probe fails. Path must return HTTP 2xx."
  default     = {}
}
```

> **Convention applied:** `optional(type, default)` (requires Terraform >= 1.3) keeps the caller interface ergonomic — callers only override what they need.

---

## 4. How the test file would look (team pattern)

```hcl
# tests/workload.tftest.hcl
mock_provider "kubernetes" {}

variables {
  container_image  = "myapp"
  container_name   = "app"
  container_tag    = "1.0.0"
  environment      = "sbx"
  namespace        = "default"
  solution         = "myservice"
}

run "deployment_has_resource_limits" {
  command = plan

  assert {
    condition     = kubernetes_deployment.main.spec[0].template[0].spec[0].container[0].resources[0].limits["memory"] == "256Mi"
    error_message = "Primary container must declare a memory limit."
  }
}

run "liveness_probe_is_configured" {
  command = plan

  assert {
    condition     = kubernetes_deployment.main.spec[0].template[0].spec[0].container[0].liveness_probe[0].http_get[0].path == "/healthz"
    error_message = "Primary container must have a liveness probe."
  }
}
```

---

## Summary: tf-architect conventions applied throughout

| Practice | Convention used |
|---|---|
| Single primary container | First `container` block is canonical; sidecars are `dynamic` + `default = []` |
| Resource limits | Typed string variables with sensible defaults; optional validation blocks |
| Probes | Typed object variables with `optional()` fields and defaults — callers override only what differs |
| Variable ordering | Alphabetical in variables.tf |
| Naming | `local.deployment_name = "deploy-${var.environment}-${var.solution}"` |
| Tests | Mock providers, `command = plan`, one assertion per concern |