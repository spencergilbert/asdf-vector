<div align="center">

# asdf-vector [![Build](https://github.com/spencergilbert/asdf-vector/actions/workflows/build.yml/badge.svg)](https://github.com/spencergilbert/asdf-vector/actions/workflows/build.yml) [![Lint](https://github.com/spencergilbert/asdf-vector/actions/workflows/lint.yml/badge.svg)](https://github.com/spencergilbert/asdf-vector/actions/workflows/lint.yml)


[vector](https://vector.dev) plugin for the [asdf version manager](https://asdf-vm.com).

</div>

# Contents

- [Dependencies](#dependencies)
- [Install](#install)
- [Environment Variables](#environment-variables)
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

# Environment Variables

- `ASDF_VECTOR_DISABLE_ROSETTA`: Set to any non-empty value to disable defaulting back to using Rosetta 2 on Apple Silicon Macs if a native version is not available. This is useful if you do not want to install binaries that require Rosetta 2 to run.
- `ASDF_VECTOR_FORCE_CHECKSUM`: Set to any non-empty value to fail if there are no tools to verify the checksum of the downloaded archive, or if the file containing the checksums is not found. By default, this is a best effort process.

# Contributing

Contributions of any kind welcome! See the [contributing guide](contributing.md).

[Thanks goes to these contributors](https://github.com/spencergilbert/asdf-vector/graphs/contributors)!

# License

See [LICENSE](LICENSE) © [Spencer Gilbert](https://github.com/spencergilbert/)

