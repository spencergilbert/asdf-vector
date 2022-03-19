<div align="center">

# asdf-vector [![Build](https://github.com/spencergilbert/asdf-vector/actions/workflows/build.yml/badge.svg)](https://github.com/spencergilbert/asdf-vector/actions/workflows/build.yml) [![Lint](https://github.com/spencergilbert/asdf-vector/actions/workflows/lint.yml/badge.svg)](https://github.com/spencergilbert/asdf-vector/actions/workflows/lint.yml)


[vector](https://vector.dev) plugin for the [asdf version manager](https://asdf-vm.com).

</div>

# Contents

- [Dependencies](#dependencies)
- [Install](#install)
- [Contributing](#contributing)
- [License](#license)

# Dependencies

- `bash`, `curl`, `tar`: generic POSIX utilities.

# Install

Plugin:

```shell
asdf plugin add vector
# or
asdf plugin add vector https://github.com/spencergilbert/asdf-vector.git
```

vector:

```shell
# Show all installable versions
asdf list-all vector

# Install specific version
asdf install vector latest

# Set a version globally (on your ~/.tool-versions file)
asdf global vector latest

# Now vector commands are available
vector --help
```

Check [asdf](https://github.com/asdf-vm/asdf) readme for more instructions on how to
install & manage versions.

# Contributing

Contributions of any kind welcome! See the [contributing guide](contributing.md).

[Thanks goes to these contributors](https://github.com/spencergilbert/asdf-vector/graphs/contributors)!

# License

See [LICENSE](LICENSE) © [Spencer Gilbert](https://github.com/spencergilbert/)

