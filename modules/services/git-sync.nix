{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.git-sync;
  mkUnit = repo: {
    Unit = { Description = "Git Sync ${repo.name}"; };

    Install = { WantedBy = [ "default.target" ]; };

    Service = {
      Environment = [
        "GIT_SYNC_DIRECTORY=${repo.path}"
        "GIT_SYNC_COMMAND=${cfg.package}/bin/git-sync"
        "GIT_SYNC_REPOSITORY=${repo.uri}"
        "GIT_SYNC_INTERVAL=${toString repo.interval}"
      ];
      ExecStart = "${cfg.package}/bin/git-sync-on-inotify";
      Restart = "on-abort";
    };
  };
  services = listToAttrs (map (repo: {
    name = "git-sync-${repo.name}";
    value = mkUnit repo;
  }) cfg.repositories);

in {
  meta.maintainers = [ maintainers.imalison ];

  options = {
    services.git-sync = {
      enable = mkEnableOption "Enable git-sync services";

      package = mkOption {
        type = types.package;
        default = pkgs.git-sync;
        defaultText = literalExample "pkgs.git-sync";
        description = ''
          Package containing the <command>git-sync</command> program.
        '';
      };

      repositories = mkOption {
        description = "A list of objects describing repositories that should be synced";
        type = with types;
          listOf (submodule {
            options = {
              name = mkOption {
                type = types.str;
                description = "The name that should be given to this unit.";
              };

              path = mkOption {
                type = types.path;
                description = "The path at which to sync the repository";
              };

              uri = mkOption {
                type = types.str;
                description = ''
                  The uri of the remote to be synchronized. This is only used
                  in the event that the directory does not already exist.'';
              };

              interval = mkOption {
                type = types.int;
                default = 500;
                description = ''
                  The interval at which the synchronization will be triggered
                  even without filesystem changes.
                '';
              };
            };
          });
      };
    };
  };

  config = mkIf cfg.enable { systemd.user.services = services; };
}
