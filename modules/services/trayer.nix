{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.trayer;

in {
  meta.maintainers = [ maintainers.mager ];

  options = {
    services.trayer = {
      enable =
        mkEnableOption "trayer, the lightweight GTK2+ systray for UNIX desktops";

      package = mkOption {
        default = pkgs.trayer;
        defaultText = literalExample "pkgs.trayer";
        type = types.package;
        example = literalExample "pkgs.trayer";
        description = "The package to use for the trayer binary.";
      };

      config = mkOption {
        type = with types; attrsOf (nullOr (either str (either bool int)));
        description = ''
          Trayer configuration as a set of attributes. 
          Details for trayer can be found here: https://github.com/sargon/trayer-srg
          
          edge       <left|right|top|bottom|none> (default:bottom)
          align      <left|right|center>          (default:center)
          margin     <number>                     (default:0)
          widthtype  <request|pixel|percent>      (default:percent)
          width      <number>                     (default:100)
          heighttype <request|pixel>              (default:pixel)
          height     <number>                     (default:26)
          SetDockType     <true|false>            (default:true)
          SetPartialStrut <true|false>            (default:true)
          transparent     <true|false>            (default:false)
          alpha      <number>                     (default:127)
          tint       <int>                        (default:0xFFFFFFFF)
          distance   <number>                     (default:0)
          distancefrom <left|right|top|bottom>    (default:top)
          expand     <false|true>                 (default:true)
          padding    <number>                     (default:0)
          monitor    <number|primary>             (default:0)
          iconspacing <number>                    (default:0)    
        '';
        default = { };
        defaultText = literalExample "{ }";
        example = literalExample ''
          {
            edge = "top";
            padding = 6;
            SetDockType = true;
            tint = "0x282c34";
          }
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [ cfg.package ];

      systemd.user.services.trayer = let
        parameter = let
          valueToString = v:
            if isBool v then
              (if v then "true" else "false")
            else
              "${toString v}";
        in concatStrings
        (mapAttrsToList (k: v: "--${k} ${valueToString v} ") cfg.config);
      in {
        Unit = {
          Description = "trayer -- lightweight GTK2+ systray for UNIX desktops";
          PartOf = [ "tray.target" ];
        };

        Install.WantedBy = [ "tray.target" ];

        Service = {
          ExecStart = "${cfg.package}/bin/trayer ${parameter}";
          Restart = "on-failure";
        };
      };
    }

  ]);
}
