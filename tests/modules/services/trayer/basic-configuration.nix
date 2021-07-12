{ config, pkgs, ... }:

{
  config = {
    services.trayer = {
      enable = true;
      package = pkgs.writeScriptBin "dummy-trayer" "";
      config = {
        edge = "top";
        padding = 6;
        SetDockType = true;
        tint = "0x282c34";
        SetPartialStrut = true;
        expand = true;
        monitor = 1;
      };
    };

    nmt.script = ''
      serviceFile=home-files/.config/systemd/user/trayer.service

      assertFileExists $serviceFile
      assertFileRegex $serviceFile 'ExecStart=.*/bin/trayer --SetDockType true --SetPartialStrut true --edge top --expand true --monitor 1 --padding 6 --tint 0x282c34'
    '';
  };
}
