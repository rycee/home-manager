{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.xsession;

in {
  meta.maintainers = [ maintainers.rycee ];

  options = {
    xsession = {
      enable = mkEnableOption "X Session";

      scriptPath = mkOption {
        type = types.str;
        default = ".xsession";
        example = ".xsession-hm";
        description = ''
          Path, relative to <envar>HOME</envar>, where Home Manager
          should write the X session script.
        '';
      };

      profilePath = mkOption {
        type = types.str;
        default = ".xprofile";
        example = ".xprofile-hm";
        description = ''
          Path, relative to <envar>HOME</envar>, where Home Manager
          should write the X profile script.
        '';
      };

      windowManager.command = mkOption {
        type = types.str;
        example = literalExample ''
          let
            xmonad = pkgs.xmonad-with-packages.override {
              packages = self: [ self.xmonad-contrib self.taffybar ];
            };
          in
            "''${xmonad}/bin/xmonad";
        '';
        default = ''test -n "$1" && eval "$@"'';
        description = ''
          Window manager start command. The default value handles
          display-manager parameter from <code>de+wm.desktop</code>. If you use
          home-manager to config your window manager on NixOS, you have to
          handle extra actions from
          <code>services.xserver.displayManager.session.start</code> on NixOS by
          yourself, such as background setting, through
          <code>xsession.initExtra</code>.
        '';
      };

      preferStatusNotifierItems = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = ''
          Whether tray applets should prefer using the Status Notifier
          Items (SNI) protocol, commonly called App Indicators. Note,
          not all tray applets or status bars support SNI.
        '';
      };

      profileExtra = mkOption {
        type = types.lines;
        default = "";
        description = "Extra shell commands to run before session start.";
      };

      initExtra = mkOption {
        type = types.lines;
        default = "";
        description = "Extra shell commands to run during initialization.";
      };

      importedVariables = mkOption {
        type = types.listOf (types.strMatching "[a-zA-Z_][a-zA-Z0-9_]*");
        example = [ "GDK_PIXBUF_ICON_LOADER" ];
        visible = false;
        description = ''
          Environment variables to import into the user systemd
          session. The will be available for use by graphical
          services.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions =
      [ (hm.assertions.assertPlatform "xsession" pkgs platforms.linux) ];

    xsession.importedVariables = [
      "DBUS_SESSION_BUS_ADDRESS"
      "DISPLAY"
      "SSH_AUTH_SOCK"
      "XAUTHORITY"
      "XDG_DATA_DIRS"
      "XDG_RUNTIME_DIR"
      "XDG_SESSION_ID"
    ];

    systemd.user = {
      services = mkIf (config.home.keyboard != null) {
        setxkbmap = {
          Unit = {
            Description = "Set up keyboard in X";
            After = [ "graphical-session-pre.target" ];
            PartOf = [ "graphical-session.target" ];
          };

          Install = { WantedBy = [ "graphical-session.target" ]; };

          Service = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = with config.home.keyboard;
              let
                args = optional (layout != null) "-layout '${layout}'"
                  ++ optional (variant != null) "-variant '${variant}'"
                  ++ optional (model != null) "-model '${model}'"
                  ++ [ "-option ''" ] ++ map (v: "-option '${v}'") options;
              in "${pkgs.xorg.setxkbmap}/bin/setxkbmap ${toString args}";
          };
        };
      };

      targets = {
        # A basic graphical session target for Home Manager.
        hm-graphical-session = {
          Unit = {
            Description = "Home Manager X session";
            Requires = [ "graphical-session-pre.target" ];
            BindsTo = [ "graphical-session.target" "tray.target" ];
          };
        };

        tray = {
          Unit = {
            Description = "Home Manager System Tray";
            Requires = [ "graphical-session-pre.target" ];
          };
        };
      };
    };

    home.file.${cfg.profilePath}.text = ''
      . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"

      if [ -e "$HOME/.profile" ]; then
        . "$HOME/.profile"
      fi

      # If there are any running services from a previous session.
      # Need to run this in xprofile because the NixOS xsession
      # script starts up graphical-session.target.
      systemctl --user stop graphical-session.target graphical-session-pre.target

      ${optionalString (cfg.importedVariables != [ ])
      ("systemctl --user import-environment "
        + toString (unique cfg.importedVariables))}

      ${cfg.profileExtra}

      export HM_XPROFILE_SOURCED=1
    '';

    home.file.${cfg.scriptPath} = {
      executable = true;
      text = ''
        if [ -z "$HM_XPROFILE_SOURCED" ]; then
          . "${config.home.homeDirectory}/${cfg.profilePath}"
        fi
        unset HM_XPROFILE_SOURCED

        systemctl --user start hm-graphical-session.target

        ${cfg.initExtra}

        ${cfg.windowManager.command}

        systemctl --user stop graphical-session.target
        systemctl --user stop graphical-session-pre.target

        # Wait until the units actually stop.
        while [ -n "$(systemctl --user --no-legend --state=deactivating list-units)" ]; do
          sleep 0.5
        done
      '';
    };
  };
}
