{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.gtk;
  cfg2 = config.gtk.gtk2;
  cfg3 = config.gtk.gtk3;

  toGtk3Ini = generators.toINI {
    mkKeyValue = key: value:
      let
        value' = if isBool value then
          (if value then "true" else "false")
        else
          toString value;
      in "${key}=${value'}";
  };

  formatGtk2Option = n: v:
    let
      v' = if isBool v then
        (if v then "true" else "false")
      else if isString v then
        ''"${v}"''
      else
        toString v;
    in "${n} = ${v'}";

  themeType = types.submodule {
    options = {
      package = mkOption {
        type = types.nullOr types.package;
        default = null;
        example = literalExample "pkgs.gnome.gnome_themes_standard";
        description = ''
          Package providing the theme. This package will be installed
          to your profile. If <literal>null</literal> then the theme
          is assumed to already be available in your profile.
        '';
      };

      name = mkOption {
        type = types.str;
        example = "Adwaita";
        description = "The name of the theme within the package.";
      };
    };
  };

in {
  meta.maintainers = [ maintainers.rycee ];

  imports = [
    (mkRemovedOptionModule [ "gtk" "gtk3" "waylandSupport" ] ''
      This options is not longer needed and can be removed.
    '')
  ];

  options = {
    gtk = {
      enable = mkEnableOption "GTK 2/3 configuration";

      font = mkOption {
        type = types.nullOr hm.types.fontType;
        default = null;
        description = ''
          The font to use in GTK+ 2/3 applications.
        '';
      };

      iconTheme = mkOption {
        type = types.nullOr themeType;
        default = null;
        description = "The icon theme to use.";
      };

      theme = mkOption {
        type = types.nullOr themeType;
        default = null;
        description = "The GTK+2/3 theme to use.";
      };

      gtk2 = {
        extraConfig = mkOption {
          type = types.lines;
          default = "";
          example = "gtk-can-change-accels = 1";
          description = ''
            Extra configuration lines to add verbatim to
            <filename>~/.gtkrc-2.0</filename>.
          '';
        };

        configLocation = mkOption {
          type = types.path;
          default = "${config.home.homeDirectory}/.gtkrc-2.0";
          defaultText =
            literalExample ''"''${config.home.homeDirectory}/.gtkrc-2.0"'';
          example =
            literalExample ''"''${config.xdg.configHome}/gtk-2.0/gtkrc"'';
          description = ''
            The location to put the GTK configuration file.
          '';
        };
      };

      gtk3 = {
        bookmarks = mkOption {
          type = types.listOf types.str;
          default = [ ];
          example = [ "file:///home/jane/Documents" ];
          description = "Bookmarks in the sidebar of the GTK file browser";
        };

        extraConfig = mkOption {
          type = with types; attrsOf (either bool (either int str));
          default = { };
          example = {
            gtk-cursor-blink = false;
            gtk-recent-files-limit = 20;
          };
          description = ''
            Extra configuration options to add to
            <filename>~/.config/gtk-3.0/settings.ini</filename>.
          '';
        };

        extraCss = mkOption {
          type = types.lines;
          default = "";
          description = ''
            Extra configuration lines to add verbatim to
            <filename>~/.config/gtk-3.0/gtk.css</filename>.
          '';
        };
      };
    };
  };

  config = mkIf cfg.enable (let
    ini = optionalAttrs (cfg.font != null) {
      gtk-font-name = let
        fontSize =
          optionalString (cfg.font.size != null) " ${toString cfg.font.size}";
      in "${cfg.font.name}" + fontSize;
    } // optionalAttrs (cfg.theme != null) { gtk-theme-name = cfg.theme.name; }
      // optionalAttrs (cfg.iconTheme != null) {
        gtk-icon-theme-name = cfg.iconTheme.name;
      };

    dconfIni = optionalAttrs (cfg.font != null) {
      font-name = let
        fontSize =
          optionalString (cfg.font.size != null) " ${toString cfg.font.size}";
      in "${cfg.font.name}" + fontSize;
    } // optionalAttrs (cfg.theme != null) { gtk-theme = cfg.theme.name; }
      // optionalAttrs (cfg.iconTheme != null) {
        icon-theme = cfg.iconTheme.name;
      };

    optionalPackage = opt:
      optional (opt != null && opt.package != null) opt.package;
  in {
    home.packages = optionalPackage cfg.font ++ optionalPackage cfg.theme
      ++ optionalPackage cfg.iconTheme;

    home.file.${cfg2.configLocation} = {
      text = concatStringsSep "\n" (mapAttrsToList formatGtk2Option ini) + "\n"
        + cfg2.extraConfig;
      onChange = let xsettingsd = "${pkgs.xsettingsd}/bin/xsettingsd";
      in ''
        DISPLAY=":0" $DRY_RUN_CMD ${xsettingsd} -c \
        <( echo "Net/ThemeName \"${cfg.theme.name}\"" ) & \
        kill $! || true
      '';
    };

    home.sessionVariables.GTK2_RC_FILES = cfg2.configLocation;

    xdg.configFile."gtk-3.0/settings.ini" = {
      text = toGtk3Ini { Settings = ini // cfg3.extraConfig; };
      onChange = let
        gsettings-schemas =
          "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/gsettings-desktop-schemas-${pkgs.gsettings-desktop-schemas.version}";
      in ''
        XDG_DATA_DIRS="$XDG_DATA_DIRS"${XDG_DATA_DIRS:+:}${escapeShellArg gsettings-schemas} \
        DBUS_SESSION_BUS_ADDRESS="unix:path=''${XDG_RUNTIME_DIR:-/run/user/$UID}/bus" \
        $DRY_RUN_CMD ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme ${cfg.theme.name}
      '';
    };

    xdg.configFile."gtk-3.0/gtk.css".text = cfg3.extraCss;

    xdg.configFile."gtk-3.0/bookmarks" = mkIf (cfg3.bookmarks != [ ]) {
      text = concatStringsSep "\n" cfg3.bookmarks;
    };

    dconf.settings."org/gnome/desktop/interface" = dconfIni;
  });
}
