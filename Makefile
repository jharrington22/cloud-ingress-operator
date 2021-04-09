include boilerplate/generated-includes.mk

SHELL := /usr/bin/env bash

# Extend Makefile after here
CONTAINER_ENGINE=docker

# Needed for build-catalog-image
CATALOG_REGISTRY_ORGANIZATION?=app-sre

# Enable boilerplate OLM CSV generate script
DEFAULT_CSV_GENRATOR=common

# TODO: Remove once app-interface config is updated
.PHONY: build
build: docker-build
	@echo "$@ success!"

# TODO: Remove once app-interface and prow config is updated
.PHONY: gobuild
gobuild: go-build
	@echo "$@ success!"

# Build the docker image
# TODO: Remove below target once prow config is updated
.PHONY: container-build
container-build: docker-build
	@echo "$@ success!"

# Push the docker image
# TODO: Remove below target once prow config is updated
.PHONY: container-push
container-push: docker-push
	@echo "$@ success!"

# TODO: Remove below target once prow config is updated
.PHONY: operator-sdk-generate
operator-sdk-generate: generate
	@echo "$@ success!"

# TODO: Removed once standardized in boilerplate
.PHONY: generate-syncset
generate-syncset:
	if [ "${IN_CONTAINER}" == "true" ]; then \
		$(CONTAINER_ENGINE) pull quay.io/app-sre/python:3 && $(CONTAINER_ENGINE) tag quay.io/app-sre/python:3 python:3 || true; \
		$(CONTAINER_ENGINE) run --rm -v `pwd -P`:`pwd -P` python:3 /bin/sh -c "cd `pwd`; pip install oyaml; `pwd`/${GEN_SYNCSET}"; \
	else \
		${GEN_SYNCSET}; \
	fi

# TODO: Remove once standardized in boilerplate
.PHONY: skopeo-push
skopeo-push: container-build
	skopeo copy \
		--dest-creds "${QUAY_USER}:${QUAY_TOKEN}" \
		"docker-daemon:${OPERATOR_IMAGE_URI_LATEST}" \
		"docker://${OPERATOR_IMAGE_URI_LATEST}"
	skopeo copy \
		--dest-creds "${QUAY_USER}:${QUAY_TOKEN}" \
		"docker-daemon:${OPERATOR_IMAGE_URI}" \
		"docker://${OPERATOR_IMAGE_URI}"

.PHONY: build-catalog-image
build-catalog-image:
	$(call create_push_catalog_image,staging,service/saas-$(OPERATOR_NAME)-bundle,$$APP_SRE_BOT_PUSH_TOKEN,false,service/app-interface,data/services/osd-operators/cicd/saas/saas-$(OPERATOR_NAME).yaml,hack/generate-operator-bundle.py,$(CATALOG_REGISTRY_ORGANIZATION))
	$(call create_push_catalog_image,production,service/saas-$(OPERATOR_NAME)-bundle,$$APP_SRE_BOT_PUSH_TOKEN,true,service/app-interface,data/services/osd-operators/cicd/saas/saas-$(OPERATOR_NAME).yaml,hack/generate-operator-bundle.py,$(CATALOG_REGISTRY_ORGANIZATION))

.PHONY: boilerplate-update
boilerplate-update:
	@boilerplate/update
