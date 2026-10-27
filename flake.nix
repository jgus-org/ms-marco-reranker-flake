{
  description = "cross-encoder/ms-marco-MiniLM-L6-v2 reranker model (HuggingFace), pinned by commit + per-file hash for offline loading (no egress).";

  inputs = {
    flake-lib.url = "github:jgus-org/flake-lib/v1";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs =
    {
      self,
      flake-lib,
      nixpkgs,
    }:
    flake-lib.lib.eachDefaultSystem (
      system:
      let
        pin = import ./pin.nix;
        pkgs = import nixpkgs { inherit system; };
        inherit (pkgs) lib;
        repo = "cross-encoder/ms-marco-MiniLM-L6-v2";

        orgFormatting = flake-lib.lib.mkFormatting {
          inherit self system;
        };

        # Assemble just the needed files into a plain directory CrossEncoder can load by path.
        model =
          pkgs.runCommand "ms-marco-MiniLM-L6-v2"
            {
              meta = {
                description = "Sentence-transformers cross-encoder re-ranker model files for text ranking";
                homepage = "https://huggingface.co/${repo}";
                license = lib.licenses.asl20;
              };
            }
            (
              ''
                mkdir -p "$out"
              ''
              + lib.concatStrings (
                lib.mapAttrsToList (file: hash: ''
                  cp ${
                    pkgs.fetchurl {
                      inherit hash;
                      url = "https://huggingface.co/${repo}/resolve/${pin.rev}/${file}";
                    }
                  } "$out/${file}"
                '') pin.hashes
              )
            );

        # Bespoke rather than flake-lib's mkUpdateVersion: its huggingface source writes { version, sourceRev, hashes }, and this pin is { rev, hashes }, so switching means rewriting the pin's field names and every read of them.
        update-version = pkgs.writeShellApplication {
          name = "update-version";
          text = ''exec ${./update-version.sh} "$@"'';
        };
      in
      {
        checks.formatting = orgFormatting.check;
        formatter = orgFormatting.formatter;
        packages = {
          inherit model update-version;
          default = model;
        };
      }
    );
}
