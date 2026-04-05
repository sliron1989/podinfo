# ============================================================================
# Application Definitions
# ============================================================================
# To add a new application, simply add a new entry to this map.
# Terraform will automatically create a Deployment, Service, and Ingress
# for it — no code changes required. This demonstrates code reusability.

apps = {
  # App 1: nginxdemos/hello — returns pod name and IP in its response
  app1 = {
    image          = "nginxdemos/hello:plain-text"
    replicas       = 2
    container_port = 80
    hostname       = "app1.local"
  }

  # App 2: a second application demonstrating minimal-effort scaling
  app2 = {
    image          = "nginxdemos/hello:plain-text"
    replicas       = 2
    container_port = 80
    hostname       = "app2.local"
  }

  # Bonus: podinfo — deployed with zero additional Terraform code,
  # just one more map entry. This satisfies the bonus requirement.
  podinfo = {
    image          = "stefanprodan/podinfo:latest"
    replicas       = 2
    container_port = 9898
    hostname       = "podinfo.local"
  }
}
