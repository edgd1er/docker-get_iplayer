.PHONY: lint flake8 help all

# Use bash for inline if-statements in arch_patch target
SHELL:=bash -x

# Enable BuildKit for Docker build
export DOCKER_BUILDKIT:=1

MAKEPATH := $(abspath $(lastword $(MAKEFILE_LIST)))
PWD := $(dir $(MAKEPATH))

all: lint build

# https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ## generate help list
		# @$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# Fichiers/,/^# Base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'
		@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

lint: ## lint dockerfile
		@echo "lint Dockerfile ..."
		@docker run --rm -i hadolint/hadolint < ./Dockerfile

build: ## build container transmission v3
		@echo "build image  ..."
		@VERSION=$$(grep -oPm1 "(?<=VERSION=)[0-9\.]+" docker-compose-dev.yml ); \
		docker buildx build --progress auto --load -f Dockerfile --build-arg aptCacher=192.168.53.208 --build-arg VERSION=$${VERSION} --build-arg APP_VERSION=$${VERSION} -t edgd1er/get_iplayer:dev .

down: ## stop and delete container
		@echo "stop and delete container"
		docker compose -f docker-compose-dev.yml down -v

up: ## start container
		@echo "start container"
		docker compose -f docker-compose-dev.yml up

login: ## exec bash
		@echo "login into container"
		docker compose -f docker-compose-dev.yml exec get_iplayer bash

ver: ## check get_iplayer version
		@echo "check get_iplayer version" ;\
		VERSION=$$(grep -oPm1 "(?<=VERSION=)[0-9\.]+" docker-compose-dev.yml ); \
		rver=$$(curl -sX GET "https://api.github.com/repos/get-iplayer/get_iplayer/releases/latest" | jq -r '.tag_name[1:]'); \
		if [[ $${rver:-x} != $${VERSION} ]] || [[ ! -f get_iplayer.$${rver}.tar.gz ]]; then echo "New version detected: $${rver} > $${VERSION}" ;\
		sed -r -i "s/VERSION=.*/VERSION=$${rver}/g" docker-compose-dev.yml ; \
		curl -o get_iplayer.$${rver}.tar.gz -L "https://github.com/get-iplayer/get_iplayer/archive/refs/tags/v$${rver}.tar.gz" ; \
		else echo "No new version, current is $${VERSION}";fi
