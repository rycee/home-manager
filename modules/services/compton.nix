{ config, lib, pkgs, ... }:

with lib; {
  imports = let
    old = n: [ "services" "compton" n ];
    new = n: [ "services" "picom" n ];
  in [
    (mkRenamedOptionModule (old "settings") (new "settings"))
    (mkRenamedOptionModule (old "package") (new "package"))
  ];

  options.services.compton.enable = mkEnableOption "Compton X11 compositor" // {
    visible = false;
  };

  config = mkIf config.services.compton.enable {
    warnings = [
      "Obsolete option `services.compton.enable' is used. It was renamed to `services.picom.enable'."
    ];

    services.picom.enable = true;
  };
}
