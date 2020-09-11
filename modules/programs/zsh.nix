{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.zsh;

  relToDotDir = file: (optionalString (cfg.dotDir != null) (cfg.dotDir + "/")) + file;

  pluginsDir = if cfg.dotDir != null then
    relToDotDir "plugins" else ".zsh/plugins";

  envVarsStr = config.lib.zsh.exportAll cfg.sessionVariables;
  localVarsStr = config.lib.zsh.defineAll cfg.localVariables;

  aliasesStr = concatStringsSep "\n" (
    mapAttrsToList (k: v: "alias ${k}=${lib.escapeShellArg v}") cfg.shellAliases
  );

  globalAliasesStr = concatStringsSep "\n" (
    mapAttrsToList (k: v: "alias -g ${k}=${lib.escapeShellArg v}") cfg.shellGlobalAliases
  );

  zdotdir = "$HOME/" + cfg.dotDir;

  bindkeyCommands = {
    emacs = "bindkey -e";
    viins = "bindkey -v";
    vicmd = "bindkey -a";
  };

  stateVersion = config.home.stateVersion;

  completionModule = types.submodule ({ config, ... }: {
    options = {
      enable = mkOption {
        default = true;
        description = ''
          Whether to enable zsh completion. Don't forget to add
          <programlisting language="nix">
            environment.pathsToLink = [ "/share/zsh" ];
          </programlisting>
          to your system configuration to get completion for system packages (e.g. systemd).
        '';
        type = types.bool;
      };

      path = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = literalExample ''"''${config.xdg.cacheHome}/zsh/zcompdump-$ZSH_VERSION"'';
        description = "compinit dump location";
      };
    };
  });

  historyModule = types.submodule ({ config, ... }: {
    options = {
      size = mkOption {
        type = types.int;
        default = 10000;
        description = "Number of history lines to keep.";
      };

      save = mkOption {
        type = types.int;
        defaultText = 10000;
        default = config.size;
        description = "Number of history lines to save.";
      };

      path = mkOption {
        type = types.str;
        default = if versionAtLeast stateVersion "20.03"
          then "$HOME/.zsh_history"
          else relToDotDir ".zsh_history";
        example = literalExample ''"''${config.xdg.dataHome}/zsh/zsh_history"'';
        description = "History file location";
      };

      ignoreDups = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Do not enter command lines into the history list
          if they are duplicates of the previous event.
        '';
      };

      ignoreSpace = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Do not enter command lines into the history list
          if the first character is a space.
        '';
      };

      expireDuplicatesFirst = mkOption {
        type = types.bool;
        default = false;
        description = "Expire duplicates first.";
      };

      extended = mkOption {
        type = types.bool;
        default = false;
        description = "Save timestamp into the history file.";
      };

      share = mkOption {
        type = types.bool;
        default = true;
        description = "Share command history between zsh sessions.";
      };
    };
  });

  pluginModule = types.submodule ({ config, ... }: {
    options = {
      src = mkOption {
        type = types.path;
        description = ''
          Path to the plugin folder.

          Will be added to <envar>fpath</envar> and <envar>PATH</envar>.
        '';
      };

      name = mkOption {
        type = types.str;
        description = ''
          The name of the plugin.

          Don't forget to add <option>file</option>
          if the script name does not follow convention.
        '';
      };

      file = mkOption {
        type = types.str;
        description = "The plugin script to source.";
      };
    };

    config.file = mkDefault "${config.name}.plugin.zsh";
  });

  ohMyZshModule = types.submodule {
    options = {
      enable = mkEnableOption "oh-my-zsh";

      plugins = mkOption {
        default = [];
        example = [ "git" "sudo" ];
        type = types.listOf types.str;
        description = ''
          List of oh-my-zsh plugins
        '';
      };

      custom = mkOption {
        default = "";
        type = types.str;
        example = "$HOME/my_customizations";
        description = ''
          Path to a custom oh-my-zsh package to override config of
          oh-my-zsh. See <link xlink:href="https://github.com/robbyrussell/oh-my-zsh/wiki/Customization"/>
          for more information.
        '';
      };

      theme = mkOption {
        default = "";
        example = "robbyrussell";
        type = types.str;
        description = ''
          Name of the theme to be used by oh-my-zsh.
        '';
      };

      extraConfig = mkOption {
        default = "";
        example = ''
          zstyle :omz:plugins:ssh-agent identities id_rsa id_rsa2 id_github
        '';
        type = types.lines;
        description = ''
          Extra settings for plugins.
        '';
      };
    };
  };

in

{
  options = {
    programs.zsh = {
      enable = mkEnableOption "Z shell (Zsh)";

      autocd = mkOption {
        default = null;
        description = ''
          Automatically enter into a directory if typed directly into shell.
        '';
        type = types.nullOr types.bool;
      };

      cdpath = mkOption {
        default = [];
        description = ''
          List of paths to autocomplete calls to `cd`.
        '';
        type = types.listOf types.str;
      };

      dotDir = mkOption {
        default = null;
        example = ".config/zsh";
        description = ''
          Directory where the zsh configuration and more should be located,
          relative to the users home directory. The default is the home
          directory.
        '';
        type = types.nullOr types.str;
      };

      shellAliases = mkOption {
        default = {};
        example = literalExample ''
          {
            ll = "ls -l";
            ".." = "cd ..";
          }
        '';
        description = ''
          An attribute set that maps aliases (the top level attribute names in
          this option) to command strings or directly to build outputs.
        '';
        type = types.attrsOf types.str;
      };

      shellGlobalAliases = mkOption {
        default = {};
        example = literalExample ''
          {
            UUID = "$(uuidgen | tr -d \\n)";
            G = "| grep";
          }
        '';
        description = ''
          Similar to <varname><link linkend="opt-programs.zsh.shellAliases">opt-programs.zsh.shellAliases</link></varname>,
          but are substituted anywhere on a line.
        '';
        type = types.attrsOf types.str;
      };

      completion = mkOption {
        type = completionModule;
        default = {};
        description = ''
          Options related to command completion configuration.
        '';
      };

      enableAutosuggestions = mkOption {
        default = false;
        description = "Enable zsh autosuggestions";
      };

      history = mkOption {
        type = historyModule;
        default = {};
        description = "Options related to commands history configuration.";
      };

      defaultKeymap = mkOption {
        type = types.nullOr (types.enum (attrNames bindkeyCommands));
        default = null;
        example = "emacs";
        description = "The default base keymap to use.";
      };

      sessionVariables = mkOption {
        default = {};
        type = types.attrs;
        example = { MAILCHECK = 30; };
        description = "Environment variables that will be set for zsh session.";
      };

      initExtraBeforeCompInit = mkOption {
        default = "";
        type = types.lines;
        description = "Extra commands that should be added to <filename>.zshrc</filename> before compinit.";
      };

      initExtra = mkOption {
        default = "";
        type = types.lines;
        description = "Extra commands that should be added to <filename>.zshrc</filename>.";
      };

      envExtra = mkOption {
        default = "";
        type = types.lines;
        description = "Extra commands that should be added to <filename>.zshenv</filename>.";
      };

      profileExtra = mkOption {
        default = "";
        type = types.lines;
        description = "Extra commands that should be added to <filename>.zprofile</filename>.";
      };

      loginExtra = mkOption {
        default = "";
        type = types.lines;
        description = "Extra commands that should be added to <filename>.zlogin</filename>.";
      };

      logoutExtra = mkOption {
        default = "";
        type = types.lines;
        description = "Extra commands that should be added to <filename>.zlogout</filename>.";
      };

      plugins = mkOption {
        type = types.listOf pluginModule;
        default = [];
        example = literalExample ''
          [
            {
              # will source zsh-autosuggestions.plugin.zsh
              name = "zsh-autosuggestions";
              src = pkgs.fetchFromGitHub {
                owner = "zsh-users";
                repo = "zsh-autosuggestions";
                rev = "v0.4.0";
                sha256 = "0z6i9wjjklb4lvr7zjhbphibsyx51psv50gm07mbb0kj9058j6kc";
              };
            }
            {
              name = "enhancd";
              file = "init.sh";
              src = pkgs.fetchFromGitHub {
                owner = "b4b4r07";
                repo = "enhancd";
                rev = "v2.2.1";
                sha256 = "0iqa9j09fwm6nj5rpip87x3hnvbbz9w9ajgm6wkrd5fls8fn8i5g";
              };
            }
          ]
        '';
        description = "Plugins to source in <filename>.zshrc</filename>.";
      };

      oh-my-zsh = mkOption {
        type = ohMyZshModule;
        default = {};
        description = "Options to configure oh-my-zsh.";
      };

      localVariables = mkOption {
        type = types.attrs;
        default = {};
        example = { POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=["dir" "vcs"]; };
        description = ''
          Extra local variables defined at the top of <filename>.zshrc</filename>.
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf (cfg.envExtra != "") {
      home.file."${relToDotDir ".zshenv"}".text = cfg.envExtra;
    })

    (mkIf (cfg.profileExtra != "") {
      home.file."${relToDotDir ".zprofile"}".text = cfg.profileExtra;
    })

    (mkIf (cfg.loginExtra != "") {
      home.file."${relToDotDir ".zlogin"}".text = cfg.loginExtra;
    })

    (mkIf (cfg.logoutExtra != "") {
      home.file."${relToDotDir ".zlogout"}".text = cfg.logoutExtra;
    })

    (mkIf cfg.oh-my-zsh.enable {
      home.file."${relToDotDir ".zshenv"}".text = ''
        ZSH="${pkgs.oh-my-zsh}/share/oh-my-zsh";
        ZSH_CACHE_DIR="${config.xdg.cacheHome}/oh-my-zsh";
      '';
    })

    (mkIf (cfg.dotDir != null) {
      home.file."${relToDotDir ".zshenv"}".text = ''
        ZDOTDIR=${zdotdir}
      '';

      # When dotDir is set, only use ~/.zshenv to source ZDOTDIR/.zshenv,
      # This is so that if ZDOTDIR happens to be
      # already set correctly (by e.g. spawning a zsh inside a zsh), all env
      # vars still get exported
      home.file.".zshenv".text = ''
        source ${zdotdir}/.zshenv
      '';
    })

    {
      home.packages = with pkgs; [ zsh ]
        ++ optional cfg.completion.enable nix-zsh-completions
        ++ optional cfg.oh-my-zsh.enable oh-my-zsh;

      home.file."${relToDotDir ".zshrc"}".text = ''
        typeset -U path cdpath fpath manpath

        ${optionalString (cfg.cdpath != []) ''
          cdpath+=(${concatStringsSep " " cfg.cdpath})
        ''}

        for profile in ''${(z)NIX_PROFILES}; do
          fpath+=($profile/share/zsh/site-functions $profile/share/zsh/$ZSH_VERSION/functions $profile/share/zsh/vendor-completions)
        done

        HELPDIR="${pkgs.zsh}/share/zsh/$ZSH_VERSION/help"

        ${optionalString (cfg.defaultKeymap != null) ''
          # Use ${cfg.defaultKeymap} keymap as the default.
          ${getAttr cfg.defaultKeymap bindkeyCommands}
        ''}

        ${localVarsStr}

        ${cfg.initExtraBeforeCompInit}

        ${concatStrings (map (plugin: ''
          path+="$HOME/${pluginsDir}/${plugin.name}"
          fpath+="$HOME/${pluginsDir}/${plugin.name}"
        '') cfg.plugins)}

        # Oh-My-Zsh calls compinit during initialization,
        # calling it twice causes sight start up slowdown
        # as all $fpath entries will be traversed again.
        ${optionalString (cfg.completion.enable && !cfg.oh-my-zsh.enable) ''
          ${if cfg.completion.path != null
            then ''
              # compinit directory must exist
              mkdir -p "$(dirname "${cfg.completion.path}")"
              autoload -U compinit && compinit -d "${cfg.completion.path}"
            ''
            else "autoload -U compinit && compinit"}
        ''}

        ${optionalString cfg.enableAutosuggestions
          "source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
        }

        # Environment variables
        . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"
        ${envVarsStr}

        ${optionalString cfg.oh-my-zsh.enable ''
            # oh-my-zsh extra settings for plugins
            ${cfg.oh-my-zsh.extraConfig}
            # oh-my-zsh configuration generated by NixOS
            ${optionalString (cfg.oh-my-zsh.plugins != [])
              "plugins=(${concatStringsSep " " cfg.oh-my-zsh.plugins})"
            }
            ${optionalString (cfg.oh-my-zsh.custom != "")
              "ZSH_CUSTOM=\"${cfg.oh-my-zsh.custom}\""
            }
            ${optionalString (cfg.oh-my-zsh.theme != "")
              "ZSH_THEME=\"${cfg.oh-my-zsh.theme}\""
            }
            source $ZSH/oh-my-zsh.sh
        ''}

        ${concatStrings (map (plugin: ''
          if [ -f "$HOME/${pluginsDir}/${plugin.name}/${plugin.file}" ]; then
            source "$HOME/${pluginsDir}/${plugin.name}/${plugin.file}"
          fi
        '') cfg.plugins)}

        # History options should be set in .zshrc and after oh-my-zsh sourcing.
        # See https://github.com/rycee/home-manager/issues/177.
        HISTSIZE="${toString cfg.history.size}"
        SAVEHIST="${toString cfg.history.save}"
        ${if versionAtLeast config.home.stateVersion "20.03"
          then ''HISTFILE="${cfg.history.path}"''
          else ''HISTFILE="$HOME/${cfg.history.path}"''}
        mkdir -p "$(dirname "$HISTFILE")"

        setopt HIST_FCNTL_LOCK
        ${if cfg.history.ignoreDups then "setopt" else "unsetopt"} HIST_IGNORE_DUPS
        ${if cfg.history.ignoreSpace then "setopt" else "unsetopt"} HIST_IGNORE_SPACE
        ${if cfg.history.expireDuplicatesFirst then "setopt" else "unsetopt"} HIST_EXPIRE_DUPS_FIRST
        ${if cfg.history.share then "setopt" else "unsetopt"} SHARE_HISTORY
        ${if cfg.history.extended then "setopt" else "unsetopt"} EXTENDED_HISTORY
        ${if cfg.autocd != null then "${if cfg.autocd then "setopt" else "unsetopt"} autocd" else ""}

        ${cfg.initExtra}

        # Aliases
        ${aliasesStr}

        # Global Aliases
        ${globalAliasesStr}
      '';
    }

    (mkIf cfg.oh-my-zsh.enable {
      # Make sure we create a cache directory since some plugins expect it to exist
      # See: https://github.com/rycee/home-manager/issues/761
      home.file."${config.xdg.cacheHome}/oh-my-zsh/.keep".text = "";
    })

    (mkIf (cfg.plugins != []) {
      # Many plugins require compinit to be called
      # but allow the user to opt out.
      programs.zsh.completion.enable = mkDefault true;

      home.file =
        foldl' (a: b: a // b) {}
        (map (plugin: { "${pluginsDir}/${plugin.name}".source = plugin.src; })
        cfg.plugins);
    })
  ]);
}
