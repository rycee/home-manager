{ config, lib, pkgs, ... }:

with lib;
with import ../lib/dag.nix { inherit lib; };

let

  cfg = config.programs.notmuch;
  configFile = pkgs.writeText "notmuch.conf" 
  # ((if cfg.config != null then with cfg.config; 
  ''

      [database]
      # todo use account name instead
      # create the folder or ?
      path=${config.home.homeDirectory}/maildir
[user]
name=matt
primary_email=mattator@gmail.com
# other_email=

[new]
tags=unread;inbox;
ignore=

[search]
exclude_tags=deleted;spam;

[maildir]
synchronize_flags=true

  '';
  # else "") + "\n" );
    # ${keybindingsStr keybindings}
    # ${concatStringsSep "\n" (mapAttrsToList modeStr modes)}
    # ${concatStringsSep "\n" (mapAttrsToList assignStr assigns)}
    # ${concatStringsSep "\n" (map barStr bars)}
    # ${optionalString (gaps != null) gapsStr}
    # ${concatStringsSep "\n" (map floatingCriteriaStr floating.criteria)}
    # ${concatStringsSep "\n" (map startupEntryStr startup)}
in

{
# TODO per account specifics
# [new]
# tags=unread;inbox;
# ignore=

  options = {
    programs.notmuch = {
      enable = mkEnableOption "Notmuch";

    };
  };





  config = mkIf cfg.enable {
    home.packages = [ pkgs.notmuch ];

    # create folder where to store mails
      home.activation.createMailStore = dagEntryBefore [ "linkGeneration" ] ''
        echo 'hello world, notmuch link activation'
        # if ! cmp --quiet \
        #     "${configFile}" \
        #     "${config.xdg.configHome}/i3/config"; then
        #   i3Changed=1
        # fi
      '';

      # ca s appelle notmuchrc plutot
      xdg.configFile."notmuch/notmuchrc".source = configFile;
      # ''
      # '';
  };
}


