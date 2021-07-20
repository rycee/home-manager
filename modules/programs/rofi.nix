{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.rofi;

  colorOption = description:
    mkOption {
      type = types.str;
      description = description;
    };

  rowColorSubmodule = types.submodule {
    options = {
      background = colorOption "Background color";
      foreground = colorOption "Foreground color";
      backgroundAlt = colorOption "Alternative background color";
      highlight = mkOption {
        type = types.submodule {
          options = {
            background = colorOption "Highlight background color";
            foreground = colorOption "Highlight foreground color";
          };
        };
        description = "Color settings for highlighted row.";
      };
    };
  };

  windowColorSubmodule = types.submodule {
    options = {
      background = colorOption "Window background color";
      border = colorOption "Window border color";
      separator = colorOption "Separator color";
    };
  };

  colorsSubmodule = types.submodule {
    options = {
      window = mkOption {
        default = null;
        type = windowColorSubmodule;
        description = "Window color settings.";
      };
      rows = mkOption {
        default = null;
        type = types.submodule {
          options = {
            normal = mkOption {
              default = null;
              type = types.nullOr rowColorSubmodule;
              description = "Normal row color settings.";
            };
            active = mkOption {
              default = null;
              type = types.nullOr rowColorSubmodule;
              description = "Active row color settings.";
            };
            urgent = mkOption {
              default = null;
              type = types.nullOr rowColorSubmodule;
              description = "Urgent row color settings.";
            };
          };
        };
        description = "Rows color settings.";
      };
    };
  };

  windowColorsToString = window:
    concatStringsSep ", " (with window; [ background border separator ]);

  rowColorsToString = row:
    concatStringsSep ", " (with row; [
      background
      foreground
      backgroundAlt
      highlight.background
      highlight.foreground
    ]);

  mkColorScheme = colors:
    if colors != null then
      with colors; {
        color-window =
          if (window != null) then (windowColorsToString window) else null;
        color-normal = if (rows != null && rows.normal != null) then
          (rowColorsToString rows.normal)
        else
          null;
        color-active = if (rows != null && rows.active != null) then
          (rowColorsToString rows.active)
        else
          null;
        color-urgent = if (rows != null && rows.active != null) then
          (rowColorsToString rows.urgent)
        else
          null;
      }
    else
      { };

  mkValueString = value:
    if isBool value then
      if value then "true" else "false"
    else if isInt value then
      toString value
    else if value._type or "" == "literal" then
      value.value
    else if isString value then
      ''"${value}"''
    else if isList value then
      "[ ${strings.concatStringsSep "," (map mkValueString value)} ]"
    else
      abort "Unhandled value type ${builtins.typeOf value}";

  mkKeyValue = { sep ? ": ", end ? ";" }:
    name: value:
    "${name}${sep}${mkValueString value}${end}";

  mkRasiSection = name: value:
    if isAttrs value then
      let
        toRasiKeyValue = generators.toKeyValue { mkKeyValue = mkKeyValue { }; };
        # Remove null values so the resulting config does not have empty lines
        configStr = toRasiKeyValue (filterAttrs (_: v: v != null) value);
      in ''
        ${name} {
        ${configStr}}
      ''
    else
      mkKeyValue {
        sep = " ";
        end = "";
      } name value;

  toRasi = attrs: concatStringsSep "\n" (mapAttrsToList mkRasiSection attrs);

  locationsMap = {
    center = 0;
    top-left = 1;
    top = 2;
    top-right = 3;
    right = 4;
    bottom-right = 5;
    bottom = 6;
    bottom-left = 7;
    left = 8;
  };

  primitive = with types; (oneOf [ str int bool rasiLiteral ]);

  # Either a `section { foo: "bar"; }` or a `@import/@theme "some-text"`
  configType = with types;
    (either (attrsOf (either primitive (listOf primitive))) str);

  rasiLiteral = types.submodule {
    options = {
      _type = mkOption {
        type = types.enum [ "literal" ];
        internal = true;
      };

      value = mkOption {
        type = types.str;
        internal = true;
      };
    };
  } // {
    description = "Rasi literal string";
  };

  themeType = with types; attrsOf configType;

  themeName = if (cfg.theme == null) then
    null
  else if (isString cfg.theme) then
    cfg.theme
  else if (isAttrs cfg.theme) then
    "custom"
  else
    removeSuffix ".rasi" (baseNameOf cfg.theme);

  themePath = if (isString cfg.theme) then
    null
  else if (isAttrs cfg.theme) then
    "custom"
  else
    cfg.theme;

in {
  options.programs.rofi = {
    enable = mkEnableOption
      "Rofi: A window switcher, application launcher and dmenu replacement";

    package = mkOption {
      default = pkgs.rofi;
      type = types.package;
      description = ''
        Package providing the <command>rofi</command> binary.
      '';
      example = literalExample ''
        pkgs.rofi.override { plugins = [ pkgs.rofi-emoji ]; };
      '';
    };

    plugins = mkOption {
      default = [ ];
      type = types.listOf types.package;
      description = ''
        List of rofi plugins to be installed.
      '';
      example = literalExample "[ pkgs.rofi-calc ]";
    };

    width = mkOption {
      default = null;
      type = types.nullOr types.int;
      description = "Window width";
      example = 100;
    };

    lines = mkOption {
      default = null;
      type = types.nullOr types.int;
      description = "Number of lines";
      example = 10;
    };

    borderWidth = mkOption {
      default = null;
      type = types.nullOr types.int;
      description = "Border width";
      example = 1;
    };

    rowHeight = mkOption {
      default = null;
      type = types.nullOr types.int;
      description = "Row height (in chars)";
      example = 1;
    };

    padding = mkOption {
      default = null;
      type = types.nullOr types.int;
      description = "Padding";
      example = 400;
    };

    font = mkOption {
      default = null;
      type = types.nullOr types.str;
      example = "Droid Sans Mono 14";
      description = "Font to use.";
    };

    scrollbar = mkOption {
      default = null;
      type = types.nullOr types.bool;
      description = "Whether to show a scrollbar.";
    };

    terminal = mkOption {
      default = null;
      type = types.nullOr types.str;
      description = ''
        Path to the terminal which will be used to run console applications
      '';
      example = "\${pkgs.gnome.gnome_terminal}/bin/gnome-terminal";
    };

    separator = mkOption {
      default = null;
      type = types.nullOr (types.enum [ "none" "dash" "solid" ]);
      description = "Separator style";
      example = "solid";
    };

    cycle = mkOption {
      default = null;
      type = types.nullOr types.bool;
      description = "Whether to cycle through the results list.";
    };

    fullscreen = mkOption {
      default = null;
      type = types.nullOr types.bool;
      description = "Whether to run rofi fullscreen.";
    };

    location = mkOption {
      default = "center";
      type = types.enum (attrNames locationsMap);
      description = "The location rofi appears on the screen.";
    };

    xoffset = mkOption {
      default = 0;
      type = types.int;
      description = ''
        Offset in the x-axis in pixels relative to the chosen location.
      '';
    };

    yoffset = mkOption {
      default = 0;
      type = types.int;
      description = ''
        Offset in the y-axis in pixels relative to the chosen location.
      '';
    };

    colors = mkOption {
      default = null;
      type = types.nullOr colorsSubmodule;
      description = ''
        Color scheme settings. Colors can be specified in CSS color
        formats. This option may become deprecated in the future and
        therefore the <varname>programs.rofi.theme</varname> option
        should be used whenever possible.
      '';
      example = literalExample ''
        colors = {
          window = {
            background = "argb:583a4c54";
            border = "argb:582a373e";
            separator = "#c3c6c8";
          };

          rows = {
            normal = {
              background = "argb:58455a64";
              foreground = "#fafbfc";
              backgroundAlt = "argb:58455a64";
              highlight = {
                background = "#00bcd4";
                foreground = "#fafbfc";
              };
            };
          };
        };
      '';
    };

    theme = mkOption {
      default = null;
      type = with types; nullOr (oneOf [ str path themeType ]);
      example = literalExample ''
        let
          inherit (config.lib.formats.rasi) mkLiteral;
        in {
          "*" = {
            background-color = mkLiteral "#000000";
            foreground-color = mkLiteral "rgba ( 250, 251, 252, 100 % )";
            border-color = mkLiteral "#FFFFFF";
            width = 512;
          };

          "#inputbar" = {
            children = map mkLiteral [ "prompt" "entry" ];
          };

          "#textbox-prompt-colon" = {
            expand = false;
            str = ":";
            margin = mkLiteral "0px 0.3em 0em 0em";
            text-color = mkLiteral "@foreground-color";
          };
        }
      '';
      description = ''
        Name of theme or path to theme file in rasi format or attribute set with
        theme configuration. Available named themes can be viewed using the
        <command>rofi-theme-selector</command> tool.
      '';
    };

    configPath = mkOption {
      default = "${config.xdg.configHome}/rofi/config.rasi";
      defaultText = "$XDG_CONFIG_HOME/rofi/config.rasi";
      type = types.str;
      description = "Path where to put generated configuration file.";
    };

    extraConfig = mkOption {
      default = { };
      example = literalExample ''
        {
          modi = "drun,emoji,ssh";
          kb-primary-paste = "Control+V,Shift+Insert";
          kb-secondary-paste = "Control+v,Insert";
        }
      '';
      type = configType;
      description = "Additional configuration to add.";
    };

  };

  config = mkIf cfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "programs.rofi" pkgs platforms.linux)
      {
        assertion = cfg.theme == null || cfg.colors == null;
        message = ''
          Cannot use the rofi options 'theme' and 'colors' simultaneously.
        '';
      }
      (hm.assertions.assertPlatform "programs.rofi" pkgs platforms.linux)
      {
        assertion = (!builtins.hasAttr "override" cfg.package)
          || (cfg.plugins == [ ])
          || (cfg.package.override.__functionArgs ? plugins);
        message = ''
          Cannot use provided package with plugins.
        '';
      }
    ];

    lib.formats.rasi.mkLiteral = value: {
      _type = "literal";
      inherit value;
    };

    home.packages = let
      rofiWithPlugins = cfg.package.override
        (old: rec { plugins = (old.plugins or [ ]) ++ cfg.plugins; });
      rofiPackage = if builtins.hasAttr "override" cfg.package
      && cfg.package.override.__functionArgs ? plugins then
        rofiWithPlugins
      else
        cfg.package;
    in [ rofiPackage ];

    home.file."${cfg.configPath}".text = toRasi {
      configuration = ({
        width = cfg.width;
        lines = cfg.lines;
        font = cfg.font;
        bw = cfg.borderWidth;
        eh = cfg.rowHeight;
        padding = cfg.padding;
        separator-style = cfg.separator;
        hide-scrollbar =
          if (cfg.scrollbar != null) then (!cfg.scrollbar) else null;
        terminal = cfg.terminal;
        cycle = cfg.cycle;
        fullscreen = cfg.fullscreen;
        location = (getAttr cfg.location locationsMap);
        xoffset = cfg.xoffset;
        yoffset = cfg.yoffset;
        theme = themeName;
      } // (mkColorScheme cfg.colors) // cfg.extraConfig);
    };

    xdg.dataFile = mkIf (themePath != null) (if themePath == "custom" then {
      "rofi/themes/${themeName}.rasi".text = toRasi cfg.theme;
    } else {
      "rofi/themes/${themeName}.rasi".source = themePath;
    });
  };

  meta.maintainers = with maintainers; [ thiagokokada ];
}
