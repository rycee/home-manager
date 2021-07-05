{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.polybar;

  eitherStrBoolIntList = with types;
    either str (either bool (either int (listOf str)));

  # Convert a key/val pair to the insane format that polybar uses.
  # Each input key/val pair may return several output key/val pairs.
  convertPolybarKeyVal = key: val:
    # Convert { foo = [ "a" "b" ]; }
    # to {
    #   foo-0 = "a";
    #   foo-1 = "b";
    # }
    if isList val then
      concatLists (imap0 (i: convertPolybarKeyVal "${key}-${toString i}") val)
      # Convert {
      #   foo.text = "a";
      #   foo.font = 1;
      # } to {
      #   foo = "a";
      #   foo-font = 1;
      # }
    else if isAttrs val && !lib.isDerivation val then
      concatLists (mapAttrsToList
        (k: convertPolybarKeyVal (if k == "text" then key else "${key}-${k}"))
        val)
      # Base case
    else
      [ (nameValuePair key val) ];

  convertPolybarSection = _: attrs:
    listToAttrs (concatLists (mapAttrsToList convertPolybarKeyVal attrs));

  # Converts an attrset to INI text, quoting values as expected by polybar.
  # This does no more fancy conversion.
  toPolybarIni = generators.toINI {
    mkKeyValue = key: value:
      let
        quoted = v:
          if hasPrefix " " v || hasSuffix " " v then ''"${v}"'' else v;

        value' = if isBool value then
          (if value then "true" else "false")
        else if (isString value && key != "include-file") then
          quoted value
        else
          toString value;
      in "${key}=${value'}";
  };

  configFile = pkgs.writeText "polybar.conf" ''
    ${toPolybarIni cfg.config}
    ${toPolybarIni (mapAttrs convertPolybarSection cfg.settings)}
    ${cfg.extraConfig}
  '';

in {
  options = {
    services.polybar = {
      enable = mkEnableOption "Polybar status bar";

      package = mkOption {
        type = types.package;
        default = pkgs.polybar;
        defaultText = literalExample "pkgs.polybar";
        description = "Polybar package to install.";
        example = literalExample ''
          pkgs.polybar.override {
            i3GapsSupport = true;
            alsaSupport = true;
            iwSupport = true;
            githubSupport = true;
          }
        '';
      };

      config = mkOption {
        type = types.coercedTo types.path
          (p: { "section/base" = { include-file = "${p}"; }; })
          (types.attrsOf (types.attrsOf eitherStrBoolIntList));
        description = ''
          Polybar configuration. Can be either path to a file, or set of attributes
          that will be used to create the final configuration.
          See also <option>services.polybar.settings</option> for a more nix-friendly format.
        '';
        default = { };
        example = literalExample ''
          {
            "bar/top" = {
              monitor = "\''${env:MONITOR:eDP1}";
              width = "100%";
              height = "3%";
              radius = 0;
              modules-center = "date";
            };

            "module/date" = {
              type = "internal/date";
              internal = 5;
              date = "%d.%m.%y";
              time = "%H:%M";
              label = "%time%  %date%";
            };
          }
        '';
      };

      settings = mkOption {
        type = types.attrsOf types.attrs;
        description = ''
          Polybar configuration. This takes a nix attrset and converts it to the
          strange data format that polybar uses.
          Each entry will be converted to a section in the output file.
          Several things are treated specially: nested keys are converted
          to dash-separated keys; the special <literal>text</literal> key is ignored as a nested key,
          to allow mixing different levels of nesting; and lists are converted to
          polybar's <literal>foo-0, foo-1, ...</literal> format.
          </para><para>
          For example:
          <programlisting language="nix">
          "module/volume" = {
            type = "internal/pulseaudio";
            format.volume = "&lt;ramp-volume&gt; &lt;label-volume&gt;";
            label.muted.text = "🔇";
            label.muted.foreground = "#666";
            ramp.volume = ["🔈" "🔉" "🔊"];
            click.right = "pavucontrol &amp;";
          }
          </programlisting>
          becomes:
          <programlisting language="ini">
          [module/volume]
          type=internal/pulseaudio
          format-volume=&lt;ramp-volume&gt; &lt;label-volume&gt;
          label-muted=🔇
          label-muted-foreground=#666
          ramp-volume-0=🔈
          ramp-volume-1=🔉
          ramp-volume-2=🔊
          click-right=pavucontrol &amp;
          </programlisting>
        '';
        default = { };
        example = literalExample ''
          {
            "module/volume" = {
              type = "internal/pulseaudio";
              format.volume = "<ramp-volume> <label-volume>";
              label.muted.text = "🔇";
              label.muted.foreground = "#666";
              ramp.volume = ["🔈" "🔉" "🔊"];
              click.right = "pavucontrol &";
            };
          }
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        description = "Additional configuration to add.";
        default = "";
        example = ''
          [module/date]
          type = internal/date
          interval = 5
          date = "%d.%m.%y"
          time = %H:%M
          format-prefix-foreground = \''${colors.foreground-alt}
          label = %time%  %date%
        '';
      };

      script = mkOption {
        type = types.lines;
        description = ''
          This script will be used to start the polybars.
          Set all necessary environment variables here and start all bars.
          It can be assumed that <command>polybar</command> executable is in the <envar>PATH</envar>.

          Note, this script must start all bars in the background and then terminate.
        '';
        example = "polybar bar &";
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    xdg.configFile."polybar/config".source = configFile;

    systemd.user.services.polybar = {
      Unit = {
        Description = "Polybar status bar";
        PartOf = [ "tray.target" ];
        X-Restart-Triggers =
          [ "${config.xdg.configFile."polybar/config".source}" ];
      };

      Service = {
        Type = "forking";
        Environment =
          "PATH=\${PATH:+:}${cfg.package}/bin:/run/wrappers/bin NIX_PATH=\${NIX_PATH:+:}";
        ExecStart =
          let scriptPkg = pkgs.writeShellScriptBin "polybar-start" cfg.script;
          in "${scriptPkg}/bin/polybar-start";
        Restart = "on-failure";
      };

      Install = { WantedBy = [ "tray.target" ]; };
    };
  };

}
