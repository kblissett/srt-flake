# Nix

Always use `nix build --no-link` instead of `nix build`. We only need to verify the build succeeds, not create a `result` symlink.
