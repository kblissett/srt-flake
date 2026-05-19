# Nix

Always use `nix build --no-link` instead of `nix build`. We only need to verify the build succeeds, not create a `result` symlink.

# Version Control

Always push outside of the sandbox (`dangerouslyDisableSandbox: true`) so that commits are signed with the SSH key.
