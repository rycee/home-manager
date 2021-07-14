{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.easyeffects;

  presetOpts = optionalString (cfg.preset != "") "--load-preset ${cfg.preset}";

in {
  meta.maintainers = [ maintainers.fufexan ];

  options.services.easyeffects = {
    enable = mkEnableOption "Easyeffects daemon";

    preset = mkOption {
      type = types.str;
      default = "";
      description = ''
        Which preset to use when starting easyeffects.
        Will likely need to launch easyeffects to initially create preset.
      '';
    };
  };

  config = mkIf cfg.enable {
    # running easyeffects will just attach itself to gapplication service
    # at-spi2-core is to minimize journalctl noise of:
    # "AT-SPI: Error retrieving accessibility bus address: org.freedesktop.DBus.Error.ServiceUnknown: The name org.a11y.Bus was not provided by any .service files"
    home.packages = with pkgs; [ easyeffects at-spi2-core ];

    # Will need to add `services.dbus.packages = with pkgs; [ gnome.dconf ];`
    # to /etc/nixos/configuration.nix for daemon to work correctly

    systemd.user.services.easyeffects = {
      Unit = {
        Description = "Easyeffects daemon";
        Requires = [ "dbus.service" ];
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" "pipewire.service" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = {
        ExecStart =
          "${pkgs.easyeffects}/bin/easyeffects --gapplication-service ${presetOpts}";
        ExecStop = "${pkgs.easyeffects}/bin/easyeffects --quit";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
