{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.lieer;

  lieerAccounts =
    filter (a: a.lieer.enable) (attrValues config.accounts.email.accounts);

  nonGmailAccounts =
    map (a: a.name) (filter (a: a.flavor != "gmail.com") lieerAccounts);

  nonGmailConfigHelp =
    map (name: ''accounts.email.accounts.${name}.flavor = "gmail.com";'')
    nonGmailAccounts;

  missingNotmuchAccounts = map (a: a.name)
    (filter (a: !a.notmuch.enable && a.lieer.notmuchSetupWarning)
      lieerAccounts);

  notmuchConfigHelp =
    map (name: "accounts.email.accounts.${name}.notmuch.enable = true;")
    missingNotmuchAccounts;

  settingsFormat = pkgs.formats.json { };

  configFile = account: {
    name = "${account.maildir.absPath}/.gmailieer.json";
    value.source = settingsFormat.generate "lieer-${account.address}.json"
      ({ account = account.address; } // account.lieer.settings);
  };

  settingsOpts = {
    drop_non_existing_label = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Allow missing labels on the Gmail side to be dropped.
      '';
    };

    file_extension = mkOption {
      type = types.str;
      default = "";
      example = "mbox";
      description = ''
        Extension to include in local file names, which can be useful
        for indexing with third-party programs.
      '';
    };

    ignore_empty_history = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Work around a Gmail API quirk where an empty change history
        is sometimes returned.
        </para><para>
        See this
        <link xlink:href="https://github.com/gauteh/lieer/issues/120">GitHub issue</link>
        for more details.
      '';
    };

    ignore_remote_labels = mkOption {
      type = types.listOf types.str;
      default = [
        "CATEGORY_FORUMS"
        "CATEGORY_PROMOTIONS"
        "CATEGORY_UPDATES"
        "CATEGORY_SOCIAL"
        "CATEGORY_PERSONAL"
      ];
      description = ''
        Set Gmail labels to ignore when syncing from remote labels to
        local tags (before translations).
      '';
    };

    ignore_tags = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Set labels to ignore when syncing from local tags to
        remote labels (after translations).
      '';
    };

    local_trash_tag = mkOption {
      type = types.str;
      default = "trash";
      description = ''
        Local tag to which the remote Gmail 'TRASH' label is translated.
      '';
    };

    remove_local_messages = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Remove local messages that have been deleted on the remote.
      '';
    };

    replace_slash_with_dot = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Replace '/' with '.' in Gmail labels.
      '';
    };

    timeout = mkOption {
      type = types.ints.unsigned;
      default = 600;
      description = ''
        HTTP timeout in seconds. 0 means forever or system timeout.
      '';
    };
  };

  syncOpts = {
    enable = mkEnableOption "lieer synchronization service";

    frequency = mkOption {
      type = types.str;
      default = "*:0/5";
      description = ''
        How often to synchronize the account.
        </para><para>
        This value is passed to the systemd timer configuration as the
        onCalendar option. See
        <citerefentry>
          <refentrytitle>systemd.time</refentrytitle>
          <manvolnum>7</manvolnum>
        </citerefentry>
        for more information about the format.
      '';
    };
  };

  lieerOpts = {
    enable = mkEnableOption "lieer Gmail synchronization for notmuch";

    notmuchSetupWarning = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Warn if Notmuch is not also enabled for this account.
        </para><para>
        This can safely be disabled if <command>notmuch init</command>
        has been used to configure this account outside of Home
        Manager.
      '';
    };

    settings = mkOption {
      type = types.submodule {
        freeformType = settingsFormat.type;
        options = settingsOpts;
      };
      default = { };
      description = ''
        Settings which are applied to <filename>.gmailieer.json</filename>
        for the account.
        </para><para>
        See the <link xlink:href="https://github.com/gauteh/lieer/">lieer manual</link>
        for documentation of settings not explicitly covered by this module.
      '';
    };

    sync = syncOpts;
  };

  lieerModule = types.submodule {
    imports = [
      (mkRenamedOptionModule [ "lieer" "dropNonExistingLabels" ] [
        "lieer"
        "settings"
        "drop_non_existing_label"
      ])
      (mkRenamedOptionModule [ "lieer" "ignoreTagsRemote" ] [
        "lieer"
        "settings"
        "ignore_remote_labels"
      ])
      (mkRenamedOptionModule [ "lieer" "ignoreTagsLocal" ] [
        "lieer"
        "settings"
        "ignore_tags"
      ])
      (mkRenamedOptionModule [ "lieer" "timeout" ] [
        "lieer"
        "settings"
        "timeout"
      ])
      (mkRenamedOptionModule [ "lieer" "replaceSlashWithDot" ] [
        "lieer"
        "settings"
        "replace_slash_with_dot"
      ])
    ];

    options = {
      lieer = lieerOpts;

      warnings = mkOption {
        type = types.listOf types.str;
        default = [ ];
        internal = true;
        visible = false;
      };
    };
  };

  renamedOptions = account:
    let prefix = [ "accounts" "email" "accounts" account.name "lieer" ];
    in [
      (mkRenamedOptionModule (prefix ++ [ "dropNonExistingLabels" ])
        (prefix ++ [ "settings" "drop_non_existing_label" ]))
      (mkRenamedOptionModule (prefix ++ [ "ignoreTagsRemote" ])
        (prefix ++ [ "settings" "ignore_remote_labels" ]))
      (mkRenamedOptionModule (prefix ++ [ "ignoreTagsLocal" ])
        (prefix ++ [ "settings" "ignore_tags" ]))
      (mkRenamedOptionModule (prefix ++ [ "timeout" ])
        (prefix ++ [ "settings" "timeout" ]))
      (mkRenamedOptionModule (prefix ++ [ "replaceSlashWithDot" ])
        (prefix ++ [ "settings" "replace_slash_with_dot" ]))
    ];

in {
  meta.maintainers = [ maintainers.tadfisher ];

  options = {
    programs.lieer = {
      enable = mkEnableOption "lieer Gmail synchronization for notmuch";

      package = mkOption {
        type = types.package;
        default = pkgs.gmailieer;
        defaultText = "pkgs.gmailieer";
        description = ''
          lieer package to use.
        '';
      };
    };

    accounts.email.accounts =
      mkOption { type = with types; attrsOf lieerModule; };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf (missingNotmuchAccounts != [ ]) {
      warnings = [''
        lieer is enabled for the following email accounts, but notmuch is not:

            ${concatStringsSep "\n    " missingNotmuchAccounts}

        Notmuch can be enabled with:

            ${concatStringsSep "\n    " notmuchConfigHelp}

        If you have configured notmuch outside of Home Manager, you can suppress this
        warning with:

            programs.lieer.notmuchSetupWarning = false;
      ''];
    })

    {
      assertions = [{
        assertion = nonGmailAccounts == [ ];
        message = ''
          lieer is enabled for non-Gmail accounts:

              ${concatStringsSep "\n    " nonGmailAccounts}

          If these accounts are actually Gmail accounts, you can
          fix this error with:

              ${concatStringsSep "\n    " nonGmailConfigHelp}
        '';
      }];

      warnings = flatten (map (account: account.warnings) lieerAccounts);

      home.packages = [ cfg.package ];

      # Notmuch should ignore non-mail files created by lieer.
      programs.notmuch.new.ignore = [ "/.*[.](json|lock|bak)$/" ];

      home.file = listToAttrs (map configFile lieerAccounts);
    }
  ]);
}
