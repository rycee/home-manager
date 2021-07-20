{ pkgs

# Note, this should be "the standard library" + HM extensions.
, lib

# Whether to enable module type checking.
, check ? true

  # If disabled, the pkgs attribute passed to this function is used instead.
, useNixpkgsModule ? true }:

with lib;

let

  modules = [
    ./accounts/email.nix
    ./config/i18n.nix
    ./files.nix
    ./home-environment.nix
    ./i18n/input-method/default.nix
    ./manual.nix
    ./misc/dconf.nix
    ./misc/debug.nix
    ./misc/fontconfig.nix
    ./misc/gtk.nix
    ./misc/lib.nix
    ./misc/news.nix
    ./misc/numlock.nix
    ./misc/pam.nix
    ./misc/qt.nix
    ./misc/submodule-support.nix
    ./misc/tmpfiles.nix
    ./misc/version.nix
    ./misc/vte.nix
    ./misc/xdg-desktop-entries.nix
    ./misc/xdg-mime-apps.nix
    ./misc/xdg-mime.nix
    ./misc/xdg-system-dirs.nix
    ./misc/xdg-user-dirs.nix
    ./misc/xdg.nix
    ./programs/abook.nix
    ./programs/afew.nix
    ./programs/alacritty.nix
    ./programs/alot.nix
    ./programs/aria2.nix
    ./programs/astroid.nix
    ./programs/autojump.nix
    ./programs/autorandr.nix
    ./programs/bash.nix
    ./programs/bat.nix
    ./programs/beets.nix
    ./programs/broot.nix
    ./programs/browserpass.nix
    ./programs/chromium.nix
    ./programs/command-not-found/command-not-found.nix
    ./programs/dircolors.nix
    ./programs/direnv.nix
    ./programs/eclipse.nix
    ./programs/emacs.nix
    ./programs/exa.nix
    ./programs/feh.nix
    ./programs/firefox.nix
    ./programs/fish.nix
    ./programs/foot.nix
    ./programs/fzf.nix
    ./programs/getmail.nix
    ./programs/gh.nix
    ./programs/git.nix
    ./programs/gnome-terminal.nix
    ./programs/go.nix
    ./programs/gpg.nix
    ./programs/himalaya.nix
    ./programs/home-manager.nix
    ./programs/htop.nix
    ./programs/i3status-rust.nix
    ./programs/i3status.nix
    ./programs/info.nix
    ./programs/irssi.nix
    ./programs/jq.nix
    ./programs/kakoune.nix
    ./programs/keychain.nix
    ./programs/kitty.nix
    ./programs/lazygit.nix
    ./programs/lesspipe.nix
    ./programs/lf.nix
    ./programs/lieer.nix
    ./programs/lsd.nix
    ./programs/man.nix
    ./programs/mangohud.nix
    ./programs/matplotlib.nix
    ./programs/mbsync.nix
    ./programs/mcfly.nix
    ./programs/mercurial.nix
    ./programs/mpv.nix
    ./programs/msmtp.nix
    ./programs/mu.nix
    ./programs/ncmpcpp.nix
    ./programs/ncspot.nix
    ./programs/ne.nix
    ./programs/neomutt.nix
    ./programs/neovim.nix
    ./programs/newsboat.nix
    ./programs/nix-index.nix
    ./programs/noti.nix
    ./programs/notmuch.nix
    ./programs/nushell.nix
    ./programs/obs-studio.nix
    ./programs/octant.nix
    ./programs/offlineimap.nix
    ./programs/opam.nix
    ./programs/password-store.nix
    ./programs/pazi.nix
    ./programs/pet.nix
    ./programs/pidgin.nix
    ./programs/piston-cli.nix
    ./programs/powerline-go.nix
    ./programs/qutebrowser.nix
    ./programs/rbw.nix
    ./programs/readline.nix
    ./programs/rofi-pass.nix
    ./programs/rofi.nix
    ./programs/rtorrent.nix
    ./programs/sbt.nix
    ./programs/scmpuff.nix
    ./programs/senpai.nix
    ./programs/skim.nix
    ./programs/sm64ex.nix
    ./programs/ssh.nix
    ./programs/starship.nix
    ./programs/taskwarrior.nix
    ./programs/terminator.nix
    ./programs/termite.nix
    ./programs/texlive.nix
    ./programs/tmux.nix
    ./programs/topgrade.nix
    ./programs/urxvt.nix
    ./programs/vim.nix
    ./programs/vscode.nix
    ./programs/vscode/haskell.nix
    ./programs/waybar.nix
    ./programs/xmobar.nix
    ./programs/z-lua.nix
    ./programs/zathura.nix
    ./programs/zoxide.nix
    ./programs/zplug.nix
    ./programs/zsh.nix
    ./programs/zsh/prezto.nix
    ./services/barrier.nix
    ./services/blueman-applet.nix
    ./services/caffeine.nix
    ./services/cbatticon.nix
    ./services/clipmenu.nix
    ./services/compton.nix
    ./services/devilspie2.nix
    ./services/dropbox.nix
    ./services/dunst.nix
    ./services/dwm-status.nix
    ./services/emacs.nix
    ./services/etesync-dav.nix
    ./services/flameshot.nix
    ./services/fluidsynth.nix
    ./services/getmail.nix
    ./services/gnome-keyring.nix
    ./services/gpg-agent.nix
    ./services/grobi.nix
    ./services/hound.nix
    ./services/imapnotify.nix
    ./services/kanshi.nix
    ./services/kbfs.nix
    ./services/kdeconnect.nix
    ./services/keepassx.nix
    ./services/keybase.nix
    ./services/keynav.nix
    ./services/lieer.nix
    ./services/lorri.nix
    ./services/mako.nix
    ./services/mbsync.nix
    ./services/mpd.nix
    ./services/mpdris2.nix
    ./services/mpris-proxy.nix
    ./services/muchsync.nix
    ./services/network-manager-applet.nix
    ./services/nextcloud-client.nix
    ./services/owncloud-client.nix
    ./services/pantalaimon.nix
    ./services/parcellite.nix
    ./services/pass-secret-service.nix
    ./services/password-store-sync.nix
    ./services/pasystray.nix
    ./services/pbgopy.nix
    ./services/picom.nix
    ./services/plan9port.nix
    ./services/playerctld.nix
    ./services/polybar.nix
    ./services/poweralertd.nix
    ./services/pulseeffects.nix
    ./services/random-background.nix
    ./services/redshift-gammastep/gammastep.nix
    ./services/redshift-gammastep/redshift.nix
    ./services/rsibreak.nix
    ./services/screen-locker.nix
    ./services/spotifyd.nix
    ./services/stalonetray.nix
    ./services/status-notifier-watcher.nix
    ./services/sxhkd.nix
    ./services/syncthing.nix
    ./services/taffybar.nix
    ./services/tahoe-lafs.nix
    ./services/taskwarrior-sync.nix
    ./services/udiskie.nix
    ./services/unclutter.nix
    ./services/unison.nix
    ./services/volnoti.nix
    ./services/window-managers/awesome.nix
    ./services/window-managers/bspwm/default.nix
    ./services/window-managers/i3-sway/i3.nix
    ./services/window-managers/i3-sway/sway.nix
    ./services/window-managers/xmonad.nix
    ./services/wlsunset.nix
    ./services/xcape.nix
    ./services/xembed-sni-proxy.nix
    ./services/xidlehook.nix
    ./services/xscreensaver.nix
    ./services/xsettingsd.nix
    ./services/xsuspender.nix
    ./systemd.nix
    ./targets/darwin
    ./targets/generic-linux.nix
    ./xcursor.nix
    ./xresources.nix
    ./xsession.nix
    (pkgs.path + "/nixos/modules/misc/assertions.nix")
    (pkgs.path + "/nixos/modules/misc/meta.nix")
  ] ++ optional useNixpkgsModule ./misc/nixpkgs.nix;

  pkgsModule = { config, ... }: {
    config = {
      _module.args.baseModules = modules;
      _module.args.pkgsPath = lib.mkDefault
        (if versionAtLeast config.home.stateVersion "20.09" then
          pkgs.path
        else
          <nixpkgs>);
      _module.args.pkgs = lib.mkDefault pkgs;
      _module.check = check;
      lib = lib.hm;
    } // optionalAttrs useNixpkgsModule {
      nixpkgs.system = mkDefault pkgs.system;
    };
  };

in modules ++ [ pkgsModule ]
