.PHONY: init plan apply destroy fmt validate lint clean

ENV ?= dev
MODULE_DIRS := $(shell find modules -mindepth 1 -maxdepth 1 -type d)

init:
	@echo "Initializing $(ENV) environment..."
	cd environments/$(ENV) && terraform init -upgrade

plan:
	@echo "Planning $(ENV) environment..."
	cd environments/$(ENV) && terraform plan -out=tfplan

apply:
	@echo "Applying $(ENV) environment..."
	cd environments/$(ENV) && terraform apply tfplan

destroy:
	@echo "Destroying $(ENV) environment..."
	cd environments/$(ENV) && terraform destroy

fmt:
	@echo "Formatting Terraform files..."
	terraform fmt -recursive .

validate:
	@echo "Validating all modules..."
	@for dir in $(MODULE_DIRS); do \
		echo "Validating $$dir..."; \
		cd $$dir && terraform init -backend=false > /dev/null 2>&1 && terraform validate && cd ../..; \
	done

lint:
	@echo "Linting all modules..."
	@for dir in $(MODULE_DIRS); do \
		echo "Linting $$dir..."; \
		tflint --chdir=$$dir; \
	done

clean:
	@echo "Cleaning up..."
	find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	find . -name "*.tfplan" -delete 2>/dev/null || true
	find . -name ".terraform.lock.hcl" -delete 2>/dev/null || true
