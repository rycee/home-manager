{ config, pkgs, lib, ... }:
with builtins;
with lib;
let cfg = config.programs.hexchat;
in {
  meta.maintainers = [ maintainers.superherointj ];

  options.programs.hexchat = with types; {
    channels = let
      modChannelOption = submodule {
        options = {
          autojoin = mkOption {
            type = listOf str;
            default = [ ];
            description = "Channels list to autojoin on connecting to server.";
            example = literalExample ''[ "##linux" "#nix" ]'';
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
          options = let
            channelOptions = submodule {
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
          in mkOption {
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
    in mkOption {
      default = null;
      type = nullOr (attrsOf modChannelOption);
      description = "Configures '~/.config/hexchat/servlist.conf'";
      example = literalExample ''
        {
          freenode = {
            autojoin = [
              "#home-manager"
              "##linux"
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
        };'';
      type = nullOr (attrsOf str);
    };
    enable = mkEnableOption "HexChat - Graphical IRC client";
    overwriteConfigFiles = mkOption {
      type = nullOr bool;
      description = ''
        Enables overwritting HexChat configuration files (hexchat.conf, servlist.conf). Any existing HexChat configuration will be lost. Certify to back-up any previous configuration before enabling this.
        Enabling this setting is recommended, because everytime HexChat application is closed it overwrites Nix/Home-Manager provided configuration files, causing:
        1. Nix/HM provided configuration to be out of sync with actual active HexChat configuration.
        2. Blocking Nix/HM updates until configuration files are manually removed.'';
      default = false;
    };
    theme = mkOption {
      default = null;
      description =
        "Theme package for HexChat. Expects a derivation containing decompressed theme files. '.hct' file format requires unzip decompression, as seen in example.";
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
        };'';
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
      text = let hexchatConf = cfg.settings;
      in concatMapStringsSep "\n" (x: x + " = " + hexchatConf.${x})
      (attrNames hexchatConf);
    };
    xdg.configFile."hexchat/servlist.conf" = mkIf (cfg.channels != null)
      (if attrNames cfg.channels == [ ] then {
        text = "";
      } else {
        force = cfg.overwriteConfigFiles;
        text = let
          transformChannel = (channelName:
            let
              channel = cfg.channels.${channelName};
              transformField = (k: v:
                optionalString (v != null) ''

                  ${k}=${v}'');
              listChar = c: l: concatMapStrings (transformField c) l;
              loginMethodMap = {
                nickServMsg = 1;
                nickServ = 2;
                challengeAuth = 4;
                sasl = 6;
                serverPassword = 7;
                saslExternal = 10;
                customCommands = 9;
              };
            in let
              name = transformField "N" channelName;
              nickname = transformField "I" channel.nickname;
              nickname2 = transformField "i" channel.nickname2;
              realName = transformField "R" channel.realName;
              userName = transformField "U" channel.userName;
              password = transformField "P" channel.password;
              charset = transformField "E" channel.charset;
              loginMethod = transformField "L"
                (optionalString (channel.loginMethod != null)
                  (toString loginMethodMap.${channel.loginMethod}));
              servers = listChar "S" channel.servers;
              autojoin = listChar "J" channel.autojoin;
              commands = listChar "C" channel.commands;
              options = let
                computeFieldsValue = (with channel.options;
                  (if channel.options == null then
                    0
                  else
                    ((if autoconnect then 8 else 0)
                      + (if !connectToSelectedServerOnly then 1 else 0)
                      + (if !bypassProxy then 16 else 0)
                      + (if forceSSL then 4 else 0)
                      + (if acceptInvalidSSLCertificates then 32 else 0)
                      + (if useGlobalUserInformation then 2 else 0))));
              in transformField "F" (toString computeFieldsValue);
              # Note: Missing option `D=`.
            in name + loginMethod + charset + options + # `D=` position +
            nickname + nickname2 + realName + userName + password + servers
            + autojoin + commands);
        in concatMapStringsSep "\n" transformChannel (attrNames cfg.channels)
        # Line break required to avoid cropping last field value.
        + "\n\n";
      });
  };
}
