{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.trayer;

in {
  meta.maintainers = [ maintainers.mager ];

  options = {
    services.trayer = {
      enable =
        mkEnableOption "trayer, the lightweight GTK2+ systray for UNIX desktops";

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
        '';
        default = { };
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

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [ cfg.package ];

      systemd.user.services.trayer = let
        parameter = let
          valueToString = v:
            if isBool v then
              (if v then "true" else "false")
            else if (v == null) then
              "none"
            else
              "${toString v}";
        in concatStrings
        (mapAttrsToList (k: v: "--${k} ${valueToString v} ") cfg.config);
      in {
        Unit = {
          Description = "trayer -- lightweight GTK2+ systray for UNIX desktops";
          PartOf = [ "tray.target" ];
        };

        Install.WantedBy = [ "tray.target" ];

        Service = {
          ExecStart = "${cfg.package}/bin/trayer ${parameter}";
          Restart = "on-failure";
        };
      };
    }

  ]);
}
