{ config, lib, pkgs, ...}:

with lib;

let

  cfg = config.programs.zathura;

  formatLine = n: v:
    let
      formatValue = v:
        if isBool v then (if v then "true" else "false")
        else toString v;
    in
      "set ${n}\t\"${formatValue v}\"";
in

{
  meta.maintainers = [maintainers.rprospero];

  options.programs.zathura = {
    enable = mkEnableOption ''Zathura is a highly customizable and funtional
      document viewer focused on keyboard interaction.'';
    options = mkOption {
      default = null;
      type = types.nullOr types.attrs;
      description = ''
      Add :set command options to zathura and make them permanent.
      Run <code>man zathura</code> to see the full list of options
      '';
      example = literalExample ''
        {default-bg = "#000000"; default-fg = "#FFFFFF";}
      '';
    };
    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
      Additional commands for zathura the zathurarc file.  If this and all
      other zathura options are <code>null</code>, then this feature is
      disabled and no <filename>zathurarc</filename> link is produced.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.zathura ];
    xdg.configFile."zathura/zathurarc".text =
    concatStringsSep "\n" ([]
      ++ (optional (cfg.extraConfig != "") cfg.extraConfig)
      ++ (optionals (cfg.options != null) (mapAttrsToList formatLine cfg.options))) + "\n";
  };
}
