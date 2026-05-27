{
  description = "Anthropic Sandbox Runtime (ASRT)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    sandbox-runtime = {
      url = "github:anthropic-experimental/sandbox-runtime/v0.0.52";
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
      system = "aarch64-darwin";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
      };
    in
    {
      overlays.default = final: prev: {
        kblissett = (prev.kblissett or { }) // {
          srt = final.buildNpmPackage {
            pname = "sandbox-runtime";
            version = "0.0.52";
            src = sandbox-runtime;

            npmDepsHash = "sha256-IFf65G1v3JtjjH7o8gS68VongLIP3WuKmD/om41yRts=";

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
                --replace-fail @node@ ${final.lib.getExe final.nodejs} \
                --replace-fail @out@ $out
              chmod +x $out/bin/srt
              runHook postInstall
            '';

            meta = {
              description = "A general-purpose tool for wrapping security boundaries around arbitrary processes";
              homepage = "https://github.com/anthropic-experimental/sandbox-runtime";
              license = final.lib.licenses.asl20;
              mainProgram = "srt";
            };
          };
        };
      };

      packages.${system}.default = pkgs.kblissett.srt;

      checks.${system}.tests = pkgs.kblissett.srt.overrideAttrs (old: {
        doCheck = true;
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
          pkgs.bun
          pkgs.bash
          pkgs.ripgrep
          pkgs.curl
        ];
        # sandbox-exec can't nest inside the Nix build sandbox, so exclude
        # test files that spawn seatbelt-wrapped processes
        checkPhase = ''
          runHook preCheck
          bun test $(find test -name '*.test.ts' \
            ! -name 'cli.test.ts' \
            ! -name 'control-fd.test.ts' \
            ! -name 'macos-seatbelt.test.ts' \
            ! -name 'macos-pty.test.ts' \
            ! -name 'macos-allow-local-binding.test.ts' \
            ! -name 'symlink-boundary.test.ts' \
            ! -name 'allow-read.test.ts' \
            ! -name 'mandatory-deny-paths.test.ts' \
            ! -name 'tls-terminate-trust-env.test.ts')
          runHook postCheck
        '';
      });

      apps.${system}.default = {
        type = "app";
        program = "${pkgs.kblissett.srt}/bin/srt";
      };
    };
}
