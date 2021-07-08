{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.lieer;

  syncAccounts = filter (a: a.lieer.enable && a.lieer.sync.enable)
    (attrValues config.accounts.email.accounts);

  escapeUnitName = name:
    let
      good = upperChars ++ lowerChars ++ stringToCharacters "0123456789-_";
      subst = c: if any (x: x == c) good then c else "-";
    in stringAsChars subst name;

  serviceUnit = account: {
    name = escapeUnitName "lieer-${account.name}";
    value = {
      Unit = {
        Description = "lieer Gmail synchronization for ${account.name}";
        ConditionPathExists = "${account.maildir.absPath}/.gmailieer.json";
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.gmailieer}/bin/gmi sync";
        WorkingDirectory = account.maildir.absPath;
        Environment =
          "NOTMUCH_CONFIG=${config.xdg.configHome}/notmuch/notmuchrc";
      };
    };
  };

  timerUnit = account: {
    name = escapeUnitName "lieer-${account.name}";
    value = {
      Unit = {
        Description = "lieer Gmail synchronization for ${account.name}";
      };

      Timer = {
        OnCalendar = account.lieer.sync.frequency;
        RandomizedDelaySec = 30;
      };

      Install = { WantedBy = [ "timers.target" ]; };
    };
  };

in {
  meta.maintainers = [ maintainers.tadfisher ];

  options.services.lieer.enable =
    mkEnableOption "lieer Gmail synchronization service";

  config = mkIf cfg.enable {
    programs.lieer.enable = true;
    systemd.user.services = listToAttrs (map serviceUnit syncAccounts);
    systemd.user.timers = listToAttrs (map timerUnit syncAccounts);
  };
}
