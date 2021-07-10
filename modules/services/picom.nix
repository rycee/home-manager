{ config, lib, pkgs, ... }:

with lib;
with builtins;

# TODO evaluate https://github.com/imZack/jsonlibconfig
let
  cfg = config.services.picom;

  _toConf = v:
    with builtins;
    let isPath = v: typeOf v == "path";
    in if isInt v then
      toString v
    else if isFloat v then
      "${toString v}"
    else if isString v then
      ''"${strings.escape [ ''"'' ] v}"''
    else if true == v then
      "true"
    else if false == v then
      "false"
    else if null == v then
      "null"
    else if isPath v then
      toString v
    else if isList v then
      "[ " + strings.concatMapStringsSep "," _toConf v + " ]"
    else if isAttrs v then
    # apply pretty values if allowed
      if attrNames v == [ "__pretty" "val" ] && allowPrettyValues then
        v.__pretty v.val
        # TODO: there is probably a better representation?
      else if v ? type && v.type == "derivation" then
        "<δ:${v.name}>"
        # "<δ:${concatStringsSep "," (builtins.attrNames v)}>"
      else
        "{ " + strings.concatStringsSep " "
        (attrsets.mapAttrsToList (name: value: "${name} = ${_toConf value};") v)
        + " }"
    else
      abort "picom: not supported: (v = ${v})";

  toConf = v:
    with builtins;
    if isAttrs v then
      if v ? type && v.type == "derivation" then
        abort "picom: not supported: (v = ${v})"
      else
        strings.concatStringsSep " "
        (attrsets.mapAttrsToList (name: value: "${name} = ${_toConf value};") v)
    else
      abort "picom: not supported: (v = ${v})";

  configFile = pkgs.writeText "picom.conf" (toConf cfg.settings);

in {

  options.services.picom = {
    enable = mkEnableOption "Picom X11 compositor";

    experimentalBackends = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to use the new experimental backends.
      '';
    };

    settings = mkOption {
      type = with types;
        let
          prim = oneOf [ bool int str float ];
          primOrPrimAttrs = either prim (attrsOf prim);
          entry = either prim (listOf primOrPrimAttrs);
          entryOrAttrsOf = t: either entry (attrsOf t);
          entries = entryOrAttrsOf (entryOrAttrsOf entry);
        in attrsOf entries // { description = "Picom configuration"; };
      default = { };
      example = literalExample ''
        {
          backend = "glx";
          vsync = false;
          refresh-rate = 0;
          unredir-if-possible = false;
          blur-background = true;
          blur-background-exclude = [ ];
          blur-method = "dual_kawase";
          blur-strength = 10;
          wintypes = {
            dock = {
              corner-radius = 4;
            };
            normal = {
              shadow = true;
            };
          };
          rounded-corners-exclude = [
            "window_type = 'menu'"
            "window_type = 'dock'"
            "window_type = 'dropdown_menu'"
            "window_type = 'popup_menu'"
            "class_g = 'Polybar'"
            "class_g = 'Rofi'"
            "class_g = 'Dunst'"
          ];
          detect-rounded-corners = true;
          corner-radius = 10;
          round-borders = 1;
          frame-opacity = builtins.fromJSON config.lib.base16.theme.alpha;
        }
      '';
      description = ''
        See <link xlink:href="https://github.com/yshui/picom/blob/next/picom.sample.conf" /> for the full list
        of options.
      '';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.picom;
      defaultText = literalExample "pkgs.picom";
      example = literalExample "pkgs.picom";
      description = ''
        picom derivation to use.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    systemd.user.services.picom = {
      Unit = {
        Description = "Picom X11 compositor";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = let
        experimentalBackendsFlag =
          if cfg.experimentalBackends then " --experimental-backends" else "";
      in {
        ExecStart = "${cfg.package}/bin/picom --config ${configFile}"
          + experimentalBackendsFlag;
        Restart = "always";
        RestartSec = 3;
      };
    };
  };
}
