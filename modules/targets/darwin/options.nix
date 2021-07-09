{ config, lib, ... }:

with lib;

let
  mkNullableOption = args:
    lib.mkOption (args // {
      type = types.nullOr args.type;
      default = null;
    });

  mkNullableEnableOption = name:
    lib.mkOption {
      type = with types; nullOr bool;
      default = null;
      example = true;
      description = "Whether to enable ${name}.";
    };

  isFloatStr = x:
    isString x && builtins.match "^[+-]?([0-9]*[.])?[0-9]+$" x != null;

  floatStr = mkOptionType {
    name = "float";
    description = "float";
    check = isFloatStr;
    merge = options.mergeOneOption;
  };

  safari = config."com.apple.Safari";
in {
  freeformType = with types; attrsOf (attrsOf anything);

  options = {
    NSGlobalDomain = {
      AppleLanguages = mkNullableOption {
        type = with types; listOf str;
        example = [ "en" ];
        description = "Sets the language to use in the preferred order.";
      };

      AppleLocale = mkNullableOption {
        type = types.str;
        example = "en_US";
        description = "Configures the user locale.";
      };

      AppleMeasurementUnits = mkNullableOption {
        type = types.enum [ "Centimeters" "Inches" ];
        example = "Centimeters";
        description = "Sets the measurement unit.";
      };

      AppleTemperatureUnit = mkNullableOption {
        type = types.enum [ "Celsius" "Fahrenheit" ];
        example = "Celsius";
        description = "Sets the temperature unit.";
      };

      AppleMetricUnits = mkNullableEnableOption "the metric system";

      NSAutomaticCapitalizationEnabled =
        mkNullableEnableOption "automatic captilization";

      NSAutomaticDashSubstitutionEnabled =
        mkNullableEnableOption "smart dashes";

      NSAutomaticPeriodSubstitutionEnabled =
        mkNullableEnableOption "period with double space";

      NSAutomaticQuoteSubstitutionEnabled =
        mkNullableEnableOption "smart quotes";

      NSAutomaticSpellingCorrectionEnabled =
        mkNullableEnableOption "spelling correction";

      AppleEnableMouseSwipeNavigateWithScrolls = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Enables swiping left or right with two fingers to navigate backward or forward. The default is true.
        '';
      };

      AppleEnableSwipeNavigateWithScrolls = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Enables swiping left or right with two fingers to navigate backward or forward. The default is true.
        '';
      };

      AppleFontSmoothing = mkOption {
        type = types.nullOr (types.enum [ 0 1 2 ]);
        default = null;
        description = ''
          Sets the level of font smoothing (sub-pixel font rendering).
        '';
      };

      AppleInterfaceStyle = mkOption {
        type = types.nullOr (types.enum [ "Dark" ]);
        default = null;
        description = ''
          Set to 'Dark' to enable dark mode, or leave unset for normal mod.
        '';
      };

      AppleKeyboardUIMode = mkOption {
        type = types.nullOr (types.enum [ 3 ]);
        default = null;
        description = ''
          Configures the keyboard control behavior.  Mode 3 enables full keyboard control.
        '';
      };

      ApplePressAndHoldEnabled = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Whether to enable the press-and-hold feature.  The default is true.
        '';
      };

      AppleShowAllExtensions = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Whether to show all file extensions in finder. The default is false.
        '';
      };

      AppleShowScrollBars = mkOption {
        type =
          types.nullOr (types.enum [ "WhenScrolling" "Automatic" "Always" ]);
        default = null;
        description = ''
          When to show the scrollbars. Options are 'WhenScrolling', 'Automatic' and 'Always'.
        '';
      };

      NSDisableAutomaticTermination = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Whether to disable the automatic termination of inactive apps.
        '';
      };

      NSDocumentSaveNewDocumentsToCloud = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Whether to save new documents to iCloud by default.  The default is true.
        '';
      };

      NSNavPanelExpandedStateForSaveMode = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Whether to use expanded save panel by default.  The default is false.
        '';
      };

      NSNavPanelExpandedStateForSaveMode2 = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Whether to use expanded save panel by default.  The default is false.
        '';
      };

      NSTableViewDefaultSizeMode = mkOption {
        type = types.nullOr (types.enum [ 1 2 3 ]);
        default = null;
        description = ''
          Sets the size of the finder sidebar icons: 1 (small), 2 (medium) or 3 (large). The default is 3.
        '';
      };

      NSTextShowsControlCharacters = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Whether to display ASCII control characters using caret notation in standard text views. The default is false.
        '';
      };

      NSUseAnimatedFocusRing = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Whether to enable the focus ring animation. The default is true.
        '';
      };

      NSScrollAnimationEnabled = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Whether to enable smooth scrolling. The default is true.
        '';
      };

      NSWindowResizeTime = mkOption {
        type = types.nullOr floatStr;
        default = null;
        example = "0.20";
        description = ''
          Sets the speed speed of window resizing. The default is given in the example.
        '';
      };

      InitialKeyRepeat = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = ''
          # Apple menu > System Preferences > Keyboard
          If you press and hold certain keyboard keys when in a text area, the key’s character begins to repeat.
          For example, the Delete key continues to remove text for as long as you hold it down.

          This sets how long you must hold down the key before it starts repeating.
        '';
      };

      KeyRepeat = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = ''
          # Apple menu > System Preferences > Keyboard
          If you press and hold certain keyboard keys when in a text area, the key’s character begins to repeat.
          For example, the Delete key continues to remove text for as long as you hold it down.

          This sets how fast it repeats once it starts.
        '';
      };

      PMPrintingExpandedStateForPrint = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Whether to use the expanded print panel by default. The default is false.
        '';
      };

      PMPrintingExpandedStateForPrint2 = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Whether to use the expanded print panel by default. The default is false.
        '';
      };

      "com.apple.keyboard.fnState" = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Use F1, F2, etc. keys as standard function keys.
        '';
      };

      "com.apple.mouse.tapBehavior" = mkOption {
        type = types.nullOr (types.enum [ 1 ]);
        default = null;
        description = ''
          Configures the trackpad tap behavior.  Mode 1 enables tap to click.
        '';
      };

      "com.apple.sound.beep.volume" = mkOption {
        type = types.nullOr floatStr;
        default = null;
        description = ''
          # Apple menu > System Preferences > Sound
          Sets the beep/alert volume level from 0.000 (muted) to 1.000 (100% volume).

          75% = 0.7788008
          50% = 0.6065307
          25% = 0.4723665
        '';
      };

      "com.apple.sound.beep.feedback" = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = ''
          # Apple menu > System Preferences > Sound
          Make a feedback sound when the system volume changed. This setting accepts
          the integers 0 or 1. Defaults to 1.
        '';
      };

      "com.apple.trackpad.enableSecondaryClick" = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Whether to enable trackpad secondary click.  The default is true.
        '';
      };

      "com.apple.trackpad.trackpadCornerClickBehavior" = mkOption {
        type = types.nullOr (types.enum [ 1 ]);
        default = null;
        description = ''
          Configures the trackpad corner click behavior.  Mode 1 enables right click.
        '';
      };

      "com.apple.trackpad.scaling" = mkOption {
        type = types.nullOr floatStr;
        default = null;
        description = ''
          Configures the trackpad tracking speed (0 to 3).  The default is "1".
        '';
      };

      "com.apple.springing.enabled" = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Whether to enable spring loading (expose) for directories.
        '';
      };

      "com.apple.springing.delay" = mkOption {
        type = types.nullOr floatStr;
        default = null;
        example = "1.0";
        description = ''
          Set the spring loading delay for directories. The default is given in the example.
        '';
      };

      "com.apple.swipescrolldirection" = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Whether to enable "Natural" scrolling direction.  The default is true.
        '';
      };

      _HIHideMenuBar = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Whether to autohide the menu bar.  The default is false.
        '';
      };
    };

    "com.apple.desktopservices" = {
      DSDontWriteNetworkStores = mkNullableOption {
        type = types.bool;
        example = false;
        description = ''
          Disable use of <filename>.DS_Store</filename> files on network shares.
          See <link xlink:href="https://support.apple.com/en-us/HT208209">the
          official article</link> for more info.
        '';
      };
      DSDontWriteUSBStores = mkNullableOption {
        type = types.bool;
        example = false;
        description = ''
          Disable use of <filename>.DS_Store</filename> files on thumb drives.
        '';
      };
    };

    "com.apple.dock" = {
      tilesize = mkNullableOption {
        type = types.int;
        example = 64;
        description = "Sets the size of the dock.";
      };
      size-immutable = mkNullableEnableOption "locking of the dock size";
      expose-group-apps = mkNullableEnableOption
        "grouping of windows by application in Mission Control";
    };

    "com.apple.menuextra.battery".ShowPercent = mkNullableOption {
      type = types.enum [ "YES" "NO" ];
      example = "NO";
      description = "Whether to show battery percentage in the menu bar.";
    };

    "com.apple.Safari" = {
      AutoOpenSafeDownloads =
        mkNullableEnableOption "opening of downloaded files";
      AutoFillPasswords =
        mkNullableEnableOption "autofill of usernames and passwords";
      AutoFillCreditCardData =
        mkNullableEnableOption "autofill of credit card numbers";
      IncludeDevelopMenu =
        mkNullableEnableOption ''"Develop" menu in the menu bar'';
      ShowOverlayStatusBar = mkNullableEnableOption "status bar";

      WebKitDeveloperExtrasEnabledPreferenceKey = mkNullableOption {
        type = types.bool;
        description = ''
          Configures the web inspector.

          <warning>
            <para>
              Instead of setting this option directly, set
              <option>IncludeDevelopMenu</option> instead.
            </para>
          </warning>
        '';
      };
      "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" =
        mkNullableOption {
          type = types.bool;
          description = ''
            Configures the web inspector.

            <warning>
              <para>
                Instead of setting this option directly, set
                <option>IncludeDevelopMenu</option> instead.
              </para>
            </warning>
          '';
        };
    };

    "com.googlecode.iterm2" = {
      AddNewTabAtEndOfTabs = mkNullableEnableOption
        "placement of new tabs at the end of the tab bar";

      AlternateMouseScroll = mkNullableEnableOption
        "arrow keys when scrolling in alternate screen mode";

      CopySelection =
        mkNullableEnableOption "copy to clipboard upon selecting text";

      OpenTmuxWindowsIn = mkNullableOption {
        type = types.int;
        example = 2;
        description = ''
          Configures how to restore tmux windows when attaching to a session.

          <variablelist><title>Possible Values</title>
            <varlistentry>
              <term><literal>0</literal></term>
              <listitem><para>Native windows</para></listitem>
            </varlistentry>
            <varlistentry>
              <term><literal>1</literal></term>
              <listitem><para>Native tabs in a new window</para></listitem>
            </varlistentry>
            <varlistentry>
              <term><literal>2</literal></term>
              <listitem><para>Tabs in the attaching window</para></listitem>
            </varlistentry>
          </variablelist>
        '';
      };

      ExperimentalKeyHandling = mkNullableEnableOption
        "experimental key handling for AquaSKK compatibility";
    };
  };

  config = {
    "com.apple.Safari" = mkIf (safari.IncludeDevelopMenu != null) {
      WebKitDeveloperExtrasEnabledPreferenceKey = safari.IncludeDevelopMenu;
      "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" =
        safari.IncludeDevelopMenu;
    };
  };
}
