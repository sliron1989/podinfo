variable "cluster_name" {
  description = "Name of the Kind cluster"
  type        = string
  default     = "terraform-k8s"
}

variable "kind_node_version" {
  description = "Kubernetes version for the Kind node image"
  type        = string
  default     = "v1.32.2"
}

# This map drives the entire deployment. Adding a new entry here
# automatically creates a full app stack (Deployment + Service + Ingress)
# with zero additional Terraform code — this is the core reusability mechanism.
variable "apps" {
  description = "Map of applications to deploy. Key = app name, value = app config."
  type = map(object({
    image          = string
    replicas       = optional(number, 2)
    container_port = optional(number, 80)
    hostname       = string
  }))
}
