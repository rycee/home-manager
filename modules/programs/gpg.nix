{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.gpg;
  dag = config.lib.dag;

  mkKeyValue = key: value:
    if isString value
    then "${key} ${value}"
    else optionalString value key;

  cfgText = generators.toKeyValue {
    inherit mkKeyValue;
    listsAsDuplicateKeys = true;
  } cfg.settings;

  primitiveType = types.oneOf [ types.str types.bool ];

  keyfileOpts = { config, ...}: {
    options = {
      text = mkOption {
        type = types.nullOr types.lines;
        description = ''
          Text of a gpg public key
        '';
        default = null;
      };
      source = mkOption {
        type = types.path;
        description = ''
          Path of a gpg public key file
        '';
      };
    };
    config = {
      source = mkIf (config.text != null)
        (pkgs.writeText "gpg-pubkeys" config.text);
    };
  };

  keyringFiles = pkgs.runCommand "gpg-pubring" {
      buildInputs = [ pkgs.gnupg ];
    } ''
    HOME="/build"
    mkdir /build/.gnupg
    chmod 700 /build/.gnupg
    gpg-agent --daemon
    ${concatMapStrings
      ({source, ...}: ''
        gpg --import ${source}
      ''
      )
      cfg.keyfiles
    }
    mkdir $out
    cp /build/.gnupg/{pubring.kbx} $out
  '';
in
{
  options.programs.gpg = {
    enable = mkEnableOption "GnuPG";

    settings = mkOption {
      type = types.attrsOf (types.either primitiveType (types.listOf types.str));
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

    mutableKeys = mkOption {
      type = types.bool;
      default = true;
      description = ''
        If set to <literal>true</literal>, you may manage your keyring
        as a user using the <literal>gpg</literal> command. Upon activation,
        the keyring will have managed keys added without overwriting unmanaged keys.

        If set to <literal>false</literal>, the <literal>.gnupg/pubring.kbx</literal>
        will become an immutable link to the nix store, denying modifications.
      '';
    };

    keyfiles = mkOption {
      type = types.listOf (types.submodule keyfileOpts);
      example = literalExample ''
        [ { source = ./pubkeys.txt; } ]
      '';
      default = [ ];
      description = ''
        A list of keyfiles to be imported into GnuPG. These keyfiles
        will be copied into the world-readable Nix store.
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.gpg.settings = {
      personal-cipher-preferences = mkDefault "AES256 AES192 AES";
      personal-digest-preferences = mkDefault "SHA512 SHA384 SHA256";
      personal-compress-preferences = mkDefault "ZLIB BZIP2 ZIP Uncompressed";
      default-preference-list = mkDefault "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
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

    home.packages = [ pkgs.gnupg ];

    home.file.".gnupg/gpg.conf".text = cfgText;

    # Link keyring if keys are not mutable
    home.file.".gnupg/pubring.kbx".source = mkIf
      (!cfg.mutableKeys && cfg.keyfiles != [])
      "${keyringFiles}/pubring.kbx";

    home.activation = mkIf (cfg.keyfiles != []) {
      # Import at activation time if mutable keys
      importGpgKeys = optionalString cfg.mutableKeys (
        dag.entryAfter ["linkGeneration"] (
          lib.concatMapStrings
            ({source, ...}: ''
              ${pkgs.gnupg}/bin/gpg --import ${source}
            '')
            cfg.keyfiles
        )
      );
    };
  };
}
