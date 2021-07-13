{ config, lib, pkgs, ... }:

let

  cfg = config.services.home-manager-auto-upgrade;

in {
  meta.maintainers = [ lib.maintainers.pinage404 ];

  options = {
    services.home-manager.auto-upgrade = {
      enable = lib.mkEnableOption ''
        Home Manager upgrade
        Service that run `home-manager switch` periodically with a SystemD's service
      '';

      frequency = lib.mkOption {
        type = lib.types.str;
        default = "12:30";
        example = "weekly";
        description = ''
          How often or when Home Manager is run.
          This value is passed to the SystemD timer configuration as the OnCalendar option.
          The format is described in
          <citerefentry>
            <refentrytitle>systemd.time</refentrytitle>
            <manvolnum>7</manvolnum>
          </citerefentry>.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user = {
      timers.home-manager-auto-upgrade = {
        Unit = { Description = "Home-Manager upgrade timer"; };

        Install = { WantedBy = [ "timers.target" ]; };

        Timer = {
          OnCalendar = cfg.frequency;
          Unit = "home-manager-auto-upgrade.service";
          Persistent = true;
        };
      };

      services.home-manager-auto-upgrade = {
        Unit = {
          Description = "Home-Manager upgrade";
          After = [ "network-online.target" ];
          Wants = [ "network-online.target" ];
        };

        Service = {
          ExecStart = "${pkgs.home-manager}/bin/home-manager switch";
        };
      };
    };
  };
}
