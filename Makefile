IGW_TARGET_DIR ?= /Users/davidbr/git/clean/gateway-api-inference-extension
IGW_BRANCH ?= bbr-openai-go
IGW_SCRIPTS_HOME ?= /Users/davidbr/git/scripts/scripts


.PHONY: checkout
checkout:
	@if [ -z "$(IGW_BRANCH)" ]; then \
		echo "Error: IGW_BRANCH is required. Usage: make checkout IGW_BRANCH=your-branch"; \
		exit 1; \
	fi
	cd $(IGW_TARGET_DIR) && git checkout $(IGW_BRANCH)

.PHONY: istio
istio: common
	$(IGW_SCRIPTS_HOME)/kind-igw-setup-istio.sh

.PHONY: common
common: clean-colima colima
	$(IGW_SCRIPTS_HOME)/kind-igw-setup-common.sh

.PHONY: colima
colima:
	$(IGW_SCRIPTS_HOME)/kind-metallb-colima-full.sh

.PHONY: clean-colima
clean-colima:
	$(IGW_SCRIPTS_HOME)/kind-metallb-colima-clean.sh
