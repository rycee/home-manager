{ pkgs, lib, config, ... }:

with lib;

{
  meta.maintainers = with maintainers; [ jD91mZM2 ];

  options.xdg.autoStart =
    mkEnableOption "autostarting of files in the XDG autostart directories";

  config = mkIf config.xdg.autoStart {
    # Run dex to autostart all directories in $XDG_CONFIG_DIRS/autostart. Runs
    # outside of a systemd unit because it might need full access to $PATH
    # (some desktop files don't specify absolute paths in ExecFile=)
    xsession.initExtra = ''
      ${pkgs.dex}/bin/dex -a
    '';
  };
}
