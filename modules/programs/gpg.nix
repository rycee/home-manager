{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.gpg;

  mkKeyValue = key: value:
    if isString value then "${key} ${value}" else optionalString value key;

  cfgText = generators.toKeyValue {
    inherit mkKeyValue;
    listsAsDuplicateKeys = true;
  } cfg.settings;

  scdaemonCfgText = generators.toKeyValue {
    inherit mkKeyValue;
    listsAsDuplicateKeys = true;
  } cfg.scdaemonSettings;

  primitiveType = types.oneOf [ types.str types.bool ];
in {
  options.programs.gpg = {
    enable = mkEnableOption "GnuPG";

    package = mkOption {
      type = types.package;
      default = pkgs.gnupg;
      defaultText = literalExample "pkgs.gnupg";
      example = literalExample "pkgs.gnupg23";
      description =
        "The Gnupg package to use (also used the gpg-agent service).";
    };

    settings = mkOption {
      type =
        types.attrsOf (types.either primitiveType (types.listOf types.str));
      example = literalExample ''
        {
          no-comments = false;
          s2k-cipher-algo = "AES128";
        }
      '';
      description = ''
        GnuPG configuration options. Available options are described
        in the gpg manpage:
        <link xlink:href="https://gnupg.org/documentation/manpage.html"/>.
      '';
    };

    scdaemonSettings = mkOption {
      type =
        types.attrsOf (types.either primitiveType (types.listOf types.str));
      example = literalExample ''
        {
          disable-ccid = true;
        }
      '';
      description = ''
        SCdaemon configuration options. Available options are described
        in the gpg scdaemon manpage:
        <link xlink:href="https://www.gnupg.org/documentation/manuals/gnupg/Scdaemon-Options.html"/>.
      '';
    };

    homedir = mkOption {
      type = types.path;
      example = literalExample ''"''${config.xdg.dataHome}/gnupg"'';
      default = "${config.home.homeDirectory}/.gnupg";
      defaultText = literalExample ''"''${config.home.homeDirectory}/.gnupg"'';
      description = "Directory to store keychains and configuration.";
    };
  };

  config = mkIf cfg.enable {
    programs.gpg.settings = {
      personal-cipher-preferences = mkDefault "AES256 AES192 AES";
      personal-digest-preferences = mkDefault "SHA512 SHA384 SHA256";
      personal-compress-preferences = mkDefault "ZLIB BZIP2 ZIP Uncompressed";
      default-preference-list = mkDefault
        "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
      cert-digest-algo = mkDefault "SHA512";
      s2k-digest-algo = mkDefault "SHA512";
      s2k-cipher-algo = mkDefault "AES256";
      charset = mkDefault "utf-8";
      fixed-list-mode = mkDefault true;
      no-comments = mkDefault true;
      no-emit-version = mkDefault true;
      keyid-format = mkDefault "0xlong";
      list-options = mkDefault "show-uid-validity";
      verify-options = mkDefault "show-uid-validity";
      with-fingerprint = mkDefault true;
      require-cross-certification = mkDefault true;
      no-symkey-cache = mkDefault true;
      use-agent = mkDefault true;
    };

    programs.gpg.scdaemonSettings = {
      # no defaults for scdaemon
    };

    home.packages = [ cfg.package ];
    home.sessionVariables = { GNUPGHOME = cfg.homedir; };

    home.file."${cfg.homedir}/gpg.conf".text = cfgText;

    home.file."${cfg.homedir}/scdaemon.conf".text = scdaemonCfgText;
  };
}
