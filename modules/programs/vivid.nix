{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.programs.vivid;
  yaml = pkgs.formats.yaml { };
in
{
  meta.maintainers = [ maintainers.noib3 ];

  options.programs.vivid = {
    enable = mkEnableOption "vivid";

    package = mkOption {
      type = types.package;
      default = pkgs.vivid;
      defaultText = literalExample "pkgs.vivid";
      description = "The vivid package to install.";
    };

    filetypes = mkOption {
      type = yaml.type;
      default = { };
      example = literalExample ''
        {
          core = {
            regular_file = [ "$fi" ];
            directory = [ "$di" ];
          };
          text = {
            readme = [ "README.md" ];
            licenses = [ "LICENSE" ];
          };
        }
      '';
      description = ''
        Configuration written to
        <filename>~/.config/vivid/filetypes.yml</filename>.
      '';
    };

    themes = mkOption {
      type = types.attrsOf (yaml.type);
      default = { };
      example = literalExample ''
        {
          mytheme = {
            colors = {
              blue = "0000ff";
            };
            core = {
              directory = {
                foreground = "blue";
                font-style = "bold";
              };
            };
          };
        }
      '';
      description = ''
        Theme files written to
        <filename>~/.config/vivid/themes/<mytheme>.yml</filename>.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile = {
      "vivid/filetypes.yml".source =
        yaml.generate "filetypes.yml" cfg.filetypes;
    } // mapAttrs'
      (
        name: value: nameValuePair
          ("vivid/themes/${name}.yml")
          ({ source = yaml.generate "${name}.yml" value; })
      )
      cfg.themes;
  };
}
