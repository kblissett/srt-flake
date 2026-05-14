{
  description = "Anthropic Sandbox Runtime (ASRT)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    sandbox-runtime = {
      url = "github:anthropic-experimental/sandbox-runtime";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      sandbox-runtime,
    }:
    let
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;
    in
    {
      packages.aarch64-darwin.default = pkgs.buildNpmPackage {
        pname = "sandbox-runtime";
        version = "0.0.51";
        src = sandbox-runtime;

        npmDepsHash = "sha256-L/BJ0KCBYHAA6BaYZbzNFVPHJZHGnDnpZFo9XepKc4s=";

        buildPhase = ''
          runHook preBuild
          npm run build
          cp -r vendor dist/
          runHook postBuild
        '';

        installPhase = ''
                    runHook preInstall
                    mkdir -p $out/lib/sandbox-runtime $out/bin
                    cp -r dist package.json node_modules $out/lib/sandbox-runtime/

                    cat > $out/bin/srt <<'WRAPPER'
          #!/usr/bin/env bash
          exec @node@ @out@/lib/sandbox-runtime/dist/cli.js "$@"
          WRAPPER
                    substituteInPlace $out/bin/srt \
                      --replace-fail @node@ ${pkgs.lib.getExe pkgs.nodejs} \
                      --replace-fail @out@ $out
                    chmod +x $out/bin/srt
                    runHook postInstall
        '';

        meta = {
          description = "A general-purpose tool for wrapping security boundaries around arbitrary processes";
          homepage = "https://github.com/anthropic-experimental/sandbox-runtime";
          license = pkgs.lib.licenses.asl20;
          mainProgram = "srt";
        };
      };

      apps.aarch64-darwin.default = {
        type = "app";
        program = "${self.packages.aarch64-darwin.default}/bin/srt";
      };
    };
}
