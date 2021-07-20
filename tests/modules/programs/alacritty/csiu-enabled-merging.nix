{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.alacritty = {
      enable = true;
      CSIuSupport = true;
      package = pkgs.writeScriptBin "dummy-alacritty" "";

      settings = {
        key_bindings = [{
          key = "K";
          mods = "Control";
          chars = "\\x0c";
        }];
      };
    };

    nmt.script = ''
      assertFileContent \
        home-files/.config/alacritty/alacritty.yml \
        ${./csiu-enabled-merging-expected.yml}
    '';
  };
}
