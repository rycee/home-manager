{ config, options, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.gpg-agent;
  gpgPkg = config.programs.gpg.package;

  homedir = config.programs.gpg.homedir;

  gpgInitStr = ''
    GPG_TTY="$(tty)"
    export GPG_TTY
  '' + optionalString cfg.enableSshSupport
    "${gpgPkg}/bin/gpg-connect-agent updatestartuptty /bye > /dev/null";

  # mimic `gpgconf` output for use in `systemd` unit definitions.
  # we cannot use `gpgconf` directly because it heavily depends on system
  # state, but we need the values at build time. original:
  # https://github.com/gpg/gnupg/blob/c6702d77d936b3e9d91b34d8fdee9599ab94ee1b/common/homedir.c#L672-L681
  gpgconf = dir:
    let
      f = pkgs.runCommand dir { } ''
        PATH=${pkgs.coreutils}/bin:${pkgs.xxd}/bin:$PATH

        if [[ ${homedir} = ${options.programs.gpg.homedir.default} ]]
        then
          echo -n "%t/gnupg/${dir}" > $out
        else
          hash=$(echo -n ${homedir} | sha1sum -b | xxd -r -p | base32 | \
                 cut -c -24 | tr '[:upper:]' '[:lower:]' | \
                 tr abcdefghijklmnopqrstuvwxyz234567 \
                    ybndrfg8ejkmcpqxot1uwisza345h769)
           echo -n "%t/gnupg/d.$hash/${dir}" > $out
        fi
      '';
    in "${builtins.readFile f}";

in {
  meta.maintainers = [ maintainers.rycee ];

  options = {
    services.gpg-agent = {
      enable = mkEnableOption "GnuPG private key agent";

      defaultCacheTtl = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = ''
          Set the time a cache entry is valid to the given number of
          seconds.
        '';
      };

      defaultCacheTtlSsh = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = ''
          Set the time a cache entry used for SSH keys is valid to the
          given number of seconds.
        '';
      };

      maxCacheTtl = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = ''
          Set the maximum time a cache entry is valid to n seconds. After this
          time a cache entry will be expired even if it has been accessed
          recently or has been set using gpg-preset-passphrase. The default is
          2 hours (7200 seconds).
        '';
      };

      maxCacheTtlSsh = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = ''
          Set the maximum time a cache entry used for SSH keys is valid to n
          seconds. After this time a cache entry will be expired even if it has
          been accessed recently or has been set using gpg-preset-passphrase.
          The default is 2 hours (7200 seconds).
        '';
      };

      enableSshSupport = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to use the GnuPG key agent for SSH keys.
        '';
      };

      sshKeys = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = ''
          Which GPG keys (by keygrip) to expose as SSH keys.
        '';
      };

      enableExtraSocket = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable extra socket of the GnuPG key agent (useful for GPG
          Agent forwarding).
        '';
      };

      verbose = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to produce verbose output.
        '';
      };

      grabKeyboardAndMouse = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Tell the pinentry to grab the keyboard and mouse. This
          option should in general be used to avoid X-sniffing
          attacks. When disabled, this option passes
          <option>no-grab</option> setting to gpg-agent.
        '';
      };

      enableScDaemon = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Make use of the scdaemon tool. This option has the effect of
          enabling the ability to do smartcard operations. When
          disabled, this option passes
          <option>disable-scdaemon</option> setting to gpg-agent.
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        example = ''
          allow-emacs-pinentry
          allow-loopback-pinentry
        '';
        description = ''
          Extra configuration lines to append to the gpg-agent
          configuration file.
        '';
      };

      pinentryFlavor = mkOption {
        type = types.nullOr (types.enum pkgs.pinentry.flavors);
        example = "gnome3";
        default = "gtk2";
        description = ''
          Which pinentry interface to use. If not
          <literal>null</literal>, it sets
          <option>pinentry-program</option> in
          <filename>gpg-agent.conf</filename>. Beware that
          <literal>pinentry-gnome3</literal> may not work on non-Gnome
          systems. You can fix it by adding the following to your
          system configuration:
          <programlisting language="nix">
          services.dbus.packages = [ pkgs.gcr ];
          </programlisting>
          For this reason, the default is <literal>gtk2</literal> for
          now.
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.file."${homedir}/gpg-agent.conf".text = concatStringsSep "\n"
        (optional (cfg.enableSshSupport) "enable-ssh-support"
          ++ optional (!cfg.grabKeyboardAndMouse) "no-grab"
          ++ optional (!cfg.enableScDaemon) "disable-scdaemon"
          ++ (optional (cfg.defaultCacheTtl != null)
            "default-cache-ttl ${toString cfg.defaultCacheTtl}")
          ++ (optional (cfg.defaultCacheTtlSsh != null)
            "default-cache-ttl-ssh ${toString cfg.defaultCacheTtlSsh}")
          ++ (optional (cfg.maxCacheTtl != null)
            "max-cache-ttl ${toString cfg.maxCacheTtl}")
          ++ (optional (cfg.maxCacheTtlSsh != null)
            "max-cache-ttl-ssh ${toString cfg.maxCacheTtlSsh}")
          ++ (optional (cfg.pinentryFlavor != null) "pinentry-program ${
              pkgs.pinentry.${cfg.pinentryFlavor}
            }/bin/pinentry") ++ [ cfg.extraConfig ]);

      home.sessionVariables = optionalAttrs cfg.enableSshSupport {
        SSH_AUTH_SOCK = "$(${gpgPkg}/bin/gpgconf --list-dirs agent-ssh-socket)";
      };

      programs.bash.initExtra = gpgInitStr;
      programs.zsh.initExtra = gpgInitStr;
      programs.fish.interactiveShellInit = ''
        set -gx GPG_TTY (tty)
      '';
    }

    (mkIf (cfg.sshKeys != null) {
      # Trailing newlines are important
      home.file."${homedir}/sshcontrol".text =
        (concatStringsSep "\n" cfg.sshKeys) + "\n";
    })

    # The systemd units below are direct translations of the
    # descriptions in the
    #
    #   ${gpgPkg}/share/doc/gnupg/examples/systemd-user
    #
    # directory.
    {
      systemd.user.services.gpg-agent = {
        Unit = {
          Description = "GnuPG cryptographic agent and passphrase cache";
          Documentation = "man:gpg-agent(1)";
          Requires = "gpg-agent.socket";
          After = "gpg-agent.socket";
          # This is a socket-activated service:
          RefuseManualStart = true;
        };

        Service = {
          ExecStart = "${gpgPkg}/bin/gpg-agent --supervised"
            + optionalString cfg.verbose " --verbose";
          ExecReload = "${gpgPkg}/bin/gpgconf --reload gpg-agent";
          Environment = "GNUPGHOME=${homedir}";
        };
      };

      systemd.user.sockets.gpg-agent = {
        Unit = {
          Description = "GnuPG cryptographic agent and passphrase cache";
          Documentation = "man:gpg-agent(1)";
        };

        Socket = {
          ListenStream = gpgconf "S.gpg-agent";
          FileDescriptorName = "std";
          SocketMode = "0600";
          DirectoryMode = "0700";
        };

        Install.WantedBy = [ "sockets.target" ];
      };
    }

    (mkIf cfg.enableSshSupport {
      systemd.user.sockets.gpg-agent-ssh = {
        Unit = {
          Description = "GnuPG cryptographic agent (ssh-agent emulation)";
          Documentation =
            "man:gpg-agent(1) man:ssh-add(1) man:ssh-agent(1) man:ssh(1)";
        };

        Socket = {
          ListenStream = gpgconf "S.gpg-agent.ssh";
          FileDescriptorName = "ssh";
          Service = "gpg-agent.service";
          SocketMode = "0600";
          DirectoryMode = "0700";
        };

        Install.WantedBy = [ "sockets.target" ];
      };
    })

    (mkIf cfg.enableExtraSocket {
      systemd.user.sockets.gpg-agent-extra = {
        Unit = {
          Description =
            "GnuPG cryptographic agent and passphrase cache (restricted)";
          Documentation = "man:gpg-agent(1) man:ssh(1)";
        };

        Socket = {
          ListenStream = gpgconf "S.gpg-agent.extra";
          FileDescriptorName = "extra";
          Service = "gpg-agent.service";
          SocketMode = "0600";
          DirectoryMode = "0700";
        };

        Install.WantedBy = [ "sockets.target" ];
      };
    })
  ]);
}
