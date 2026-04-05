.PHONY: check-docker init plan apply hosts verify test destroy clean all

TERRAFORM_DIR := terraform/provisioners

# Check that Docker daemon is running before any cluster operation
check-docker:
	@docker info > /dev/null 2>&1 || (echo "Error: Docker is not running. Please start Docker and try again." && exit 1)
	@echo "Docker is running."

init: check-docker
	cd $(TERRAFORM_DIR) && terraform init

plan: init
	cd $(TERRAFORM_DIR) && terraform plan

apply: init
	cd $(TERRAFORM_DIR) && terraform apply -auto-approve

hosts:
	@echo "" | sudo tee -a /etc/hosts > /dev/null
	@cd $(TERRAFORM_DIR) && terraform output -raw etc_hosts_entries | sudo tee -a /etc/hosts
	@echo "" | sudo tee -a /etc/hosts > /dev/null
	@echo "/etc/hosts updated."

verify:
	@echo "=== Pods ==="
	@kubectl get pods -o wide
	@echo ""
	@echo "=== Services ==="
	@kubectl get svc
	@echo ""
	@echo "=== Ingress ==="
	@kubectl get ingress

test:
	@kubectl wait --for=condition=ready pod -l app=app1 --timeout=120s
	@kubectl wait --for=condition=ready pod -l app=app2 --timeout=120s
	@kubectl wait --for=condition=ready pod -l app=podinfo --timeout=120s
	@echo "--- app1.local ---"e
	@curl -s -H "Host: app1.local" http://localhost
	@echo ""
	@echo "--- app2.local ---"
	@curl -s -H "Host: app2.local" http://localhost
	@echo ""
	@echo "--- podinfo.local ---"
	@curl -s -H "Host: podinfo.local" http://localhost
	@echo ""

destroy:
	cd $(TERRAFORM_DIR) && terraform destroy -auto-approve

clean: destroy
	rm -rf $(TERRAFORM_DIR)/.terraform $(TERRAFORM_DIR)/.terraform.lock.hcl $(TERRAFORM_DIR)/terraform.tfstate $(TERRAFORM_DIR)/terraform.tfstate.backup

# Full end-to-end: provision cluster, deploy apps, update hosts, verify
all: apply hosts verify test
