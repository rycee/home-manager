{ config, lib, pkgs, ... }:

let
  cfg = config.programs.waybar;

  # Used when generating warnings
  modulesPath = "programs.waybar.settings.[].modules";

  # Taken from <https://github.com/Alexays/Waybar/blob/adaf84304865e143e4e83984aaea6f6a7c9d4d96/src/factory.cpp>
  defaultModuleNames = [
    "sway/mode"
    "sway/workspaces"
    "sway/window"
    "wlr/taskbar"
    "idle_inhibitor"
    "memory"
    "cpu"
    "clock"
    "disk"
    "tray"
    "network"
    "backlight"
    "pulseaudio"
    "mpd"
    "temperature"
    "bluetooth"
    "battery"
  ];

  isValidCustomModuleName = x:
    lib.elem x defaultModuleNames
    || (lib.hasPrefix "custom/" x && lib.stringLength x > 7);

  margins = let
    mkMargin = name: {
      "margin-${name}" = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        example = 10;
        description = "Margins value without unit.";
      };
    };
    margins = map mkMargin [ "top" "left" "bottom" "right" ];
  in lib.foldl' lib.mergeAttrs { } margins;

  waybarBarConfig = with lib.types;
    submodule {
      options = {
        layer = lib.mkOption {
          type = nullOr (enum [ "top" "bottom" ]);
          default = null;
          description = ''
            Decide if the bar is displayed in front (<code>"top"</code>)
            of the windows or behind (<code>"bottom"</code>).
          '';
          example = "top";
        };

        output = lib.mkOption {
          type = nullOr (either str (listOf str));
          default = null;
          example = literalExample ''
            [ "DP-1" "!DP-2" "!DP-3" ]
          '';
          description = ''
            Specifies on which screen this bar will be displayed.
            Exclamation mark(!) can be used to exclude specific output.
          '';
        };

        position = lib.mkOption {
          type = nullOr (enum [ "top" "bottom" "left" "right" ]);
          default = null;
          example = "right";
          description = "Bar position relative to the output.";
        };

        height = lib.mkOption {
          type = nullOr ints.unsigned;
          default = null;
          example = 5;
          description =
            "Height to be used by the bar if possible. Leave blank for a dynamic value.";
        };

        width = lib.mkOption {
          type = nullOr ints.unsigned;
          default = null;
          example = 5;
          description =
            "Width to be used by the bar if possible. Leave blank for a dynamic value.";
        };

        modules-left = lib.mkOption {
          type = nullOr (listOf str);
          default = null;
          description = "Modules that will be displayed on the left.";
          example = literalExample ''
            [ "sway/workspaces" "sway/mode" "wlr/taskbar" ]
          '';
        };

        modules-center = lib.mkOption {
          type = nullOr (listOf str);
          default = null;
          description = "Modules that will be displayed in the center.";
          example = literalExample ''
            [ "sway/window" ]
          '';
        };

        modules-right = lib.mkOption {
          type = nullOr (listOf str);
          default = null;
          description = "Modules that will be displayed on the right.";
          example = literalExample ''
            [ "mpd" "custom/mymodule#with-css-id" "temperature" ]
          '';
        };

        modules = lib.mkOption {
          type = attrsOf unspecified;
          default = { };
          description = "Modules configuration.";
          example = literalExample ''
            {
              "sway/window" = {
                max-length = 50;
              };
              "clock" = {
                format-alt = "{:%a, %d. %b  %H:%M}";
              };
              "custom/hello-from" = {
                format = "hello {}";
                max-length = 40;
                interval = 10;
                # If you have multiple scripts defined inline, you may be interested in
                # using symlinkJoin to merge all scripts in one derivation
                # to have them all under one directory structure in the nix store
                exec = "''${pkgs.writers.writeBashBin "hello-from-waybar" '''
                  echo "from within waybar"
                '''}/bin/hello-from-waybar";
              };
            }
          '';
        };

        margin = lib.mkOption {
          type = nullOr str;
          default = null;
          description = "Margins value using the CSS format without units.";
          example = "20 5";
        };

        inherit (margins) margin-top margin-left margin-bottom margin-right;

        name = lib.mkOption {
          type = nullOr str;
          default = null;
          description =
            "Optional name added as a CSS class, for styling multiple waybars.";
          example = "waybar-1";
        };

        gtk-layer-shell = lib.mkOption {
          type = nullOr bool;
          default = null;
          example = false;
          description =
            "Option to disable the use of gtk-layer-shell for popups.";
        };
      };
    };
in {
  meta.maintainers = [ lib.hm.maintainers.berbiche ];

  options.programs.waybar = with lib.types; {
    enable = lib.mkEnableOption "Waybar";

    package = lib.mkOption {
      type = nullOr package;
      default = pkgs.waybar;
      defaultText = literalExample "${pkgs.waybar}";
      description = ''
        Waybar package to use. Set to <code>null</code> to use the default module.
      '';
    };

    settings = lib.mkOption {
      type = listOf waybarBarConfig;
      default = [ ];
      description = ''
        Configuration for Waybar, see <link
          xlink:href="https://github.com/Alexays/Waybar/wiki/Configuration"/>
        for supported values.
      '';
      example = literalExample ''
        [
          {
            layer = "top";
            position = "top";
            height = 30;
            # Specify outputs to restrict to certain outputs, otherwise show on all outputs
            output = [
              "eDP-1"
              "DP-1"
            ];
            modules-left = [ "sway/workspaces" "sway/mode" "wlr/taskbar" ];
            modules-center = [ "sway/window" "custom/hello-from-waybar" ];
            modules-right = [ "mpd" "custom/mymodule#with-css-id" "temperature" ];
            modules = {
              "sway/workspaces" = {
                disable-scroll = true;
                all-outputs = true;
              };
              "custom/hello-from-waybar" = {
                format = "hello {}";
                max-length = 40;
                interval = "once";
                # You may be interested in using symlinkJoin to merge all scripts in one derivation
                # to have them all under one directory structure in the nix store
                exec = "''${pkgs.writers.writeBashBin "hello-from-waybar" '''
                  echo "from within waybar"
                '''}/bin/hello-from-waybar";
              };
            };
          }
        ]
      '';
    };

    systemd.enable = lib.mkEnableOption "Waybar Systemd integration";

    style = lib.mkOption {
      type = nullOr str;
      default = null;
      description = ''
        CSS style of the bar.
        See <link
          xlink:href="https://github.com/Alexays/Waybar/wiki/Configuration"/> for the documentation.
      '';
      example = ''
        * {
          border: none;
          border-radius: 0;
          font-family: Source Code Pro;
        }
        window#waybar {
          background: #16191C;
          color: #AAB2BF;
        }
        #workspaces button {
          padding: 0 5px;
        }
      '';
    };
  };

  config = let
    # Inspired by https://github.com/NixOS/nixpkgs/pull/89781
    writePrettyJSON = name: x:
      pkgs.runCommandNoCCLocal name { } ''
        ${pkgs.jq}/bin/jq . > $out <<<${lib.escapeShellArg (builtins.toJSON x)}
      '';

    configSource = let
      # Removes nulls because Waybar ignores them for most values
      removeNulls = lib.filterAttrs (_: v: v != null);

      # Makes the actual valid configuration Waybar accepts
      # (strips our custom settings before converting to JSON)
      makeConfiguration = configuration:
        let
          # The "modules" option is not valid in the JSON
          # as its descendants have to live at the top-level
          settingsWithoutModules =
            lib.filterAttrs (n: _: n != "modules") configuration;
          settingsModules = lib.optionalAttrs (configuration.modules != { })
            configuration.modules;
        in removeNulls (settingsWithoutModules // settingsModules);
      # The clean list of configurations
      finalConfiguration = map makeConfiguration cfg.settings;
    in writePrettyJSON "waybar-config.json" finalConfiguration;

    warnings = let
      mkUnreferencedModuleWarning = name:
        "The module '${name}' defined in '${modulesPath}' is not referenced "
        + "in either `modules-left`, `modules-center` or `modules-right` of Waybar's options";
      mkUndefinedModuleWarning = settings: name:
        let
          # Locations where the module is undefined (a combination modules-{left,center,right})
          locations = lib.flip lib.filter [ "left" "center" "right" ]
            (x: lib.elem name settings."modules-${x}");
          mkPath = loc: "'${modulesPath}-${loc}'";
          # The modules-{left,center,right} configuration that includes
          # an undefined module
          path = lib.concatMapStringsSep " and " mkPath locations;
        in "The module '${name}' defined in ${path} is neither "
        + "a default module or a custom module declared in '${modulesPath}'";
      mkInvalidModuleNameWarning = name:
        "The custom module '${name}' defined in '${modulesPath}' is not a valid "
        + "module name. A custom module's name must start with 'custom/' "
        + "like 'custom/mymodule' for instance";

      # Find all modules in `modules-{left,center,right}` and `modules` not declared/referenced.
      # `cfg.settings` is a list of Waybar configurations
      # and we need to preserve the index for appropriate warnings
      allFaultyModules = lib.flip map cfg.settings (settings:
        let
          allModules = lib.unique
            (lib.concatMap (x: lib.attrByPath [ "modules-${x}" ] [ ] settings) [
              "left"
              "center"
              "right"
            ]);
          declaredModules = lib.attrNames settings.modules;
          # Modules declared in `modules` but not referenced in `modules-{left,center,right}`
          unreferencedModules = lib.subtractLists allModules declaredModules;
          # Modules listed in modules-{left,center,right} that are not default modules
          nonDefaultModules = lib.subtractLists defaultModuleNames allModules;
          # Modules referenced in `modules-{left,center,right}` but not declared in `modules`
          undefinedModules =
            lib.subtractLists declaredModules nonDefaultModules;
          # Check for invalid module names
          invalidModuleNames = lib.filter (m: !isValidCustomModuleName m)
            (lib.attrNames settings.modules);
        in {
          # The Waybar bar configuration (since config.settings is a list)
          settings = settings;
          undef = undefinedModules;
          unref = unreferencedModules;
          invalidName = invalidModuleNames;
        });

      allWarnings = lib.flip lib.concatMap allFaultyModules
        ({ settings, undef, unref, invalidName }:
          let
            unreferenced = map mkUnreferencedModuleWarning unref;
            undefined = map (mkUndefinedModuleWarning settings) undef;
            invalid = map mkInvalidModuleNameWarning invalidName;
          in undefined ++ unreferenced ++ invalid);
    in allWarnings;

  in lib.mkIf cfg.enable (lib.mkMerge [
    { home.packages = [ cfg.package ]; }
    (lib.mkIf (cfg.settings != [ ]) {
      # Generate warnings about defined but unreferenced modules
      inherit warnings;

      xdg.configFile."waybar/config".source = configSource;
    })
    (lib.mkIf (cfg.style != null) {
      xdg.configFile."waybar/style.css".text = cfg.style;
    })
    (lib.mkIf cfg.systemd.enable {
      systemd.user.services.waybar = {
        Unit = {
          Description =
            "Highly customizable Wayland bar for Sway and Wlroots based compositors.";
          Documentation = "https://github.com/Alexays/Waybar/wiki";
          PartOf = [ "graphical-session.target" ];
          Requisite = [ "dbus.service" ];
          After = [ "dbus.service" ];
        };

        Service = {
          Type = "dbus";
          BusName = "fr.arouillard.waybar";
          ExecStart = "${cfg.package}/bin/waybar";
          Restart = "always";
          RestartSec = "1sec";
        };

        Install = { WantedBy = [ "graphical-session.target" ]; };
      };
    })
  ]);
}
