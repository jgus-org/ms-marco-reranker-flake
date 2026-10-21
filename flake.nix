{
  description = "cross-encoder/ms-marco-MiniLM-L6-v2 reranker model (HuggingFace), pinned by commit + per-file hash for offline loading (no egress).";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-lib = {
      url = "github:jgus-org/flake-lib/v1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-lib,
      treefmt-nix,
    }:
    flake-lib.lib.eachDefaultSystem (
      system:
      let
        pin = import ./pin.nix;
        pkgs = import nixpkgs { inherit system; };
        inherit (pkgs) lib;
        repo = "cross-encoder/ms-marco-MiniLM-L6-v2";

        treefmtEval = treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";
          programs.nixfmt.enable = true;
          programs.shfmt.enable = true;
        };

        # Assemble just the needed files into a plain directory CrossEncoder can load by path.
        model = pkgs.runCommand "ms-marco-MiniLM-L6-v2" { } (
          ''
            mkdir -p "$out"
          ''
          + lib.concatStrings (
            lib.mapAttrsToList (file: hash: ''
              cp ${
                pkgs.fetchurl {
                  url = "https://huggingface.co/${repo}/resolve/${pin.rev}/${file}";
                  inherit hash;
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
        packages = {
          inherit model update-version;
          default = model;
        };

        formatter = treefmtEval.config.build.wrapper;
        checks.formatting = treefmtEval.config.build.check self;
      }
    );
}
