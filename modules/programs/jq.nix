{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.jq;

  colorType = mkOption {
    type = types.str;
    description = "ANSI color definition";
    example = "1;31";
    visible = false;
  };

  colorsType = types.submodule {
    options = {
      null = colorType;
      false = colorType;
      true = colorType;
      numbers = colorType;
      strings = colorType;
      arrays = colorType;
      objects = colorType;
    };
  };

in {
  options = {
    programs.jq = {
      enable = mkEnableOption "the jq command-line JSON processor";

      package = mkOption {
        type = types.package;
        default = pkgs.jq;
        defaultText = literalExample "pkgs.jq";
        description = "The jq package to use.";
      };

      colors = mkOption {
        description = ''
          The colors used in colored JSON output.</para>

          <para>See <link xlink:href="https://stedolan.github.io/jq/manual/#Colors"/>.
        '';

        example = literalExample ''
          {
            null    = "1;30";
            false   = "0;31";
            true    = "0;32";
            numbers = "0;36";
            strings = "0;33";
            arrays  = "1;35";
            objects = "1;37";
          }
        '';

        default = {
          null = "1;30";
          false = "0;37";
          true = "0;37";
          numbers = "0;37";
          strings = "0;32";
          arrays = "1;37";
          objects = "1;37";
        };

        type = colorsType;
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.sessionVariables = let c = cfg.colors;
    in {
      JQ_COLORS =
        "${c.null}:${c.false}:${c.true}:${c.numbers}:${c.strings}:${c.arrays}:${c.objects}";
    };
  };
}
