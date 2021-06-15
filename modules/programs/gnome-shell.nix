{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.programs.gnome-shell;

  extensionOpts = { config, ... }: {
    options = {
      id = mkOption {
        type = types.str;
        example = "user-theme@gnome-shell-extensions.gcampax.github.com";
        description = ''
          ID of the gnome-shell extension. If not provided, it
          will be obtained from <varname>package.uuid</varname>.
        '';
      };

      package = mkOption {
        type = types.package;
        example = "pkgs.gnome3.gnome-shell-extensions";
        description = ''
          Package providing a gnome-shell extension in
          <filename>$out/share/gnome-shell/extensions/''${id}</filename>.
        '';
      };
    };

    config = mkIf (hasAttr "uuid" config.package) {
      id = mkDefault config.package.uuid;
    };
  };

  themeOpts = {
    options = {
      name = mkOption {
        type = types.str;
        example = "Plata-Noir";
        description = ''
          Name of the gnome-shell theme.
        '';
      };
      package = mkOption {
        type = types.nullOr types.package;
        default = null;
        example = literalExample "pkgs.plata-theme";
        description = ''
          Package providing a gnome-shell theme in
          <filename>$out/share/themes/''${name}/gnome-shell</filename>.
        '';
      };
    };
  };

in {
  meta.maintainers = [ maintainers.tadfisher ];

  options.programs.gnome-shell = {
    enable = mkEnableOption "gnome-shell customization";

    extensions = mkOption {
      type = types.listOf (types.submodule extensionOpts);
      default = [ ];
      example = literalExample ''
        [
          { package = pkgs.gnomeExtensions.dash-to-panel; }
          {
            id = "user-theme@gnome-shell-extensions.gcampax.github.com";
            package = pkgs.gnome3.gnome-shell-extensions;
          }
        ]
      '';
      description = ''
        List of gnome-shell extensions.
      '';
    };

    theme = mkOption {
      type = types.nullOr (types.submodule themeOpts);
      default = null;
      example = literalExample ''
        {
          name = "Plata-Noir";
          package = [ pkgs.plata-theme ];
        }
      '';
      description = ''
        Theme to use for gnome-shell.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf (cfg.extensions != [ ]) {
      dconf.settings."org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = catAttrs "id" cfg.extensions;
      };

      home.packages = catAttrs "package" cfg.extensions;
    })

    (mkIf (cfg.theme != null) {
      dconf.settings."org/gnome/shell/extensions/user-theme".name =
        cfg.theme.name;

      programs.gnome-shell.extensions = [{
        id = "user-theme@gnome-shell-extensions.gcampax.github.com";
        package = pkgs.gnome3.gnome-shell-extensions;
      }];

      home.packages = [ cfg.theme.package ];
    })
  ]);
}
