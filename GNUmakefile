SHELL := /usr/bin/env fish

all: docker docker-compose fmt lint

docker:
	@ruby gen_completions.rb docker > completions/docker.fish

docker-compose:
	@ruby gen_completions.rb docker-compose > completions/docker-compose.fish

fmt:
	@fish_indent --write **.fish

lint:
	@for file in **.fish; fish --no-execute $$file; end

.PHONY: \
	all \
	docker \
	docker-compose \
	fmt \
	lint
