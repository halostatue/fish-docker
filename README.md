# halostatue/fish-docker

Completions for [Docker] in the [fish shell], based on [docker-fish-completion].

[![Version badge]][latest]

## Installation

Install with [Fisher](recommended):

```fish
# Fisher 3.x
fisher add halostatue/fish-docker

# Fisher 4.0+
fisher install halostatue/fish-docker
```

<details>
<summary>Not using a package manager?</summary>

---

Copy `completions/*.fish` and `conf.d/*.fish` to your fish configuration
directory preserving the directory structure.

</details>

### System Requirements

- [fish][fish shell] 3.0+
- [Docker]
- Ruby 2.6 or later (to generate completions).

## `gen_completions.rb`

Ported from the Python script in [docker-fish-completion] to Ruby, fixing
some bugs along the way. This should be considered the initial version of the
script, as it does what the Python version did and no more. The plans are to
simplify the generation process further so that the completions are more
readily updated in place, and that commands that themselves have subcommands
can be handled.

It has been tested with Ruby 2.6.

### Usage / Updating

A `Makefile` has been added to make building this easier.

```fish
make
# OR

make docker
make docker-copmose

# OR
./gen_completions.rb docker > completions/docker.fish
./gen_completions.rb docker-compose > completions/docker-compose.fish
```

## License

[MIT](LICENCE.md)

[docker]: https://www.docker.com
[fish shell]: https://fishshell.com 'friendly interactive shell'
[fisher]: https://github.com/jorgebucaran/fisher
[fish]: https://github.com/fish-shell/fish-shell
[docker-fish-completion]: https://github.com/barnybug-archive/docker-fish-completion
[version badge]: https://img.shields.io/github/tag/halostatue/fish-docker.svg?label=Version
[latest]: https://github.com/halostatue/fish-docker/releases/latest
