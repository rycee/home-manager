# Just a convenience function that returns the given Nixpkgs standard
# library extended with the HM library.

pkgs:

let nixpkgsLib = pkgs.lib;
in nixpkgsLib.extend
(self: super: { hm = pkgs.callPackage ./. { lib = super; }; })
