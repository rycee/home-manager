{ configuration
, pkgs
, lib ? pkgs.lib

  # Whether to check that each option has a matching declaration.
, check ? true
  # Extra arguments passed to specialArgs.
, extraSpecialArgs ? { }
}:

with lib;

let

  collectFailed = cfg:
    map (x: x.message) (filter (x: !x.assertion) cfg.assertions);

  showWarnings = res:
    let
      f = w: x: builtins.trace "[1;31mwarning: ${w}[0m" x;
    in
      fold f res res.config.warnings;

  extendedLib = import ./lib/stdlib-extended.nix pkgs;

  hmModules =
    import ./modules.nix {
      inherit check pkgs;
      lib = extendedLib;
    };

  rawModule = extendedLib.evalModules {
    modules = [ configuration ] ++ hmModules;
    specialArgs = {
      modulesPath = builtins.toString ./.;
    } // extraSpecialArgs;
  };

  module = showWarnings (
    let
      failed = collectFailed rawModule.config;
      failedStr = concatStringsSep "\n" (map (x: "- ${x}") failed);
    in
      if failed == []
      then rawModule
      else throw "\nFailed assertions:\n${failedStr}"
  );

in

{
  inherit (module) options config;

  activationPackage = module.config.home.activationPackage;

  # For backwards compatibility. Please use activationPackage instead.
  activation-script = module.config.home.activationPackage;

  newsDisplay = rawModule.config.news.display;
  newsEntries =
    sort (a: b: a.time > b.time) (
      filter (a: a.condition) rawModule.config.news.entries
    );
}
