.DEFAULT_GOAL := help

DOCKERFILE = Dockerfile
ORG = gilleyj
NAME = workflow-php7.2
IMAGE = $(ORG)/$(NAME)
VERSION = 0.0.5
PORT_INT = 80
PORT_EXT = 8020

build: ## Build it
	docker build --squash --force-rm -t $(IMAGE):local -f $(DOCKERFILE) .

rebuild: ## Rebuild it without using cache
	docker build --no-cache --pull --squash --force-rm -t $(IMAGE):local -f $(DOCKERFILE) .

tag: ## Tag it with $(VERSION)
	docker tag $(IMAGE):local $(IMAGE):$(VERSION)

run: ## run it
	docker run -p $(PORT_EXT):$(PORT_INT) --name $(NAME)_run --rm -it $(IMAGE):local

runvolume: ## run it with code volume attached
	docker run -p $(PORT_EXT):$(PORT_INT) --name $(NAME)_run -v ${PWD}/code:/app --rm -id $(IMAGE):local

runshell: ## run the container with an interactive shell
	docker run -p $(PORT_EXT):$(PORT_INT) --name $(NAME)_run --rm -it $(IMAGE):local /bin/sh

connect: ## connect to it
	docker exec -it $(NAME)_run /bin/sh

watchlog: ## connect to it
	docker logs -f $(NAME)_run

kill: ## kill it
	docker kill $(NAME)_run

test: ## Simple tests
	docker build -t php_nginx_test .
	docker run --rm -d -p 127.0.0.1:8880:80 --name php_nginx_test php_nginx_test
	sleep 5
	curl -vsf --head -H 'Accept-Encoding: gzip' 'http://127.0.0.1:8880/' &> /dev/stdout
	curl -vsf --head 'http://127.0.0.1:8880/' &> /dev/stdout
	docker kill php_nginx_test

release: tag ## Create and push release to docker hub
	@if ! docker images $(IMAGE) | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME) version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	docker push $(IMAGE)
	@echo "*** Don't forget to create a tag. git tag rel-$(VERSION) && git push origin rel-$(VERSION)"

.PHONY: help

help: ## Helping devs since 2016
	@cat $(MAKEFILE_LIST) | grep -e "^[a-zA-Z_\-]*: *.*## *" | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo "For additional commands have a look at the README"

