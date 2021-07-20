{
  description = "Home Manager for Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      # List of systems supported by home-manager binary
      supportedSystems = nixpkgs.lib.platforms.unix;

      # Function to generate a set based on supported systems
      forAllSystems = f:
        nixpkgs.lib.genAttrs supportedSystems (system: f system);

      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in rec {
      nixosModules.home-manager = import ./nixos;
      nixosModule = self.nixosModules.home-manager;

      darwinModules.home-manager = import ./nix-darwin;
      darwinModule = self.darwinModules.home-manager;

      packages = forAllSystems (system: {
        home-manager = nixpkgsFor.${system}.callPackage ./home-manager { };
      });

      defaultPackage =
        forAllSystems (system: self.packages.${system}.home-manager);

      lib = {
        hm = import ./modules/lib { lib = nixpkgs.lib; };
        homeManagerConfiguration = { configuration, system, homeDirectory
          , username, extraModules ? [ ], extraSpecialArgs ? { }
          , pkgs ? nixpkgsFor.${system}, check ? true, stateVersion ? "20.09"
          }@args:
          assert nixpkgs.lib.versionAtLeast stateVersion "20.09";
          import ./modules {
            inherit pkgs check extraSpecialArgs;
            configuration = { ... }: {
              imports = [ configuration ] ++ extraModules;
              home = { inherit homeDirectory stateVersion username; };
              nixpkgs = { inherit (pkgs) config overlays; };
            };
          };
      };
    };
}
