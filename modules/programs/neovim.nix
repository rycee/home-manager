{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.neovim;

  extraPython3PackageType = mkOptionType {
    name = "extra-python3-packages";
    description = "python3 packages in python.withPackages format";
    check = with types;
      (x: if isFunction x then isList (x pkgs.python3Packages) else false);
    merge = mergeOneOption;
  };

  pluginWithConfigType = types.submodule {
    options = {
      config = mkOption {
        type = types.lines;
        description = "vimscript for this plugin to be placed in init.vim";
        default = "";
      };

      optional = mkEnableOption "optional" // {
        description = "Don't load by default (load with :packadd)";
      };

      plugin = mkOption {
        type = types.package;
        description = "vim plugin";
      };
    };
  };

  # A function to get the configuration string (if any) from an element of 'plugins'
  pluginConfig = p:
    if p ? plugin && (p.config or "") != "" then ''
      " ${p.plugin.pname or p.plugin.name} {{{
      ${p.config}
      " }}}
    '' else
      "";

  moduleConfigure = {
    packages.home-manager = {
      start = filter (f: f != null) (map
        (x: if x ? plugin && x.optional == true then null else (x.plugin or x))
        cfg.plugins);
      opt = filter (f: f != null)
        (map (x: if x ? plugin && x.optional == true then x.plugin else null)
          cfg.plugins);
    };
    beforePlugins = "";
  };

  extraMakeWrapperArgs = lib.optionalString (cfg.extraPackages != [ ])
    ''--suffix PATH : "${lib.makeBinPath cfg.extraPackages}"'';

in {
  imports = [
    (mkRemovedOptionModule [ "programs" "neovim" "withPython" ]
      "Python2 support has been removed from neovim.")
    (mkRemovedOptionModule [ "programs" "neovim" "extraPythonPackages" ]
      "Python2 support has been removed from neovim.")
  ];

  options = {
    programs.neovim = {
      enable = mkEnableOption "Neovim";

      viAlias = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Symlink <command>vi</command> to <command>nvim</command> binary.
        '';
      };

      vimAlias = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Symlink <command>vim</command> to <command>nvim</command> binary.
        '';
      };

      vimdiffAlias = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Alias <command>vimdiff</command> to <command>nvim -d</command>.
        '';
      };

      withNodeJs = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable node provider. Set to <literal>true</literal> to
          use Node plugins.
        '';
      };

      withRuby = mkOption {
        type = types.nullOr types.bool;
        default = true;
        description = ''
          Enable ruby provider.
        '';
      };

      withPython3 = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Enable Python 3 provider. Set to <literal>true</literal> to
          use Python 3 plugins.
        '';
      };

      extraPython3Packages = mkOption {
        type = with types; either extraPython3PackageType (listOf package);
        default = (_: [ ]);
        defaultText = "ps: []";
        example = literalExample "(ps: with ps; [ python-language-server ])";
        description = ''
          A function in python.withPackages format, which returns a
          list of Python 3 packages required for your plugins to work.
        '';
      };

      package = mkOption {
        type = types.package;
        default = pkgs.neovim-unwrapped;
        defaultText = literalExample "pkgs.neovim-unwrapped";
        description = "The package to use for the neovim binary.";
      };

      finalPackage = mkOption {
        type = types.package;
        visible = false;
        readOnly = true;
        description = "Resulting customized neovim package.";
      };

      configure = mkOption {
        type = types.attrsOf types.anything;
        default = { };
        example = literalExample ''
          configure = {
              customRC = $''''
              " here your custom configuration goes!
              $'''';
              packages.myVimPackage = with pkgs.vimPlugins; {
                # loaded on launch
                start = [ fugitive ];
                # manually loadable by calling `:packadd $plugin-name`
                opt = [ ];
              };
            };
        '';
        description = ''
          Deprecated. Please use the other options.

          Generate your init file from your list of plugins and custom commands,
          and loads it from the store via <command>nvim -u /nix/store/hash-vimrc</command>

          </para><para>

          This option is mutually exclusive with <varname>extraConfig</varname>
          and <varname>plugins</varname>.
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        example = ''
          set nocompatible
          set nobackup
        '';
        description = ''
          Custom vimrc lines.

          </para><para>

          This option is mutually exclusive with <varname>configure</varname>.
        '';
      };

      extraPackages = mkOption {
        type = with types; listOf package;
        default = [ ];
        example = "[ pkgs.shfmt ]";
        description = "Extra packages available to nvim.";
      };

      plugins = mkOption {
        type = with types; listOf (either package pluginWithConfigType);
        default = [ ];
        example = literalExample ''
          with pkgs.vimPlugins; [
            yankring
            vim-nix
            { plugin = vim-startify;
              config = "let g:startify_change_to_vcs_root = 0";
            }
          ]
        '';
        description = ''
          List of vim plugins to install optionally associated with
          configuration to be placed in init.vim.

          </para><para>

          This option is mutually exclusive with <varname>configure</varname>.
        '';
      };

      coc = {
        enable = mkEnableOption "Coc";

        extraConfig = mkOption {
          type = types.lines;
          default = "";
          example = ''
            {
              "suggest.noselect": true,
              "suggest.enablePreview": true,
              "suggest.enablePreselect":false,
              "suggest.disableKind": true,
              "languageserver": {
                "haskell": {
                  "command": "haskell-language-server-wrapper",
                  "args": ["--lsp"],
                  "rootPatterns": ["*.cabal", "stack.yaml", "cabal.project", "package.yaml", "hie.yaml"],
                  "filetypes": ["haskell", "lhaskell"]
                }
              }
            }
          '';
          description = ''
            Extra configuration lines to add to
            <filename>$XDG_CONFIG_HOME/nvim/coc-settings.json</filename>
            See
            <link xlink:href="https://github.com/neoclide/coc.nvim/wiki/Using-the-configuration-file" />
            for options.
          '';
        };
      };
    };
  };

  config = let
    neovimConfig = pkgs.neovimUtils.makeNeovimConfig {
      inherit (cfg)
        extraPython3Packages withPython3 withNodeJs withRuby viAlias vimAlias;
      configure = cfg.configure // moduleConfigure;
      plugins = cfg.plugins
        ++ (if cfg.coc.enable then [ pkgs.vimPlugins.coc-nvim ] else [ ]);
      customRC = cfg.extraConfig;
    };

  in mkIf cfg.enable {
    warnings = optional (cfg.configure != { }) ''
      programs.neovim.configure is deprecated.
      Other programs.neovim options can override its settings or ignore them.
      Please use the other options at your disposal:
        configure.packages.*.opt  -> programs.neovim.plugins = [ { plugin = ...; optional = true; }]
        configure.packages.*.start  -> programs.neovim.plugins = [ { plugin = ...; }]
        configure.customRC -> programs.neovim.extraConfig
    '';

    home.packages = [ cfg.finalPackage ];

    xdg.configFile."nvim/init.vim" = mkIf (neovimConfig.neovimRcContent != "") {
      text = neovimConfig.neovimRcContent;
    };
    xdg.configFile."nvim/coc-settings.json" =
      mkIf cfg.coc.enable { text = cfg.coc.extraConfig; };

    programs.neovim.finalPackage = pkgs.wrapNeovimUnstable cfg.package
      (neovimConfig // {
        wrapperArgs = (lib.escapeShellArgs neovimConfig.wrapperArgs) + " "
          + extraMakeWrapperArgs;
        wrapRc = false;
      });

    programs.bash.shellAliases = mkIf cfg.vimdiffAlias { vimdiff = "nvim -d"; };
    programs.fish.shellAliases = mkIf cfg.vimdiffAlias { vimdiff = "nvim -d"; };
    programs.zsh.shellAliases = mkIf cfg.vimdiffAlias { vimdiff = "nvim -d"; };
  };
}
