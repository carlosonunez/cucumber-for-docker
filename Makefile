#!/usr/bin/env make
MAKEFLAGS += --silent
SHELL := /usr/bin/env bash
DOCKER_IMAGE_NAME := cucumber
define DOCKER_IMAGE_TAGS
alpine-$(shell git rev-parse HEAD | head -c8)
alpine-latest
latest
endef
export DOCKER_IMAGE_TAGS

.PHONY: build test deploy clean
build:
	docker build -t cucumber .

test:
	docker run --rm \
		--tty \
		--volume "$$PWD:/work" \
		--volume /var/run/docker.sock:/var/run/docker.sock \
		--volume $$(which docker):/usr/bin/docker \
		--workdir /work \
		graze/bats tests

deploy: check_for_env_password build test
deploy:
	set -x; \
	$(MAKE) decrypt || { echo "Environment decryption failed." && exit 1; }; \
	if ! docker login \
		-u $$(sed -n '/DOCKER_HUB_USERNAME/s/DOCKER_HUB_USERNAME=//gp' .env) \
		-p $$(sed -n '/DOCKER_HUB_PASSWORD/s/DOCKER_HUB_PASSWORD=//gp' .env); \
	then \
		>&2 echo "[deploy] ERROR: Docker Hub login failed."; \
		exit 1; \
	fi; \
	for tag in $$DOCKER_IMAGE_TAGS; \
	do \
		docker tag cucumber:latest \
			"$$(sed -n '/DOCKER_HUB_USERNAME/s/DOCKER_HUB_USERNAME=//gp' .env)/$(DOCKER_IMAGE_NAME):$$tag" && \
		docker push \
			$$(sed -n '/DOCKER_HUB_USERNAME/s/DOCKER_HUB_USERNAME=//gp' .env)/$(DOCKER_IMAGE_NAME):$$tag ; \
	done; \
	$(MAKE) clean

clean:
	rm .env; \
	for tag in $$DOCKER_IMAGE_TAGS; \
	do \
		docker rmi \
			$$(sed -n '/DOCKER_HUB_USERNAME/s/DOCKER_HUB_USERNAME=//gp' .env)/$(DOCKER_IMAGE_NAME):$$tag ; \
	done; \
	docker rmi -f cucumber:latest; \

.PHONY: encrypt decrypt check_for_env_password
encrypt: check_for_env_password
encrypt:
	docker run --rm --volume "$(PWD):/work" vladgh/gpg \
		--batch \
		--yes \
		--passphrase "$(ENV_PASSWORD)" \
		--output /work/.env.gpg  \
		--symmetric \
		/work/.env

decrypt: check_for_env_password
decrypt:
	docker run --volume "$(PWD):/work" --rm vladgh/gpg \
		--batch \
		--yes \
		--passphrase "$(ENV_PASSWORD)" \
		--output /work/.env  \
		--decrypt \
		/work/.env.gpg

check_for_env_password:
	if test -z "$(ENV_PASSWORD)"; \
	then \
		>&2 echo "[$(MAKECMDGOALS)] ERROR: ENV_PASSWORD missing"; \
		exit 1; \
	fi; \
	exit 0;
