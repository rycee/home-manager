{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.gpg = {
      enable = true;

      settings = {
        no-comments = false;
        s2k-cipher-algo = "AES128";
        throw-keyids = true;
        trusted-key = [ "0xXXXXXXXXXXXXX" "0xYYYYYYYYYYYYY" ];
      };

      homedir = "${config.home.homeDirectory}/bar/foopg";
    };

    nmt.script = ''
      assertFileExists home-files/bar/foopg/gpg.conf
      assertFileContent home-files/bar/foopg/gpg.conf ${
        ./override-defaults-expected.conf
      }
    '';
  };
}
