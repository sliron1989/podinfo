output "cluster_name" {
  description = "Name of the Kind cluster"
  value       = kind_cluster.default.name
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = kind_cluster.default.endpoint
}

output "app_endpoints" {
  description = "Map of application names to their ingress hostnames"
  value = {
    for name, app in module.apps : name => app.hostname
  }
}

output "etc_hosts_entries" {
  description = "Add these lines to /etc/hosts to access the apps"
  value = join("\n", [
    for name, app in module.apps : "127.0.0.1 ${app.hostname}"
  ])
}
