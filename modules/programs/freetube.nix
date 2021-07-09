{ config, lib, pkgs, ... }:

with lib;

let
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  # FIXME-REDOX(Krey): Integrate
  #inherit (pkgs.stdenv.hostPlatform) isRedox;
  # FIXME-HURD(Krey): Integrate
  #inherit (pkgs.stdenv.hostPlatform) isHurd;
  # FIXME-FREEBSD(Krey): Integrate
  #inherit (pkgs.stdenv.hostPlatform) isFreebsd;
  inherit (pkgs.stdenv.hostPlatform) isCygwin;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  cfg = config.programs.freetube;

  # Config paths are on https://docs.freetubeapp.io/usage/data-location/
  freetubeConfigPath =
	if isLinux
	  # DNM(Krey): Verify that $HOME works
	  then "$HOME/.config/FreeTube"
	else if isCygwin
	  # DNM(Krey): Verify that `%APPDATA%` works
	  then "%APPDATA%/FreeTube"
	else if isDarwin
	  then "$HOME/Library/Application Support/FreeTube/"
	else
	  # FIXME-LOCALIZATION(Krey): Integrate `config.i18n.defaultLocale` for translations
	  throw "Platform '${pkgs.stdenv.hostPlatform}' is not implemented"
in {
  meta.maintainers = [ maintainers.kreyren ];

  options = {
	programs.freetube = {
	  enable = mkEnableOption "freetube, the privacy respecting youtube frontend";

	  package = mkOption {
		type = types.package;
		default = pkgs.freetube;
		defaultText = literalExample "pkgs.freetube";
		example = literalExample "pkgs.freetube-something";
		description = ''
		  The freetube package to install. May be used to change the version.
		'';
		};
  };

	config = mkIf cfg.enable {
    home.packages = [ cfg.finalPackage ];
    programs.freetube.finalPackage = freetubeWithPackages cfg.extraPackages;
  };
}
