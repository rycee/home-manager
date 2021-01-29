{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.emacs;

  # Copied from all-packages.nix, with modifications to support
  # overrides.
  emacsPackages = let epkgs = pkgs.emacsPackagesFor cfg.package;
  in epkgs.overrideScope' cfg.overrides;

  emacsWithPackages = emacsPackages.emacsWithPackages;

  createConfPackage = epkgs:
    epkgs.trivialBuild {
      pname = "default";
      src = pkgs.writeText "default.el" cfg.extraConfig;
    };
in {
  meta.maintainers = [ maintainers.rycee ];

  options = {
    programs.emacs = {
      enable = mkEnableOption "Emacs";

      package = mkOption {
        type = types.package;
        default = pkgs.emacs;
        defaultText = literalExample "pkgs.emacs";
        example = literalExample "pkgs.emacs25-nox";
        description = "The Emacs package to use.";
      };

      # NOTE: The config is placed in default.el instead of ~/.emacs.d so that
      # it won't conflict with Emacs configuration frameworks. Users of these
      # frameworks would still benefit from this option as it would easily allow
      # them to have Nix-computed paths in their configuration.
      extraConfig = mkOption {
        type = types.lines;
        default = "";
        example = ''
          (setq standard-indent 2)
        '';
        description = ''
          Configuration to include in the Emacs
          <link xlink:href="https://www.gnu.org/software/emacs/manual/html_node/elisp/Init-File.html">default init file</link>.
        '';
      };

      extraPackages = mkOption {
        default = self: [ ];
        type = hm.types.selectorFunction;
        defaultText = "epkgs: []";
        example = literalExample "epkgs: [ epkgs.emms epkgs.magit ]";
        description = ''
          Extra packages available to Emacs. To get a list of
          available packages run:
          <command>nix-env -f '&lt;nixpkgs&gt;' -qaP -A emacsPackages</command>.
        '';
      };

      overrides = mkOption {
        default = self: super: { };
        type = hm.types.overlayFunction;
        defaultText = "self: super: {}";
        example = literalExample ''
          self: super: rec {
            haskell-mode = self.melpaPackages.haskell-mode;
            # ...
          };
        '';
        description = ''
          Allows overriding packages within the Emacs package set.
        '';
      };

      finalPackage = mkOption {
        type = types.package;
        visible = false;
        readOnly = true;
        description = ''
          The Emacs package including any overrides and extra packages.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.finalPackage ];
    programs.emacs = {
      finalPackage = emacsWithPackages cfg.extraPackages;
      extraPackages = epkgs:
        optional (cfg.extraConfig != "") (createConfPackage epkgs);
    };
  };
}
