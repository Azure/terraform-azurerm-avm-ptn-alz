.PHONY: docs
docs:
	@echo "==> Generating module documentation..."
	terraform-docs -c .terraform-docs.yml .
	@echo "==> Generating examples documentation..."
	cd examples && for d in $$(ls -d */); do terraform-docs  $$d; done

.PHONY: fmt
fmt:
	@echo "==> Fixing Terraform code with terraform fmt..."
	terraform fmt -recursive
	@echo "==> Fixing embedded Terraform with terrafmt..."
	find . | egrep ".md|.tf" | grep -v README.md | sort | while read f; do terrafmt fmt $$f; done

.PHONY: tools
tools:
	go install github.com/katbyte/terrafmt@latest
	go install github.com/terraform-docs/terraform-docs@latest
