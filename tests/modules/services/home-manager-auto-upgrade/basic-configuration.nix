{ config, ... }:

{
  config = {
    services.home-manager-auto-upgrade = {
      enable = true;
      frequency = "00:00";
    };

    nmt.script = ''
      local serviceFile=home-files/.config/systemd/user/home-manager-auto-upgrade.service
      assertFileExists $serviceFile

      local timerFile=home-files/.config/systemd/user/home-manager-auto-upgrade.timer
      assertFileExists $timerFile
    '';
  };
}
