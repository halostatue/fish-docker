all: docker docker-compose

docker:
	@ruby gen_completions.rb docker > completions/docker.fish

docker-compose:
	@ruby gen_completions.rb docker-compose > completions/docker-compose.fish
