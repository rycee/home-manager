{ config, lib, pkgs, ... }:

let
  testScript = pkgs.writeText "test.el" ''
    ;; Emacs won't automatically load default.el when --script is specified
    (load "default")
    (kill-emacs (if (eq hm 'home-manager) 0 1))
  '';

  emacsBin = "${config.programs.emacs.finalPackage}/bin/emacs";
in {
  config = {
    programs.emacs = {
      enable = true;
      package = pkgs.emacs-nox;
      extraConfig = "(setq hm 'home-manager)";
    };

    # running emacs with --script would enable headless mode
    nmt.script = ''
      if ! ${emacsBin} --script ${testScript}; then
        fail "Failed to load default.el."
      fi
    '';
  };
}
