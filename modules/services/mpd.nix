{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.mpd;

  mpdConf = cfg': pkgs.writeText "mpd.conf" ''
    music_directory     "${cfg'.musicDirectory}"
    playlist_directory  "${cfg'.playlistDirectory}"
    ${lib.optionalString (cfg'.dbFile != null) ''
      db_file             "${cfg'.dbFile}"
    ''}
    state_file          "${cfg'.dataDir}/state"
    sticker_file        "${cfg'.dataDir}/sticker.sql"

    ${optionalString (cfg'.network.listenAddress != "any")
      ''bind_to_address "${cfg'.network.listenAddress}"''}
    ${optionalString (cfg'.network.port != 6600)
      ''port "${toString cfg'.network.port}"''}

    ${cfg'.extraConfig}
  '';

  mpdDaemon = { name, ... } @ args: let cfg' = args.config; in { options = {

    enable = mkEnableOption "this instance" // {
      default = cfg'.name == "default" && cfg.enable;
      defaultText = literalExample ''name == "default" && config.services.mpd.enable'';
    };

    name = mkOption {
      type = types.str;
      default = name;
      example = "nas";
      description = ''
        The name of this instance. Defaults to the attribute name.
      '';
    };

    default = mkOption {
      type = types.bool;
      default = cfg'.name == "default";
      defaultText = literalExample ''name == "default"'';
      description = ''
        Whether this instance is the default, and thus uses a service named just
        <literal>mpd.service</literal>.
      '';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.mpd;
      defaultText = "pkgs.mpd";
      description = ''
        The MPD package to run.
      '';
    };

    autoStart = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether this instance should be started automatically.
      '';
    };

    serviceName = mkOption {
      type = types.str;
      default = if cfg'.default then "mpd" else "mpd-${cfg'.name}";
      defaultText = literalExample ''if default then "mpd" else "mpd-''${name}"'';
      description = ''
        The name of this instance's service and data directory.
      '';
    };

    musicDirectory = mkOption {
      type = with types; either path (strMatching "(http|https|nfs|smb)://.+");
      default = "${config.home.homeDirectory}/music";
      defaultText = "$HOME/music";
      apply = toString;       # Prevent copies to Nix store.
      description = ''
        The directory where mpd reads music from.
      '';
    };

    playlistDirectory = mkOption {
      type = with types; either path str;
      default = "${cfg'.dataDir}/playlists";
      defaultText = "\${dataDir}/playlists";
      apply = toString;       # Prevent copies to Nix store.
      description = ''
        The directory where mpd stores playlists.
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Extra directives added to to the end of MPD's configuration
        file, <filename>mpd.conf</filename>. Basic configuration
        like file location and uid/gid is added automatically to the
        beginning of the file. For available options see
        <citerefentry>
          <refentrytitle>mpd.conf</refentrytitle>
          <manvolnum>5</manvolnum>
        </citerefentry>.
      '';
    };

    dataDir = mkOption {
      type = with types; either path str;
      default = "${config.xdg.dataHome}/${cfg'.serviceName}";
      defaultText = "$XDG_DATA_HOME/\${serviceName}";
      apply = toString;       # Prevent copies to Nix store.
      description = ''
        The directory where MPD stores its state, tag cache,
        playlists etc.
      '';
    };

    network = {
      startWhenNeeded = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable systemd socket activation.
        '';
      };

      listenAddress = mkOption {
        type = types.str;
        default = "127.0.0.1";
        example = "any";
        description = ''
          The address for the daemon to listen on.
          Use <literal>any</literal> to listen on all addresses.
        '';
      };

      port = mkOption {
        type = types.port;
        default = 6600;
        description = ''
          The TCP port on which the the daemon will listen.
        '';
      };

    };

    dbFile = mkOption {
      type = types.nullOr types.str;
      default = "${cfg'.dataDir}/tag_cache";
      defaultText = ''''${dataDir}/tag_cache'';
      description = ''
        The path to MPD's database. If set to
        <literal>null</literal> the parameter is omitted from the
        configuration.
      '';
    };

  }; };

  mpdService = cfg': {
    Unit = {
      After = [ "network.target" "sound.target" ];
      Description = "Music Player Daemon";
    };

    Install = mkIf (!cfg'.network.startWhenNeeded && cfg'.autoStart) {
      WantedBy = [ "default.target" ];
    };

    Service = {
      Environment = "PATH=${config.home.profileDirectory}/bin";
      ExecStart = "${cfg'.package}/bin/mpd --no-daemon ${mpdConf cfg'}";
      Type = "notify";
      ExecStartPre = ''${pkgs.bash}/bin/bash -c "${pkgs.coreutils}/bin/mkdir -p '${cfg'.dataDir}' '${cfg'.playlistDirectory}'"'';
    };
  };

  mpdSocket = cfg': mkIf cfg'.network.startWhenNeeded {
      Socket = {
        ListenStream = let
          listen =
            if cfg'.network.listenAddress == "any"
            then toString cfg'.network.port
            else "${cfg'.network.listenAddress}:${toString cfg'.network.port}";
        in [ listen "%t/mpd/socket" ];

        Backlog = 5;
        KeepAlive = true;
      };

      Install = {
        WantedBy = [ "sockets.target" ];
      };
  };

in {

  ###### interface

  options = {

    services.mpd = {

      enable = mkEnableOption "MPD, the music player daemon" // {
        default = true;
        example = false;
      };

      daemons = mkOption {
        description = ''
          Each attribute of this option defines a systemd user service that runs
          an MPD instance. All options default to the primary configuration. The
          name of each systemd service is
          <literal>mpd-<replaceable>name</replaceable>.service</literal>,
          where <replaceable>name</replaceable> is the corresponding attribute
          name, except for up to one attribute that may have the
          <literal>default</literal> option set and is named
          <literal>mpd.service</literal>.
        
          For most setups, configuring <literal>daemons.default</literal> is all
          that's needed.
        '';
        default = { default = { }; };
        defaultText = literalExample ''{ default = { }; }'';
        example = literalExample ''
          {
            default = {
              enable = true;
              extraConfig = '''
                audio_output {
                  type "pulse"
                  name "PulseAudio"
                }
              ''';
            };
          }
        '';
        type = types.attrsOf (types.submodule mpdDaemon);
      };

    };

  };

  imports = let
    old = path: [ "services" "mpd" ] ++ path;
    new = path: [ "services" "mpd" "daemons" "default" ] ++ path;
    defaultRename = f: path: f (old path) (new path);
  in [
    (defaultRename mkRenamedOptionModule [ "package" ])
    (defaultRename mkRenamedOptionModule [ "musicDirectory" ])
    (defaultRename mkRenamedOptionModule [ "playlistDirectory" ])
    (defaultRename mkRenamedOptionModule [ "extraConfig" ])
    (defaultRename mkRenamedOptionModule [ "dataDir" ])
    (defaultRename mkRenamedOptionModule [ "network" "listenAddress" ])
    (defaultRename mkRenamedOptionModule [ "network" "port" ])
    (defaultRename mkRenamedOptionModule [ "dbFile" ])
  ];


  ###### implementation

  config = mkIf (cfg.enable && cfg.daemons != { default = { }; }) {

    assertions = let
      defaultCount = count (cfg': cfg'.default) (attrValues cfg.daemons);
    in [
      { assertion = defaultCount <= 1; message = ''
        At most 1 MPD instance can be the default, but ${toString defaultCount} are specified.
      ''; }
    ];

    systemd.user.services = flip mapAttrs' cfg.daemons (_: daemon: {
      name = daemon.serviceName;
      value = mpdService daemon;
    });

    systemd.user.sockets = flip mapAttrs' cfg.daemons (_: daemon: {
      name = daemon.serviceName;
      value = mpdSocket daemon;
    });

  };

}
