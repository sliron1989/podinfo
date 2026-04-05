# Terraform Kubernetes Local Infrastructure

Automated provisioning of N web applications on a local Kubernetes cluster using Terraform.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Host Machine                      │
│                                                      │
│  terraform.tfvars ──► for_each ──► Module instances  │
│                                                      │
│  ┌─────────────────────────────────────────────┐     │
│  │           Kind Cluster (Docker)             │     │
│  │                                             │     │
│  │  ┌──────────────────────────────────┐       │     │
│  │  │    NGINX Ingress Controller      │       │     │
│  │  │    (host ports 80/443)           │       │     │
│  │  └──────┬──────────┬───────────┬────┘       │     │
│  │         │          │           │             │     │
│  │    app1.local  app2.local  podinfo.local    │     │
│  │         │          │           │             │     │
│  │     ┌───▼──┐   ┌───▼──┐   ┌───▼──┐         │     │
│  │     │ Svc  │   │ Svc  │   │ Svc  │         │     │
│  │     └──┬───┘   └──┬───┘   └──┬───┘         │     │
│  │     ┌──▼───┐   ┌──▼───┐   ┌──▼───┐         │     │
│  │     │ Pods │   │ Pods │   │ Pods │         │     │
│  │     └──────┘   └──────┘   └──────┘         │     │
│  └─────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────┘
```

### Design Decisions

- **Kind cluster** — native Terraform provider (`tehcyx/kind`), no external scripts needed.
- **`for_each` on a module** — each app in `terraform.tfvars` automatically gets a Deployment, Service, and Ingress. Adding or removing apps requires zero Terraform code changes.
- **NGINX Ingress Controller** (Helm) — industry-standard host-based routing. Each app gets a distinct hostname.
- **Health checks** — readiness and liveness probes on every pod ensure traffic only reaches healthy instances.
- **`nginxdemos/hello:plain-text`** — returns pod name and IP in its HTTP response, directly satisfying the assignment requirements.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.3
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

## Quick Start

### Using Make (recommended)

```bash
# Full end-to-end: checks Docker, provisions cluster, deploys apps, updates /etc/hosts, verifies
make all

# Or step by step:
make init       # terraform init (checks Docker first)
make plan       # terraform plan
make apply      # terraform apply
make hosts      # update /etc/hosts with app routes
make verify     # show pods, services, ingress
make test       # curl each app endpoint
make destroy    # tear everything down
```

### Manual

```bash
cd terraform/provisioners

# 1. Initialize Terraform (downloads providers)
terraform init

# 2. Preview what will be created
terraform plan

# 3. Apply — creates the Kind cluster, ingress controller, and all apps
terraform apply

# 4. Add /etc/hosts entries for local DNS resolution
echo "" | sudo tee -a /etc/hosts && terraform output -raw etc_hosts_entries | sudo tee -a /etc/hosts && echo "" | sudo tee -a /etc/hosts
```

## Verify the Routes

```bash
# Test each application
curl http://app1.local
curl http://app2.local
curl http://podinfo.local

# You should see pod name and IP in the app1/app2 responses:
#   Server address: 10.244.0.X:80
#   Server name: app1-xxxxxxxxx-xxxxx

# Check Kubernetes resources
kubectl get pods -o wide
kubectl get svc
kubectl get ingress
```

## Adding a New Application

Edit `terraform/provisioners/terraform.tfvars` and add an entry to the `apps` map:

```hcl
apps = {
  # ... existing apps ...

  my-new-app = {
    image          = "nginx:latest"
    replicas       = 3
    container_port = 80
    hostname       = "my-new-app.local"
  }
}
```

Then run:

```bash
cd terraform/provisioners
terraform apply
# Add the new /etc/hosts entry
echo "127.0.0.1 my-new-app.local" | sudo tee -a /etc/hosts
curl http://my-new-app.local
```

No Terraform code changes needed — this is the reusability in action.

## Project Structure

```
.
├── terraform/
│   ├── provisioners/        # Root module — run terraform init/apply from here
│   │   ├── main.tf          # Kind cluster + Ingress + Module calls
│   │   ├── providers.tf     # Provider configurations
│   │   ├── variables.tf     # Root variables (cluster_name, apps map)
│   │   ├── outputs.tf       # Cluster info and app endpoint outputs
│   │   ├── versions.tf      # Provider version constraints
│   │   └── terraform.tfvars # Application definitions (the only file you edit)
│   └── modules/
│       └── app/
│           ├── main.tf      # Deployment, Service, Ingress resources
│           ├── variables.tf # Module input variables
│           └── outputs.tf   # Module outputs
├── .github/
│   └── workflows/
│       └── main.yml         # CI/CD pipeline (validate + integration test)
└── README.md
```

## CI/CD

The GitHub Actions workflow (`.github/workflows/main.yml`) has two jobs:

1. **`terraform`** — runs on every push/PR: format check, init, validate.
2. **`integration-test`** — manual trigger (`workflow_dispatch`): full apply + curl tests + destroy.

### Run locally with `act`

```bash
# Install act: https://github.com/nektos/act
# Run the validation job
act push

# Run the full integration test
act workflow_dispatch
```

## Cleanup

```bash
cd terraform/provisioners
terraform destroy
```

## AI Usage Disclosure

This project was developed with the assistance of Claude (Anthropic). The AI was prompted to:
- Design a modular Terraform project using `for_each` for code reusability
- Implement Kind cluster provisioning with NGINX Ingress Controller
- Create health-checked deployments with distinct host-based routing
- Structure the project with clear separation of concerns (modules, variables, outputs)

All generated code was reviewed and validated for correctness and best practices.
# podinfo
# podinfo
