{ config, lib, pkgs, ... }:

with lib;

let

  boolTrue = {
    type = types.bool;
    values = "true|false";
    default = "true";
  };
  number0 = {
    type = types.int;
    values = "number";
    default = "0";
  };
  knownSettings = {
    edge = {
      type = types.str;
      values = "left|right|top|bottom|none";
      default = "bottom";
    };
    align = {
      type = types.str;
      values = "left|right|center";
      default = "center";
    };
    margin = number0;
    widthtype = {
      type = types.str;
      values = "request|pixel|percent";
      default = "percent";
    };
    width = {
      type = types.int;
      values = "number";
      default = "100";
    };
    heighttype = {
      type = types.str;
      values = "request|pixel";
      default = "pixel";
    };
    height = {
      type = types.int;
      values = "number";
      default = "26";
    };
    SetDockType = boolTrue;
    SetPartialStrut = boolTrue;
    transparent = {
      type = types.bool;
      values = "true|false";
      default = "false";
    };
    alpha = {
      type = types.int;
      values = "number";
      default = "127";
    };
    tint = {
      type = types.str;
      values = "int";
      default = "0xFFFFFFFF";
    };
    distance = number0;
    distancefrom = {
      type = types.str;
      values = "left|right|top|bottom";
      default = "top";
    };
    expand = boolTrue;
    padding = number0;
    monitor = {
      values = "number|primary";
      type = types.str;
      default = "0";
    };
    iconspacing = number0;
  };
  cfg = config.services.trayer;

in {
  meta.maintainers = [ maintainers.mager ];

  options = {
    services.trayer = {
      enable = mkEnableOption
        "trayer, the lightweight GTK2+ systray for UNIX desktops";

      package = mkOption {
        default = pkgs.trayer;
        defaultText = literalExample "pkgs.trayer";
        type = types.package;
        example = literalExample "pkgs.trayer";
        description = "The package to use for the trayer binary.";
      };

      config = mkOption {
        type = with types; attrsOf (nullOr (either str (either bool int)));
        description = ''
          Trayer configuration as a set of attributes.
          Details for trayer can be found here: https://github.com/sargon/trayer-srg
          <informaltable frame="none">
          <tgroup cols="4">
          <tbody>
          <row>
          <entry>proprety name</entry>
          <entry>type</entry>
          <entry>values</entry>
          <entry>default</entry>
          </row>
          ${concatStringsSep "\n" (mapAttrsToList (n: v: ''
            <row>
              <entry><varname>${n}</varname></entry>
              <entry>${v.type.description}</entry>
              <entry>${v.values}</entry>
              <entry>${v.default}</entry>
            </row>
          '') knownSettings)}
          </tbody></tgroup></informaltable>
        '';
        default = { };
        defaultText = literalExample "{ }";
        example = literalExample ''
          {
            edge = "top";
            padding = 6;
            SetDockType = true;
            tint = "0x282c34";
          }
        '';
      };
    };
  };

  config = mkIf cfg.enable ({
    home.packages = [ cfg.package ];
    systemd.user.services.trayer = let
      parameter = let
        valueToString = v:
          if isBool v then (if v then "true" else "false") else "${toString v}";
      in concatStrings
      (mapAttrsToList (k: v: "--${k} ${valueToString v} ") cfg.config);
    in {
      Unit = {
        Description = "trayer -- lightweight GTK2+ systray for UNIX desktops";
        PartOf = [ "tray.target" "graphical-session.target" ];
      };

      Install.WantedBy = [ "graphical-session.target" ];

      Service = {
        ExecStart = "${cfg.package}/bin/trayer ${parameter}";
        Restart = "on-failure";
      };
    };
  });
}
