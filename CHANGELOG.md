# fish-docker Changelog

## 1.11 / 2023-09-26

- Completion regenerated for Docker version 24.0.6, build ed223bc820 and Docker
  Compose version 2.21.0

## 1.10 / 2023-05-12

- Completion regenerated for Docker version 23.0.5, build bc4487a59e and Docker
  Compose version 2.17.3.

- Tweaked `gen_completions.rb` to include the Docker and Docker Compose versions
  as part of the completion script output.

## 1.9 / 2022-06-26

- Completion regenerated for Docker version 20.10.17, build 100c70180f and
  Docker Compose version 2.6.0.

- Fixes for the README provided by Petri Kivikangas (@Kitanotori]) as [#3][].
  Thanks for the contribution!

## 1.8 / 2022-05-16

- Completion regenerated for Docker version 20.10.15, build fd82621d35 and
  Docker Compose version 2.5.0. Note that this version of the files have been
  generated with separate installations of `docker` and `docker-compose` through
  Homebrew and not through Docker Desktop.

- Converted the Ruby script to standardrb format

## 1.7 / 2022-04-01

- Completion regenerated for Docker 20.10.12, build e91ed57 and docker-compose
  version 1.29.2, build 5becea4c. `docker compose` completions may not be
  complete as no updates to the parser have been made.

## 1.6 / 2021-04-15

- Completions regenerated for Docker version 20.10.5, build 55c4c88 and
  docker-compose version 1.29.0, build 07737305. As with
  `halostatue/fish-docker` 1.5, `docker compose` completions are not yet
  present.

## 1.5 / 2021-01-17

- Updated `gen_completion.rb` to include `management commands` for Docker.
- Use `--force-files` when completing `file`, `PATH`, `FILE`, or `DEST_PATH`
  arguments. This should resolve [#2][].
- Improve container printing for `docker cp` so that it _should_ append a
  colon to every container name for completion.
- Completions regenerated for Docker version 20.10.0, build 7287ab3. The
  docker-compose version has not changed (docker-compose version 1.27.4,
  build 40524192). Note that as of Docker 20.10.0, many docker-compose
  commands can be reached with `docker compose`, but that this information is
  not yet returned from `docker --help`.

## 1.4 / 2020-11-29

- Updated `gen_completions.rb` to correctly separate sub-command detection
  for both docker and docker-compose, also to erase existing completions.
- Completions regenerated for Docker version 19.03.13, build 4484c46d9d and
  docker-compose version 1.27.4, build 40524192.

## 1.3 / 2020-10-06

- Completions updated for Docker version 19.03.13, build 4484c46d9d and
  docker-compose version 1.27.4, build 40524192.

## 1.2 / 2020-06-14

- Small developer convenience Makefile added.
- Completions updated as of Docker version 19.03.8, build afacb8b and
  docker-compose version 1.25.5, build 8a1c60f6.

## 1.1 / 2020-01-10

- Fixes and an update provided by James Roeder (@jmaroeder) as [#1][]. Thanks
  for the contribution!

## 1.0 / 2019-12-31

- Initial version, forked from [docker-fish-completion][].

[docker-fish-completion]: https://github.com/barnybug-archive/docker-fish-completion
[#1]: https://github.com/halostatue/fish-docker/pull/1
[#2]: https://github.com/halostatue/fish-docker/issues/2
[#3]: https://github.com/halostatue/fish-docker/pull/3
