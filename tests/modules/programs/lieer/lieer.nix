{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ ../../accounts/email-test-accounts.nix ];

  config = {
    programs.lieer.enable = true;
    programs.lieer.package = pkgs.writeScriptBin "dummy-gmailieer" "";

    accounts.email.accounts."hm@example.com" = {
      flavor = "gmail.com";
      lieer.enable = true;
      notmuch.enable = true;
    };

    nmt.script = ''
      assertFileExists home-files/Mail/hm@example.com/.gmailieer.json
      assertFileContent home-files/Mail/hm@example.com/.gmailieer.json ${
        ./lieer-expected.json
      }
    '';
  };
}
