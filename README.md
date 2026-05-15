# srt-flake

Nix flake for building [Anthropic Sandbox Runtime (ASRT)](https://github.com/anthropic-experimental/sandbox-runtime) — a general-purpose tool for wrapping security boundaries around arbitrary processes.

## Usage

Run directly:

```sh
nix run github:kblissett/srt-flake -- <args>
```

Or install into a profile:

```sh
nix profile install github:kblissett/srt-flake
srt <args>
```

## Platform support

Currently builds for `aarch64-darwin` only.
