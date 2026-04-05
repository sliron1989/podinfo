# =============================================================================
# Kind Cluster
# =============================================================================
# Provisions a local Kubernetes cluster using Kind (Kubernetes in Docker).
# The extraPortMappings expose ports 80/443 on the host, allowing the
# NGINX Ingress Controller to receive traffic from localhost.

resource "kind_cluster" "default" {
  name           = var.cluster_name
  node_image     = "kindest/node:${var.kind_node_version}"
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"

      # Map host ports to the node so ingress traffic reaches the cluster.
      extra_port_mappings {
        container_port = 80
        host_port      = 80
      }
      extra_port_mappings {
        container_port = 443
        host_port      = 443
      }

      # Label the node so the NGINX ingress can target it.
      kubeadm_config_patches = [
        <<-EOT
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
        EOT
      ]
    }
  }
}

# =============================================================================
# NGINX Ingress Controller
# =============================================================================
# Deployed via Helm. Handles host-based routing for all applications.

resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  wait             = true
  timeout          = 300

  # Kind-specific settings: use hostPort instead of LoadBalancer
  # since Kind doesn't support external LBs natively.
  values = [yamlencode({
    controller = {
      hostPort = {
        enabled = true
      }
      service = {
        type = "NodePort"
      }
      nodeSelector = {
        "ingress-ready" = "true"
      }
      tolerations = [{
        key    = "node-role.kubernetes.io/control-plane"
        effect = "NoSchedule"
      }]
    }
  })]

  depends_on = [kind_cluster.default]
}

# =============================================================================
# Application Deployments
# =============================================================================
# for_each iterates over the apps variable map, creating one complete
# application stack per entry. This is the key to reusability:
# adding a new app requires only a new entry in terraform.tfvars.
# depends_on helm_release ensures ingress controller is ready first
# (wait = true on the helm_release already waits for pods to be ready).

module "apps" {
  source   = "../modules/app"
  for_each = var.apps

  name           = each.key
  image          = each.value.image
  replicas       = each.value.replicas
  container_port = each.value.container_port
  hostname       = each.value.hostname
  ingress_class  = "nginx"

  depends_on = [helm_release.ingress_nginx]
}
