# Test of explicitly defined options inside the `home.sessionVariables` freeform
# module.

{ config, lib, pkgs, ... }:

let

  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  linuxExpected = ''
    # Only source this once.
    if [ -n "$__HM_SESS_VARS_SOURCED" ]; then return; fi
    export __HM_SESS_VARS_SOURCED=1

    export LOCALE_ARCHIVE_2_27="${pkgs.glibcLocales}/lib/locale/locale-archive"
    export NIX_PATH="testpath=$HOME/testpath''${NIX_PATH:+:$NIX_PATH}"
    export PATH="''${PATH:+$PATH:}$HOME/bin"
    export XDG_CACHE_HOME="/home/hm-user/.cache"
    export XDG_CONFIG_HOME="/home/hm-user/.config"
    export XDG_DATA_HOME="/home/hm-user/.local/share"
  '';

  darwinExpected = ''
    # Only source this once.
    if [ -n "$__HM_SESS_VARS_SOURCED" ]; then return; fi
    export __HM_SESS_VARS_SOURCED=1

    export NIX_PATH="testpath=$HOME/testpath''${NIX_PATH:+:$NIX_PATH}"
    export PATH="''${PATH:+$PATH:}$HOME/bin"
    export XDG_CACHE_HOME="/home/hm-user/.cache"
    export XDG_CONFIG_HOME="/home/hm-user/.config"
    export XDG_DATA_HOME="/home/hm-user/.local/share"
  '';

  expected = pkgs.writeText "expected"
    (if isDarwin then darwinExpected else linuxExpected);

in {
  config = {
    home.sessionVariables = lib.mkMerge [
      {
        PATH = "$PATH";
        NIX_PATH = "$NIX_PATH";
      }
      {
        PATH = lib.mkAfter "$HOME/bin";
        NIX_PATH = lib.mkBefore "testpath=$HOME/testpath";
      }
    ];

    nmt.script = ''
      assertFileExists home-path/etc/profile.d/hm-session-vars.sh
      assertFileContent home-path/etc/profile.d/hm-session-vars.sh \
        ${expected}
    '';
  };
}
