{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.manual;

  docs = import ../doc { inherit lib pkgs; };

in {
  options = {
    manual.html.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to install the HTML manual. This also installs the
        <command>home-manager-help</command> tool, which opens a local
        copy of the Home Manager manual in the system web browser.
      '';
    };

    manual.manpages.enable = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = ''
        Whether to install the configuration manual page. The manual can
        be reached by <command>man home-configuration.nix</command>.
        </para><para>
        When looking at the manual page pretend that all references to
        NixOS stuff are actually references to Home Manager stuff.
        Thanks!
      '';
    };

    manual.json.enable = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Whether to install a JSON formatted list of all Home Manager
        options. This can be located at
        <filename>&lt;profile directory&gt;/share/doc/home-manager/options.json</filename>,
        and may be used for navigating definitions, auto-completing,
        and other miscellaneous tasks.
      '';
    };
  };

  config = {
    home.packages = mkMerge [
      (mkIf cfg.html.enable [ docs.manual.html docs.manual.htmlOpenTool ])
      (mkIf cfg.manpages.enable [ docs.manPages ])
      (mkIf cfg.json.enable [ docs.options.json ])
    ];

    # Whether a dependency on nmd should be introduced.
    home.extraBuilderCommands =
      mkIf (cfg.html.enable || cfg.manpages.enable || cfg.json.enable) ''
        mkdir $out/lib
        ln -s ${docs.nmdSrc} $out/lib/nmd
      '';
  };

}
