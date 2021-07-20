{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.fonts.fontconfig;

  profileDirectory = config.home.profileDirectory;

in {
  meta.maintainers = [ maintainers.rycee ];

  imports = [
    (mkRenamedOptionModule [ "fonts" "fontconfig" "enableProfileFonts" ] [
      "fonts"
      "fontconfig"
      "enable"
    ])
  ];

  options = {
    fonts.fontconfig = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable fontconfig configuration. This will, for
          example, allow fontconfig to discover fonts and
          configurations installed through
          <varname>home.packages</varname> and
          <command>nix-env</command>.
        '';
      };
      includes = mkOption {
        type = types.listOf (types.submodule {
          options = {
            ignoreMissing = mkOption {
              type = types.bool;
              default = false;
              description =
                "Ignore this import if the path does not exist. Maps to the `ignore_missing` attribute.";
            };
            path = mkOption {
              type = types.path;
              description = "Path to be included.";
            };
          };
        });
        default = [ ];
        description = "Paths to include.";
      };
      cacheDir = mkOption {
        internal = true;
        type = types.path;
        description = "fontconfig cache directory";
      };
      dirs = mkOption {
        type = types.listOf types.path;
        default = [ ];
        description = "Directories to load fonts from.";
      };
      aliases = mkOption {
        type = types.listOf (types.submodule {
          options = {
            families = mkOption {
              type = types.listOf types.str;
              description = "Families to be matched.";
            };
            prefer = mkOption {
              type = types.nullOr (types.listOf types.str);
              default = null;
              description =
                "Families to be prepended before the matched family.";
            };
            accept = mkOption {
              type = types.nullOr (types.listOf types.str);
              default = null;
              description = "Families to be placed after the matched family.";
            };
            default = mkOption {
              type = types.nullOr (types.listOf types.str);
              default = null;
              description = "Families to be appended to the family list.";
            };
          };
        });
        default = [ ];
        description = "Substitutions of one font family for another.";
      };
      matches = mkOption {
        type = types.listOf (types.submodule {
          options = {
            tests = mkOption {
              type = types.listOf (types.submodule {
                options = {
                  name = mkOption {
                    type = types.str;
                    description = "Attribute to match on.";
                  };
                  qual = mkOption {
                    type = types.nullOr
                      (types.enum [ "any" "all" "first" "not_first" ]);
                    default = null;
                    description =
                      "Determines which occurrence of the attribute should be tested if it appears multiple times.";
                  };
                  target = mkOption {
                    type = types.nullOr (types.enum [ "pattern" "font" ]);
                    default = null;
                    description = "Determines what is tested.";
                  };
                  ignoreBlanks = mkOption {
                    type = types.bool;
                    default = false;
                    description = "Whether whitespace should be ignored.";
                  };
                  compare = mkOption {
                    type = types.nullOr (types.enum [
                      "eq"
                      "not_eq"
                      "less"
                      "less_eq"
                      "more"
                      "more_eq"
                      "contains"
                      "not_contains"
                    ]);
                    default = null;
                    description = "The type of comparison to make.";
                  };
                  exprs = mkOption {
                    type = types.listOf types.str;
                    default = [ ];
                    description = "The expressions to match.";
                  };
                };
              });
              description = "Tests to make to find matched elements.";
            };
            edits = mkOption {
              type = types.listOf (types.submodule {
                options = {
                  name = mkOption {
                    type = types.str;
                    description = "The attribute to edit.";
                  };
                  mode = mkOption {
                    type = types.nullOr (types.enum [
                      "assign"
                      "assign_replace"
                      "prepend"
                      "append"
                      "prepend_first"
                      "append_last"
                      "delete"
                      "delete_all"
                    ]);
                    default = null;
                    description = "The type of edit to be made.";
                  };
                  binding = mkOption {
                    type = types.nullOr (types.enum [ "weak" "strong" "same" ]);
                    default = null;
                    description = "The binding to be used for the edit.";
                  };
                  exprs = mkOption {
                    type = types.listOf types.str;
                    default = [ ];
                    description = "The expressions to edit.";
                  };
                };
              });
              description = "Edits to be made to matches.";
            };
            target = mkOption {
              type = types.nullOr (types.enum [ "pattern" "font" "scan" ]);
              default = null;
              description = "The target to be matched.";
            };
          };
        });
        default = [ ];
        description = "Modifications to make.";
      };
    };
  };

  config = mkIf cfg.enable {
    fonts.fontconfig.includes = [
      {
        ignoreMissing = true;
        path = "${config.home.path}/etc/fonts/conf.d";
      }
      {
        ignoreMissing = true;
        path = "${config.home.path}/etc/fonts/fonts.conf";
      }
    ];
    fonts.fontconfig.cacheDir =
      lib.mkDefault "${config.home.path}/lib/fontconfig/cache";
    fonts.fontconfig.dirs = [
      "${config.home.path}/lib/X11/fonts"
      "${config.home.path}/share/fonts"
      "${profileDirectory}/lib/X11/fonts"
      "${profileDirectory}/share/fonts"
    ];

    # Create two dummy files in /lib/fontconfig to make sure that
    # buildEnv creates a real directory path. These files are removed
    # in home.extraProfileCommands below so the packages will not
    # become "runtime" dependencies.
    home.packages = [
      (pkgs.writeTextFile {
        name = "hm-dummy1";
        destination = "/lib/fontconfig/hm-dummy1";
        text = "dummy";
      })

      (pkgs.writeTextFile {
        name = "hm-dummy2";
        destination = "/lib/fontconfig/hm-dummy2";
        text = "dummy";
      })
    ];

    home.extraProfileCommands = ''
      if [[ -d $out/lib/X11/fonts || -d $out/share/fonts ]]; then
        export FONTCONFIG_FILE="$(pwd)/fonts.conf"

        cat > $FONTCONFIG_FILE << EOF
      <?xml version='1.0'?>
      <!DOCTYPE fontconfig SYSTEM 'fonts.dtd'>
      <fontconfig>
        <dir>$out/lib/X11/fonts</dir>
        <dir>$out/share/fonts</dir>
        <cachedir>$out/lib/fontconfig/cache</cachedir>
      </fontconfig>
      EOF

        ${getBin pkgs.fontconfig}/bin/fc-cache -f
        rm -f $out/lib/fontconfig/cache/CACHEDIR.TAG
        rmdir --ignore-fail-on-non-empty -p $out/lib/fontconfig/cache

        rm "$FONTCONFIG_FILE"
        unset FONTCONFIG_FILE
      fi

      # Remove hacky dummy files.
      rm $out/lib/fontconfig/hm-dummy?
      rmdir --ignore-fail-on-non-empty -p $out/lib/fontconfig
    '';

    xdg.configFile = {
      "fontconfig/conf.d/10-hm-fonts.conf".source = with cfg;
        let
          submoduleToAttrs = m: lib.filterAttrs (name: v: name != "_module") m;
          takeSubmodule = f: x: f (submoduleToAttrs x);
          mkInclude = { ignoreMissing, path }: {
            name = "include";
            attrs = if ignoreMissing then { ignore_missing = "yes"; } else { };
            content = path;
          };
          mkDir = path: {
            name = "dir";
            content = path;
          };
          mkFamilies = families:
            builtins.map (x: {
              name = "family";
              content = x;
            }) families;
          mkFamilyType = type: families:
            if families == null then
              [ ]
            else [{
              name = type;
              children = mkFamilies families;
            }];
          mkAlias = { families, prefer, accept, default }: {
            name = "alias";
            children = mkFamilies families ++ mkFamilyType "prefer" prefer
              ++ mkFamilyType "accept" accept ++ mkFamilyType "default" default;
          };
          mkExpr = expr:
            let type = builtins.typeOf expr;
            in if type == "string" then {
              name = "string";
              content = expr;
            } else
              throw "Bad expression type ${type}";
          mkTest = { name, qual, target, ignoreBlanks, compare, exprs }: {
            name = "test";
            attrs = {
              inherit name qual compare target;
              ignore-blanks = if ignoreBlanks then "true" else null;
            };
            children = builtins.map mkExpr exprs;
          };
          mkEdit = { name, mode, binding, exprs }: {
            name = "edit";
            attrs = { inherit name mode binding; };
            children = builtins.map mkExpr exprs;
          };
          mkMatch = { tests, edits, target }: {
            name = "match";
            attrs.target = target;
            children = builtins.map (takeSubmodule mkTest) tests
              ++ builtins.map (takeSubmodule mkEdit) edits;
          };
          includeElements = builtins.map (takeSubmodule mkInclude) includes;
          dirElements = builtins.map mkDir dirs;
          cacheDirElement = {
            name = "cachedir";
            content = cacheDir;
          };
          aliasElements = builtins.map (takeSubmodule mkAlias) aliases;
          matchElements = builtins.map (takeSubmodule mkMatch) matches;
        in lib.hm.xml.genXMLFile {
          doctypeSystem = "fonts.dtd";
          root = {
            name = "fontconfig";
            children = includeElements ++ dirElements ++ [ cacheDirElement ]
              ++ aliasElements ++ matchElements;
          };
        };
    };
  };
}
