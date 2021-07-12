{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.targets.genericLinux;

  profileDirectory = config.home.profileDirectory;

in {
  imports = [
    (mkRenamedOptionModule [ "targets" "genericLinux" "extraXdgDataDirs" ] [
      "xdg"
      "systemDirs"
      "data"
    ])
  ];

  options.targets.genericLinux = {
    enable = mkEnableOption "" // {
      description = ''
        Whether to enable settings that make Home Manager work better on
        GNU/Linux distributions other than NixOS.
      '';
    };
  };

  config = mkIf cfg.enable {
    xdg.systemDirs.data = [
      # Nix profiles
      "\${NIX_STATE_DIR:-/nix/var/nix}/profiles/default/share"
      "${profileDirectory}/share"

      # Distribution-specific
      "/usr/share/ubuntu"
      "/usr/local/share"
      "/usr/share"
      "/var/lib/snapd/desktop"
    ];

    home.sessionVariablesExtra = ''
      . "${pkgs.nix}/etc/profile.d/nix.sh"

      # reset TERM with new TERMINFO available (if any)
      export TERM="$TERM"
    '';

    # We need to source both nix.sh and hm-session-vars.sh as noted in
    # https://github.com/nix-community/home-manager/pull/797#issuecomment-544783247
    programs.bash.initExtra = ''
      . "${pkgs.nix}/etc/profile.d/nix.sh"
      . "${profileDirectory}/etc/profile.d/hm-session-vars.sh"
    '';
    
    programs.zsh.envExtra = ''
      # Make system functions available to zsh
      () {
        setopt LOCAL_OPTIONS CASE_GLOB EXTENDED_GLOB

        local system_fpaths=(
            # Package default
            /usr/share/zsh/site-functions(/-N)

            # Debian 
            /usr/share/zsh/functions/**/*(/-N)
            /usr/share/zsh/vendor-completions/(/-N) 
            /usr/share/zsh/vendor-functions/(/-N)
        )
        fpath=(''${fpath} ''${system_fpaths})
      }
    '';

    systemd.user.sessionVariables = let
      # https://github.com/archlinux/svntogit-packages/blob/packages/ncurses/trunk/PKGBUILD
      # https://salsa.debian.org/debian/ncurses/-/blob/master/debian/rules
      # https://src.fedoraproject.org/rpms/ncurses/blob/main/f/ncurses.spec
      # https://gitweb.gentoo.org/repo/gentoo.git/tree/sys-libs/ncurses/ncurses-6.2-r1.ebuild
      distroTerminfoDirs = concatStringsSep ":" [
        "/etc/terminfo" # debian, fedora, gentoo
        "/lib/terminfo" # debian
        "/usr/share/terminfo" # package default, all distros
      ];
    in {
      NIX_PATH = "$HOME/.nix-defexpr/channels\${NIX_PATH:+:}$NIX_PATH";
      TERMINFO_DIRS =
        "${profileDirectory}/share/terminfo:$TERMINFO_DIRS\${TERMINFO_DIRS:+:}${distroTerminfoDirs}";
    };
  };
}
