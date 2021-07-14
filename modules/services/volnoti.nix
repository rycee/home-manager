{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.volnoti;

in {
  meta.maintainers = [ maintainers.imalison ];

  options = {
    services.volnoti = { enable = mkEnableOption "Volnoti volume HUD daemon"; };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.volnoti ];
    systemd.user.services.volnoti = {
      Unit = { Description = "volnoti"; };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = { ExecStart = "${pkgs.volnoti}/bin/volnoti -v -n"; };
    };
  };
}
