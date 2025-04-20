{
  description = "Docker abbreviations for fish-shell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nur = {
      url = "github:Omochice/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };
  };

  outputs =
    {
      nixpkgs,
      treefmt-nix,
      nur,
      ...
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      treefmt =
        system:
        treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} (
          { ... }:
          {
            settings.global.excludes = [
              "CHANGELOG.md"
              ".github/release-please-manifest.json"
            ];
            programs = {
              # keep-sorted start block=yes
              fish_indent.enable = true;
              formatjson5 = {
                enable = true;
                indent = 2;
              };
              jsonfmt.enable = true;
              keep-sorted.enable = true;
              mdformat.enable = true;
              nixfmt.enable = true;
              yamlfmt = {
                enable = true;
                settings = {
                  formatter = {
                    type = "basic";
                    retain_line_breaks_single = true;
                  };
                };
              };
              # keep-sorted end
            };
          }
        );
    in
    {
      formatter = forAllSystems (system: (treefmt system).config.build.wrapper);
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          check-action = pkgs.mkShell {
            buildInputs = with pkgs; [
              actionlint
              nur.packages.${system}.ghalint
            ];
          };
          renovate = pkgs.mkShell {
            buildInputs = with pkgs; [
              renovate
            ];
          };
        }
      );
    };
}
