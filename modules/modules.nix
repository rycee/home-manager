{ pkgs
, lib

  # Whether to enable module type checking.
, check ? true

  # Whether these modules are inside a NixOS submodule.
, nixosSubmodule ? false
}:

with lib;

let

  modules = [
    ./files.nix
    ./home-environment.nix
    ./manual.nix
    ./misc/fontconfig.nix
    ./misc/gtk.nix
    ./misc/news.nix
    ./misc/nixpkgs.nix
    ./misc/pam.nix
    ./misc/xdg.nix
    ./programs/autorandr.nix
    ./programs/bash.nix
    ./programs/beets.nix
    ./programs/browserpass.nix
    ./programs/command-not-found/command-not-found.nix
    ./programs/eclipse.nix
    ./programs/emacs.nix
    ./programs/feh.nix
    ./programs/firefox.nix
    ./programs/fzf.nix
    ./programs/git.nix
    ./programs/gnome-terminal.nix
    ./programs/home-manager.nix
    ./programs/htop.nix
    ./programs/info.nix
    ./programs/lesspipe.nix
    ./programs/man.nix
    ./programs/mercurial.nix
    ./programs/neovim.nix
    ./programs/pidgin.nix
    ./programs/rofi.nix
    ./programs/ssh.nix
    ./programs/termite.nix
    ./programs/texlive.nix
    ./programs/vim.nix
    ./programs/zsh.nix
    ./services/blueman-applet.nix
    ./services/compton.nix
    ./services/dunst.nix
    ./services/gnome-keyring.nix
    ./services/gpg-agent.nix
    ./services/kbfs.nix
    ./services/keepassx.nix
    ./services/keybase.nix
    ./services/mbsync.nix
    ./services/network-manager-applet.nix
    ./services/owncloud-client.nix
    ./services/parcellite.nix
    ./services/polybar.nix
    ./services/random-background.nix
    ./services/redshift.nix
    ./services/screen-locker.nix
    ./services/stalonetray.nix
    ./services/syncthing.nix
    ./services/taffybar.nix
    ./services/tahoe-lafs.nix
    ./services/udiskie.nix
    ./services/unclutter.nix
    ./services/window-managers/i3.nix
    ./services/window-managers/xmonad.nix
    ./services/xscreensaver.nix
    ./systemd.nix
    ./xcursor.nix
    ./xresources.nix
    ./xsession.nix
    <nixpkgs/nixos/modules/misc/assertions.nix>
    <nixpkgs/nixos/modules/misc/lib.nix>
    <nixpkgs/nixos/modules/misc/meta.nix>
  ];

  pkgsModule = {
    options.nixosSubmodule = mkOption {
      type = types.bool;
      internal = true;
      readOnly = true;
    };

    config._module.args.baseModules = modules;
    config._module.args.pkgs = lib.mkDefault pkgs;
    config._module.check = check;
    config.lib = import ./lib { inherit lib; };
    config.nixosSubmodule = nixosSubmodule;
    config.nixpkgs.system = mkDefault pkgs.system;
  };

in

  modules ++ [ pkgsModule ]
