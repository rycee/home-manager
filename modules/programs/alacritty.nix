{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.alacritty;
  yamlFormat = pkgs.formats.yaml { };
  CSIuKeyBindings = [
    # http://www.leonerd.org.uk/hacks/fixterms/
    # Avoid to override default key-bindings
    #
    # Control + Shift + B ⇒ SearchBackward
    # Control + Shift + C ⇒ Copy
    # Control + Shift + F ⇒ SearchForward
    # Control + Shift + V ⇒ Paste
    # Control + 0 ⇒ ResetFontSize

    # ##############################
    # Non-Captured CTRL Combinations
    # ##############################
    {
      key = "H";
      mods = "Control";
      chars = "\\x1b[104;5u";
    }
    {
      key = "I";
      mods = "Control";
      chars = "\\x1b[105;5u";
    }
    {
      key = "J";
      mods = "Control";
      chars = "\\x1b[106;5u";
    }
    {
      key = "M";
      mods = "Control";
      chars = "\\x1b[109;5u";
    }
    {
      key = "Return";
      mods = "Control";
      chars = "\\x1b[13;5u";
    }
    {
      key = "Slash";
      mods = "Control";
      chars = "\\x1b[47;5u";
    }

    # ######################################
    # Non-Captured CTRL + SHIFT Combinations
    # ######################################
    {
      key = "51";
      mods = "Control|Shift";
      chars = "\\x1b[60;5u";
    } # Less
    {
      key = "52";
      mods = "Control|Shift";
      chars = "\\x1b[62;5u";
    } # Greater

    {
      key = "A";
      mods = "Control|Shift";
      chars = "\\x1b[65;5u";
    }
    # Control + B ⇒ SearchBackward
    # { key = "B"; mods = "Control|Shift"; chars = "\\x1b[66;5u"; }
    # Control + C ⇒ Copy
    # { key = "C"; mods = "Control|Shift"; chars = "\\x1b[67;5u"; }
    {
      key = "D";
      mods = "Control|Shift";
      chars = "\\x1b[68;5u";
    }
    {
      key = "E";
      mods = "Control|Shift";
      chars = "\\x1b[69;5u";
    }
    # Control + F ⇒ SearchForward
    # { key = "F"; mods = "Control|Shift"; chars = "\\x1b[70;5u"; }
    {
      key = "G";
      mods = "Control|Shift";
      chars = "\\x1b[71;5u";
    }
    {
      key = "H";
      mods = "Control|Shift";
      chars = "\\x1b[72;5u";
    }
    {
      key = "I";
      mods = "Control|Shift";
      chars = "\\x1b[73;5u";
    }
    {
      key = "J";
      mods = "Control|Shift";
      chars = "\\x1b[74;5u";
    }
    {
      key = "K";
      mods = "Control|Shift";
      chars = "\\x1b[75;5u";
    }
    {
      key = "L";
      mods = "Control|Shift";
      chars = "\\x1b[76;5u";
    }
    {
      key = "M";
      mods = "Control|Shift";
      chars = "\\x1b[77;5u";
    }
    {
      key = "N";
      mods = "Control|Shift";
      chars = "\\x1b[78;5u";
    }
    {
      key = "O";
      mods = "Control|Shift";
      chars = "\\x1b[79;5u";
    }
    {
      key = "P";
      mods = "Control|Shift";
      chars = "\\x1b[80;5u";
    }
    {
      key = "Q";
      mods = "Control|Shift";
      chars = "\\x1b[81;5u";
    }
    {
      key = "R";
      mods = "Control|Shift";
      chars = "\\x1b[82;5u";
    }
    {
      key = "S";
      mods = "Control|Shift";
      chars = "\\x1b[83;5u";
    }
    {
      key = "T";
      mods = "Control|Shift";
      chars = "\\x1b[84;5u";
    }
    {
      key = "U";
      mods = "Control|Shift";
      chars = "\\x1b[85;5u";
    }
    # Control + V ⇒ Paste
    # {   key = "V";  mods = "Control|Shift"; chars = "\\x1b[86;5u"; }
    {
      key = "W";
      mods = "Control|Shift";
      chars = "\\x1b[87;5u";
    }
    {
      key = "X";
      mods = "Control|Shift";
      chars = "\\x1b[88;5u";
    }
    {
      key = "Y";
      mods = "Control|Shift";
      chars = "\\x1b[89;5u";
    }
    {
      key = "Z";
      mods = "Control|Shift";
      chars = "\\x1b[90;5u";
    }

    # ################################
    # Non-Captured NumKey Combinations
    # ################################
    # Control + 0 ⇒ ResetFontSize
    # { key = "Key0"; mods = "Control"; chars = "\\x1b[48;5u"; }
    {
      key = "Key1";
      mods = "Control";
      chars = "\\x1b[49;5u";
    }
    {
      key = "Key2";
      mods = "Control";
      chars = "\\x1b[50;5u";
    }
    {
      key = "Key3";
      mods = "Control";
      chars = "\\x1b[51;5u";
    }
    {
      key = "Key4";
      mods = "Control";
      chars = "\\x1b[52;5u";
    }
    {
      key = "Key5";
      mods = "Control";
      chars = "\\x1b[53;5u";
    }
    {
      key = "Key6";
      mods = "Control";
      chars = "\\x1b[54;5u";
    }
    {
      key = "Key7";
      mods = "Control";
      chars = "\\x1b[55;5u";
    }
    {
      key = "Key8";
      mods = "Control";
      chars = "\\x1b[56;5u";
    }
    {
      key = "Key9";
      mods = "Control";
      chars = "\\x1b[57;5u";
    }

    {
      key = "Key0";
      mods = "Control|Shift";
      chars = "\\x1b[48;6u";
    }
    {
      key = "Key1";
      mods = "Control|Shift";
      chars = "\\x1b[49;6u";
    }
    {
      key = "Key2";
      mods = "Control|Shift";
      chars = "\\x1b[50;6u";
    }
    {
      key = "Key3";
      mods = "Control|Shift";
      chars = "\\x1b[51;6u";
    }
    {
      key = "Key4";
      mods = "Control|Shift";
      chars = "\\x1b[52;6u";
    }
    {
      key = "Key5";
      mods = "Control|Shift";
      chars = "\\x1b[53;6u";
    }
    {
      key = "Key6";
      mods = "Control|Shift";
      chars = "\\x1b[54;6u";
    }
    {
      key = "Key7";
      mods = "Control|Shift";
      chars = "\\x1b[55;6u";
    }
    {
      key = "Key8";
      mods = "Control|Shift";
      chars = "\\x1b[56;6u";
    }
    {
      key = "Key9";
      mods = "Control|Shift";
      chars = "\\x1b[57;6u";
    }
  ];
in {
  options = {
    programs.alacritty = {
      enable = mkEnableOption "Alacritty";

      package = mkOption {
        type = types.package;
        default = pkgs.alacritty;
        defaultText = literalExample "pkgs.alacritty";
        description = "The Alacritty package to install.";
      };

      CSIuSupport = mkEnableOption "Enable CSIu support";

      settings = mkOption {
        type = yamlFormat.type;
        default = { };
        example = literalExample ''
          {
            window.dimensions = {
              lines = 3;
              columns = 200;
            };
            key_bindings = [
              {
                key = "K";
                mods = "Control";
                chars = "\\x0c";
              }
            ];
          }
        '';
        description = ''
          Configuration written to
          <filename>~/.config/alacritty/alacritty.yml</filename>. See
          <link xlink:href="https://github.com/jwilm/alacritty/blob/master/alacritty.yml"/>
          for the default configuration.
        '';
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      home.packages = [ cfg.package ];

      programs.alacritty.settings.key_bindings =
        mkIf cfg.CSIuSupport CSIuKeyBindings;

      xdg.configFile."alacritty/alacritty.yml" = mkIf (cfg.settings != { }) {
        # TODO: Replace by the generate function but need to figure out how to
        # handle the escaping first.
        #
        # source = yamlFormat.generate "alacritty.yml" cfg.settings;

        text =
          replaceStrings [ "\\\\" ] [ "\\" ] (builtins.toJSON cfg.settings);
      };
    })
  ];
}
