{ pkgs ? import <nixpkgs> {} }:

let

  lib = import ../modules/lib/stdlib-extended.nix pkgs.lib;

  nmt = pkgs.fetchFromGitLab {
    owner = "rycee";
    repo = "nmt";
    rev = "d2cc8c1042b1c2511f68f40e2790a8c0e29eeb42";
    sha256 = "1ykcvyx82nhdq167kbnpgwkgjib8ii7c92y3427v986n2s5lsskc";
  };

  modules = import ../modules/modules.nix {
    inherit lib pkgs;
    check = false;
  } ++ [
    {
      # Fix impurities. Without these some of the user's environment
      # will leak into the tests through `builtins.getEnv`.
      xdg.enable = true;
      home.username = "hm-user";
      home.homeDirectory = "/home/hm-user";

      # Avoid including documentation since this will cause
      # unnecessary rebuilds of the tests.
      manual.manpages.enable = false;

      imports = [ ./asserts.nix ];
    }
  ];

in

import nmt {
  inherit lib pkgs modules;
  testedAttrPath = [ "home" "activationPackage" ];
  tests = builtins.foldl' (a: b: a // (import b)) { } ([
    ./lib/types
    ./modules/files
    ./modules/home-environment
    ./modules/misc/fontconfig
    ./modules/programs/alacritty
    ./modules/programs/alot
    ./modules/programs/aria2
    ./modules/programs/autojump
    ./modules/programs/bash
    ./modules/programs/browserpass
    ./modules/programs/dircolors
    ./modules/programs/direnv
    ./modules/programs/feh
    ./modules/programs/fish
    ./modules/programs/gh
    ./modules/programs/git
    ./modules/programs/gpg
    ./modules/programs/htop
    ./modules/programs/i3status
    ./modules/programs/irsii
    ./modules/programs/kakoune
    ./modules/programs/kitty
    ./modules/programs/lf
    ./modules/programs/lieer
    ./modules/programs/man
    ./modules/programs/mbsync
    ./modules/programs/mpv
    ./modules/programs/ncmpcpp
    ./modules/programs/ne
    ./modules/programs/neomutt
    ./modules/programs/newsboat
    ./modules/programs/nix-index
    ./modules/programs/nushell
    ./modules/programs/pet
    ./modules/programs/powerline-go
    ./modules/programs/qutebrowser
    ./modules/programs/readline
    ./modules/programs/sbt
    ./modules/programs/scmpuff
    ./modules/programs/ssh
    ./modules/programs/starship
    ./modules/programs/texlive
    ./modules/programs/tmux
    ./modules/programs/topgrade
    ./modules/programs/vscode
    ./modules/programs/zplug
    ./modules/programs/zsh
    ./modules/xresources
  ] ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
    ./modules/targets-darwin
  ] ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
    ./modules/config/i18n
    ./modules/misc/debug
    ./modules/misc/gtk
    ./modules/misc/numlock
    ./modules/misc/pam
    ./modules/misc/qt
    ./modules/misc/xdg
    ./modules/misc/xsession
    ./modules/programs/abook
    ./modules/programs/autorandr
    ./modules/programs/firefox
    ./modules/programs/foot
    ./modules/programs/getmail
    ./modules/programs/gnome-shell
    ./modules/programs/i3status-rust
    ./modules/programs/mangohud
    ./modules/programs/ncmpcpp-linux
    ./modules/programs/neovim   # Broken package dependency on Darwin.
    ./modules/programs/rbw
    ./modules/programs/rofi
    ./modules/programs/rofi-pass
    ./modules/programs/waybar
    ./modules/services/barrier
    ./modules/services/dropbox
    ./modules/services/emacs
    ./modules/services/fluidsynth
    ./modules/services/kanshi
    ./modules/services/lieer
    ./modules/services/pantalaimon
    ./modules/services/pbgopy
    ./modules/services/playerctld
    ./modules/services/polybar
    ./modules/services/redshift-gammastep
    ./modules/services/sxhkd
    ./modules/services/syncthing
    ./modules/services/window-managers/i3
    ./modules/services/window-managers/sway
    ./modules/services/wlsunset
    ./modules/systemd
    ./modules/targets-linux
  ]);
}
