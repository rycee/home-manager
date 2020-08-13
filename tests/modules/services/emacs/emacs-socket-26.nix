{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    nixpkgs.overlays = [
      (self: super: rec {
        emacs = pkgs.writeShellScriptBin "dummy-emacs-26.3" "" // {
          outPath = "@emacs@";
        };
        emacsPackagesFor = _:
          makeScope super.newScope (_: { emacsWithPackages = _: emacs; });
      })
    ];

    programs.emacs.enable = true;
    services.emacs.enable = true;
    services.emacs.client.enable = true;
    services.emacs.socketActivation.enable = true;

    nmt.script = ''
      assertFileExists home-files/.config/systemd/user/emacs.socket
      assertFileExists home-files/.config/systemd/user/emacs.service
      assertFileExists home-files/.local/share/applications/emacsclient.desktop

      assertFileContent home-files/.config/systemd/user/emacs.socket \
                        ${./emacs-socket-26-emacs.socket}
      assertFileContent home-files/.config/systemd/user/emacs.service \
                        ${
                          pkgs.substituteAll {
                            inherit (pkgs) runtimeShell;
                            src = ./emacs-socket-26-emacs.service;
                          }
                        }
      assertFileContent home-files/.local/share/applications/emacsclient.desktop \
                        ${./emacs-emacsclient.desktop}
    '';
  };
}
