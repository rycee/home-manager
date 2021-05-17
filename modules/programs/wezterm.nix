{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.programs.wezterm;

  genericType = with types; oneOf [ str bool int float ];

  boolToStr = boolVal: if boolVal then "true" else "false";

  toBindingMods = binding:
    optionalString (binding.modifiers != [ ])
    ''mods="${concatStringsSep "|" binding.modifiers}",'';

  toBindingAction = binding:
    optionalString (binding.action != "") "action = ${binding.action},";

  toWeztermBindings = bindings: isKeyBinding:
    let
      name = if isKeyBinding then "keys" else "mouse_bindings";
      midBinding = binding:
        if isKeyBinding then
          ''key="${binding.key}",''
        else ''
          event={${binding.event}={streak=${toString binding.count},
          button="${binding.button}"}},'';
      mapBinding = binding: ''
        {${toBindingMods binding}${midBinding binding}
        ${toBindingAction binding}},'';
    in "${name}={${toString (map mapBinding bindings)}},";

  toWeztermTabColors = tab: ''
    {bg_color="${tab.background}",fg_color="${tab.foreground}",
    intensity="${tab.intensity}",italic=${boolToStr tab.italic},
    underline="${tab.underline}",strikethrough=${boolToStr tab.strikethrough}}'';

  toWeztermBase16Colors = colors:
    let
      values = with colors; [ black red green yellow blue magenta cyan white ];
    in ''{"${(concatStringsSep ''","'' values)}"}'';

  toWeztermColorscheme = colors: ''
    {foreground="${colors.foreground}",background="${colors.background}",
    cursor_bg="${colors.cursor.background}",cursor_fg="${colors.cursor.foreground}",
    cursor_border="${colors.cursor.border}",selection_bg="${colors.selection.background}",
    selection_fg="${colors.selection.foreground}",scrollbar_thumb="${colors.scrollbarThumb}",
    split="${colors.split}",ansi=${toWeztermBase16Colors colors.ansi},
    brights=${toWeztermBase16Colors colors.bright},tab_bar={
    background="${colors.tabBar.background}",
    active_tab=${toWeztermTabColors colors.tabBar.activeTab},
    inactive_tab=${toWeztermTabColors colors.tabBar.inactiveTab},
    inactive_tab_hover=${toWeztermTabColors colors.tabBar.inactiveTabHover},
    }},'';

  toWeztermColors = colors: "colors = ${toWeztermColorscheme colors}";

  toWeztermSettings = generators.toKeyValue {
    mkKeyValue = key: value:
      let
        value' = if isString value then
          ''"${value}"''
        else if isBool value then
          (boolToStr value)
        else
          toString value;
      in "${key} = ${value'},";
  };

  mkBindingMods = with types;
    mkOption {
      type = listOf
        (enum [ "CTRL" "SUPER" "CMD" "WIN" "SHIFT" "ALT" "OPT" "LEADER" ]);
      default = [ ];
      description = ''
        The binding modifier key(s).
      '';
      example = literalExample ''
        [ "CTRL" ]
      '';
    };

  mkBindingAction = with types;
    example:
    mkOption {
      type = str;
      default = "";
      description = ''
        The code called when the binding is executed.
        You can set an action to <code>null</code> to disable the default assignment.
      '';
      example = example;
    };

  weztermKeybindType = with types;
    submodule {
      options = {
        modifiers = mkBindingMods;

        key = mkOption {
          type = str;
          description = ''
            The keybinding main key.
          '';
          example = "l";
        };

        action = mkBindingAction
          (literalExample "wezterm.action {ActivateTabRelative = 1}");
      };
    };

  weztermMousebindType = with types;
    submodule {
      options = {
        modifiers = mkBindingMods;

        button = mkOption {
          type = enum [ "Left" "Right" "Middle" ];
          default = "Left";
          description = ''
            The mouse binding button.
          '';
          example = "Left";
        };

        event = mkOption {
          type = enum [ "Up" "Down" "Drag" ];
          default = "Left";
          description = ''
            The mouse binding event.
          '';
          example = "Left";
        };

        count = mkOption {
          type = int;
          default = 1;
          description = ''
            The event count to trigger action.
          '';
          example = 1;
        };

        action = mkBindingAction (literalExample ''"OpenLinkAtMouseCursor"'');
      };
    };

  mkColor = default: desc:
    mkOption {
      type = types.str;
      default = default;
      description = desc;
      example = default;
    };

  weztermColorschemeCursorType = with types;
    submodule {
      options = {
        foreground = mkColor "#000000" ''
          Overrides the text color when the current cell is occupied by the cursor.
        '';
        background = mkColor "#52AD70" ''
          Overrides the cell background color when the current cell is occupied
          by the cursor and the cursor style is set to <literal>Block</literal>.
        '';
        border = mkColor "#52AD70" ''
          Specifies the border color of the cursor when the cursor style is
          set to <literal>Block</literal>.
        '';
      };
    };

  weztermColorschemeSelectionType = with types;
    submodule {
      options = {
        foreground = mkColor "#000000" "The foreground color of selected text.";
        background = mkColor "#FFFACD" "The background color of selected text.";
      };
    };

  weztermColorschemeTabBarTabType = with types;
    tabType:
    submodule {
      options = {
        background = let
          default = if tabType == "active" then
            "#2B2042"
          else if tabType == "inactive" then
            "#1B1032"
          else
            "#3B3052";
        in mkColor default "The color of the background area for the tab.";

        foreground = let
          default = if tabType == "active" then
            "#C0C0C0"
          else if tabType == "inactive" then
            "#808080"
          else
            "#909090";
        in mkColor default "The color of the text for the tab.";

        intensity = mkOption {
          type = enum [ "Half" "Normal" "Bold" ];
          default = "Normal";
          description = ''
            Specify whether you want <literal>Half</literal>, <literal>Normal</literal>
            or <literal>Bold</literal> intensity for the label shown for this tab.
          '';
          example = literalExample "Normal";
        };

        underline = mkOption {
          type = enum [ "None" "Single" "Double" ];
          default = "None";
          description = ''
            Specify whether you want <literal>None</literal>, <literal>Single</literal>
            or <literal>Double</literal> underline for label shown for this tab.
          '';
          example = literalExample "None";
        };

        italic = mkOption {
          type = bool;
          default = tabType == "inactive_hover";
          description = ''
            Specify whether you want the text to be italic (<literal>true</literal>)
            or not (<literal>false</literal>) for this tab.
          '';
          example = literalExample "true";
        };

        strikethrough = mkOption {
          type = bool;
          default = false;
          description = ''
            Specify whether you want the text to be rendered with
            strikethrough (<literal>true</literal>) or not (<literal>false</literal>) for this tab.
          '';
          example = literalExample "false";
        };
      };
    };

  weztermColorschemeTabBarType = with types;
    submodule {
      options = {
        background = mkColor "#0B0022"
          "The color of the strip that goes along the top of the window.";

        activeTab = mkOption {
          type = weztermColorschemeTabBarTabType "active";
          default = { };
          description = ''
            Color the tab that has focus in the window.
          '';
          example = literalExample ''
            {
              background = "#2B2042";
              foreground = "#C0C0C0";
              intensity = "Bold";
              italic = false;
              strikethrough = false;
              underline = "None";
            }
          '';
        };

        inactiveTab = mkOption {
          type = weztermColorschemeTabBarTabType "inactive";
          default = { };
          description = ''
            Color the tabs that do not have focus.
          '';
          example = literalExample ''
            {
              background = "#1B1032";
              foreground = "#808080";
              intensity = "Normal";
              italic = false;
              strikethrough = false;
              underline = "None";
            }
          '';
        };

        inactiveTabHover = mkOption {
          type = weztermColorschemeTabBarTabType "inactive_hover";
          default = { };
          description = ''
            Color when the mouse pointer hovers over an inactive tab.
          '';
          example = literalExample ''
            {
              background = "#3B3052";
              foreground = "#909090";
              intensity = "Normal";
              italic = true;
              strikethrough = false;
              underline = "None";
            }
          '';
        };
      };
    };

  mkBase16Color = with types;
    colorName: isAnsi: defaultAnsi: defaultBright:
    let
      name = if isAnsi then "ansi" else "bright";
      default = if isAnsi then defaultAnsi else defaultBright;
    in mkColor default "The ${name} ${colorName} color.";

  weztermColorschemeBase16Type = with types;
    isAnsi:
    submodule {
      options = {
        black = mkBase16Color "black" isAnsi "#000000" "#808080";
        red = mkBase16Color "red" isAnsi "#800000" "#FF0000";
        green = mkBase16Color "green" isAnsi "#008000" "#00FF00";
        yellow = mkBase16Color "yellow" isAnsi "#808000" "#FFFF00";
        blue = mkBase16Color "blue" isAnsi "#000080" "#0000FF";
        magenta = mkBase16Color "magenta" isAnsi "#800080" "#FF00FF";
        cyan = mkBase16Color "cyan" isAnsi "#008080" "#00FFFF";
        white = mkBase16Color "white" isAnsi "#C0C0C0" "#FFFFFF";
      };
    };

  weztermColorschemeType = with types;
    submodule {
      options = {
        foreground = mkColor "#C0C0C0" "The default text color.";
        background = mkColor "#000000" "The default background color.";

        scrollbarThumb = mkColor "#222222" ''
          The color of the scrollbar "thumb"; the portion that represents
          the current viewport.
        '';
        split = mkColor "#444444" "The color of the split lines between panes";

        cursor = mkOption {
          type = weztermColorschemeCursorType;
          default = { };
          description = ''
            The color of the cursor.
          '';
          example = literalExample ''
            {
              foreground = "#52ad70";
              background = "#000000";
              border = "#52AD70";
            }
          '';
        };

        selection = mkOption {
          type = weztermColorschemeSelectionType;
          default = { };
          description = ''
            The color of the selection.
          '';
          example = literalExample ''
            {
              foreground = "#FFFACD";
              background = "#000000";
            }
          '';
        };

        tabBar = mkOption {
          type = weztermColorschemeTabBarType;
          default = { };
          description = ''
            The colors of the tab bar.
          '';
          example = literalExample ''
            {
              background = "#0b0022";
            }
          '';
        };

        ansi = mkOption {
          type = weztermColorschemeBase16Type true;
          default = { };
          description = ''
            The main ANSI colors.
          '';
          example = literalExample ''
            {
              black = "#000000";
              red = "#800000";
              green = "#008000";
              yellow = "#808000";
              blue = "#000080";
              magenta = "#800080";
              cyan = "#008080";
              white = "#C0C0C0";
            }
          '';
        };

        bright = mkOption {
          type = weztermColorschemeBase16Type false;
          default = { };
          description = ''
            The main bright colors.
          '';
          example = literalExample ''
            {
              black = "#808080";
              red = "#FF0000";
              green = "#00FF00";
              yellow = "#FFFF00";
              blue = "#0000FF";
              magenta = "#FF00FF";
              cyan = "#00FFFF";
              white = "#FFFFFF";
            }
          '';
        };
      };
    };

in {
  meta.maintainers = with lib.hm.maintainers; [ l3af ];

  options.programs.wezterm = with types; {
    enable = mkEnableOption "Wezterm terminal emulator";

    package = mkOption {
      type = package;
      default = pkgs.wezterm;
      defaultText = "pkgs.wezterm";
      description = ''
        The Wezterm package to use.
      '';
    };

    keybindings = mkOption {
      type = listOf weztermKeybindType;
      default = [ ];
      description = ''
        Mapping of keybindings to actions.
      '';
      example = literalExample ''
        [{
            modifiers = [ "SHIFT" "CTRL" ];
            key = "l";
            action = "wezterm.action {ActivateTabRelative = 1}";
        }]
      '';
    };

    mousebindings = mkOption {
      type = listOf weztermMousebindType;
      default = [ ];
      description = ''
        Mapping of mouse bindings to actions.
      '';
      example = literalExample ''
        [{
            button = "Left";
            event = "Up";
            count = 1;
            modifiers = [ "CTRL" ];
            action = "\"OpenLinkAtMouseCursor\"";
        }]
      '';
    };

    settings = mkOption {
      type = attrsOf genericType;
      default = { };
      description = ''
        Set any simple value.
      '';
      example = literalExample ''
        {
          enable_wayland = true;
          font_size = 10.0;
        }
      '';
    };

    colors = mkOption {
      type = weztermColorschemeType;
      default = { };
      description = ''
        Set terminal colors.
      '';
      example = literalExample ''
        {
          foreground = "#C0C0C0";
          background = "#000000";
        }
      '';
    };

    extraSettings = mkOption {
      default = "";
      type = lines;
      description = ''
        Additional configuration to add outside of the return statement.
      '';
    };

    extraReturnSettings = mkOption {
      default = "";
      type = lines;
      description = ''
        Additional configuration to add to the return statement.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package pkgs.luaformatter ];

    xdg.configFile.weztermHMSettings = {
      target = "wezterm/wezterm.lua";
      source = let
        code = ''
          -- Generated by Home Manager.

          local wezterm = require("wezterm")
          ${cfg.extraSettings}
          return {${
            concatStringsSep "\n" [
              (optionalString (cfg.keybindings != [ ])
                (toWeztermBindings cfg.keybindings true))
              (optionalString (cfg.mousebindings != [ ])
                (toWeztermBindings cfg.mousebindings false))
              (optionalString (cfg.settings != { })
                (toWeztermSettings cfg.settings))
              (toWeztermColors cfg.colors)
              cfg.extraReturnSettings
            ]}}'';
      in pkgs.runCommand "format" { } ''
        ${pkgs.luaformatter}/bin/lua-format --indent-width=2 --no-use-tab <<EOF >$out
        ${code}
        EOF
      '';
    };
  };
}
