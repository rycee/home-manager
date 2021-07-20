{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.rofi = {
      enable = true;
      package = pkgs.wofi;
      plugins = [ pkgs.rofi-calc ];
    };

    test.asserts.assertions.expected = [''
      Cannot use provided package with plugins.
    ''];
  };
}
