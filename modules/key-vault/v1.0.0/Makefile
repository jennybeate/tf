.PHONY: validate fmt lint security test all

validate:
	terraform init -backend=false
	terraform validate

fmt:
	terraform fmt -recursive

lint:
	tflint --recursive

security:
	tfsec .

test:
	terraform test

all: fmt validate lint security test
