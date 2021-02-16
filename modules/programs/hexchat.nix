{ config, pkgs, lib, ... }:

with builtins;
with lib;
let
  cfg = config.programs.hexchat;

  # Submodules
  channelOptions = with types;
    submodule {
      options = {
        autoconnect = mkOption {
          type = nullOr bool;
          description = "Autoconnect to network";
          default = false;
        };

        connectToSelectedServerOnly = mkOption {
          type = nullOr bool;
          description = "Connect to selected server only";
          default = true;
        };

        bypassProxy = mkOption {
          type = nullOr bool;
          description = "Bypass proxy";
          default = true;
        };

        forceSSL = mkOption {
          type = nullOr bool;
          description = "Use SSL for all servers";
          default = false;
        };

        acceptInvalidSSLCertificates = mkOption {
          type = nullOr bool;
          description = "Accept invalid SSL certificates";
          default = false;
        };

        useGlobalUserInformation = mkOption {
          type = nullOr bool;
          description = "Use global user information";
          default = false;
        };
      };
    };

  modChannelOption = with types;
    submodule {
      options = {
        autojoin = mkOption {
          type = listOf str;
          default = [ ];
          description = "Channels list to autojoin on connecting to server.";
          example = literalExample ''[ "#home-manager" "#linux" "#nix" ]'';
        };

        charset = mkOption {
          type = nullOr str;
          default = null;
          description = "Charset";
          example = "UTF-8 (Unicode)";
        };

        commands = mkOption {
          type = listOf str;
          description = "Commands to be executed on connecting to server.";
          example = literalExample ''[ "ECHO Greetings fellow Nixer! ]'';
          default = [ ];
        };

        loginMethod = mkOption {
          type = nullOr (enum [
            "nickServMsg"
            "nickServ"
            "challengeAuth"
            "sasl"
            "serverPassword"
            "saslExternal"
            "customCommands"
          ]);

          description = ''
            null => Default
            "nickServMsg" (1) => NickServ (/MSG NickServ + password)
            "nickServ" (2) => NickServ (/NICKSERV + password)
            "challengeAuth" (4) => Challenge Auth (username + password)
            "sasl" (6) => SASL (username + password)
            "serverPassword" (7) => Server password (/PASS password)
            "saslExternal" (10) => SASL EXTERNAL (cert)
            "customCommands" (9) => Custom (Use "commands" field for Auth, like: 'commands = [ "/msg NickServ IDENTIFY my_password" ];' )
          '';

          default = null;
        };

        nickname = mkOption {
          type = nullOr str;
          default = null;
          description = "Primary nickname";
        };

        nickname2 = mkOption {
          type = nullOr str;
          default = null;
          description = "Secondary nickname";
        };

        options = mkOption {
          default = null;
          type = nullOr channelOptions;
          description = "Channel options";
          example = literalExample
            "{ autoconnect = true; useGlobalUserInformation = true; }";
        };

        password = mkOption {
          type = nullOr str;
          default = null;
          description = "Password";
        };

        realName = mkOption {
          type = nullOr str;
          default = null;
          description = "Real name";
        };

        servers = mkOption {
          type = (listOf str);
          description = "IRC Server Address List";
          example =
            literalExample ''[ "chat.freenode.net" "irc.freenode.net" ]'';
          default = [ ];
        };

        userName = mkOption {
          type = nullOr str;
          default = null;
          description = "User name";
        };
      };
    };

  # helpers
  transformField = k: v: if (v != null) then "${k}=${v}" else null;

  listChar = c: l:
    if (l != [ ]) then
      (concatMapStringsSep "\n" (transformField c) l)
    else
      null;

  computeFieldsValue = (channel:
    (toString (if channel.options == null then
      0
    else
      (with channel.options;
        (if autoconnect then 8 else 0)
        + (if !connectToSelectedServerOnly then 1 else 0)
        + (if !bypassProxy then 16 else 0) + (if forceSSL then 4 else 0)
        + (if acceptInvalidSSLCertificates then 32 else 0)
        + (if useGlobalUserInformation then 2 else 0)))));

  loginMethod = let
    loginMethodMap = {
      nickServMsg = 1;
      nickServ = 2;
      challengeAuth = 4;
      sasl = 6;
      serverPassword = 7;
      saslExternal = 10;
      customCommands = 9;
    };
  in (channel:
    transformField "L" (optionalString (channel.loginMethod != null)
      (toString loginMethodMap.${channel.loginMethod})));

  # Note: Missing option `D=`.
  transformChannel = (channelName:
    let channel = cfg.channels.${channelName};
    in concatStringsSep "\n" (filter (v: v != null) [
      "" # leave a space between one server and another
      (transformField "N" channelName)
      (loginMethod channel)
      (transformField "E" channel.charset)
      (transformField "F" (computeFieldsValue channel))
      (transformField "I" channel.nickname)
      (transformField "i" channel.nickname2)
      (transformField "R" channel.realName)
      (transformField "U" channel.userName)
      (transformField "P" channel.password)
      (listChar "S" channel.servers)
      (listChar "J" channel.autojoin)
      (listChar "C" channel.commands)
    ]));
in {
  meta.maintainers = with maintainers; [ superherointj thiagokokada ];

  options.programs.hexchat = with types; {
    enable = mkEnableOption "HexChat - Graphical IRC client";

    channels = mkOption {
      default = null;
      type = nullOr (attrsOf modChannelOption);
      description = "Configures '~/.config/hexchat/servlist.conf'";
      example = literalExample ''
        {
          freenode = {
            autojoin = [
              "#home-manager"
              "#linux"
              "#nixos"
            ];
            charset = "UTF-8 (Unicode)";
            commands = [
              "ECHO Buzz Lightyear sent you a message: 'To Infinity... and Beyond!'"
            ];
            loginMethod = sasl;
            nickname = "my_nickname";
            nickname2 = "my_secondchoice";
            options = {
              acceptInvalidSSLCertificates = false;
              autoconnect = true;
              bypassProxy = true;
              connectToSelectedServerOnly = true;
              useGlobalUserInformation = false;
              forceSSL = false;
            };
            password = "my_password";
            realName = "my_realname";
            servers = [
              "chat.freenode.net"
              "irc.freenode.net"
            ];
            userName = "my_username";
          };
        }'';
    };

    settings = mkOption {
      default = null;
      description = ''
        Configuration for "~/.config/hexchat/hexchat.conf", see
        <link xlink:href="https://hexchat.readthedocs.io/en/latest/settings.html#list-of-settings"/>
        for supported values.
      '';
      example = literalExample ''
        {
          irc_nick1 = "mynick";
          irc_username = "bob";
          irc_realname = "Bart Simpson";
          text_font = "Monospace 14";
        };
      '';
      type = nullOr (attrsOf str);
    };

    overwriteConfigFiles = mkOption {
      type = nullOr bool;
      description = ''
        Enables overwritting HexChat configuration files (hexchat.conf, servlist.conf).
        Any existing HexChat configuration will be lost.
        Certify to back-up any previous configuration before enabling this.

        Enabling this setting is recommended, because everytime HexChat application is
        closed it overwrites Nix/Home-Manager provided configuration files, causing:
        1. Nix/HM provided configuration to be out of sync with actual active HexChat configuration.
        2. Blocking Nix/HM updates until configuration files are manually removed.
      '';
      default = false;
    };

    theme = mkOption {
      default = null;
      description = ''
        Theme package for HexChat.
        Expects a derivation containing decompressed theme files.
        '.hct' file format requires unzip decompression, as seen in example.
      '';
      example = ''
        stdenv.mkDerivation rec {
          name = "hexchat-theme-MatriY";
          buildInputs = [ pkgs.unzip ];
          src = fetchurl {
              url = "https://dl.hexchat.net/themes/MatriY.hct";
              sha256 = "sha256-ffkFJvySfl0Hwja3y7XCiNJceUrGvlEoEm97eYNMTZc=";
          };
          unpackPhase = "unzip ''${src}";
          installPhase = "cp -r . $out";
        };
      '';
      type = nullOr package;
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.hexchat ];
    xdg.configFile."hexchat" = mkIf (cfg.theme != null) {
      source = cfg.theme;
      recursive = true;
    };

    xdg.configFile."hexchat/hexchat.conf" = mkIf (cfg.settings != null) {
      force = cfg.overwriteConfigFiles;
      text = concatMapStringsSep "\n" (x: x + " = " + cfg.settings.${x})
        (attrNames cfg.settings);
    };

    xdg.configFile."hexchat/servlist.conf" = mkIf (cfg.channels != null)
      (if attrNames cfg.channels == [ ] then {
        text = "";
      } else {
        force = cfg.overwriteConfigFiles;
        text =
          (concatMapStringsSep "\n" transformChannel (attrNames cfg.channels))
          # Line break required to avoid cropping last field value.
          + "\n\n";
      });
  };
}
