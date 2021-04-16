# fish-docker Changelog

## 1.6

- Completions regenerated for Docker version 20.10.5, build 55c4c88 and
  docker-compose version 1.29.0, build 07737305. As with
  `halostatue/fish-docker` 1.5, `docker compose` completions are not yet
  present.

## 1.5

- Updated `gen_completion.rb` to include `management commands` for Docker.
- Use `--force-files` when completing `file`, `PATH`, `FILE`, or `DEST_PATH`
  arguments. This should resolve [#2].
- Improve container printing for `docker cp` so that it _should_ append a
  colon to every container name for completion.
- Completions regenerated for Docker version 20.10.0, build 7287ab3. The
  docker-compose version has not changed (docker-compose version 1.27.4,
  build 40524192). Note that as of Docker 20.10.0, many docker-compose
  commands can be reached with `docker compose`, but that this information is
  not yet returned from `docker --help`.

## 1.4

- Updated `gen_completions.rb` to correctly separate sub-command detection
  for both docker and docker-compose, also to erase existing completions.
- Completions regenerated for Docker version 19.03.13, build 4484c46d9d and
  docker-compose version 1.27.4, build 40524192.

## 1.3

- Completions updated for Docker version 19.03.13, build 4484c46d9d and
  docker-compose version 1.27.4, build 40524192.

## 1.2

- Small developer convenience Makefile added.
- Completions updated as of Docker version 19.03.8, build afacb8b and
  docker-compose version 1.25.5, build 8a1c60f6.

## 1.1

- Fixes and an update provided by James Roeder (@jmaroeder) as [#1]. Thanks
  for the contribution!

## 1.0

- Initial version, forked from [docker-fish-completion][].

[docker-fish-completion]: https://github.com/barnybug-archive/docker-fish-completion
[#1]: https://github.com/halostatue/fish-docker/pull/1
[#2]: https://github.com/halostatue/fish-docker/issues/2
