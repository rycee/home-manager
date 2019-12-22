{ config, pkgs, lib, ... }: with lib; let
  settingType = types.attrsOf (types.either cfgType settingType);
  flatConfig = attrs: let
    deep = mapAttrsRecursive (path: value: nameValuePair (concatStringsSep "." path) value) attrs;
    recurse = value:
      if isAttrs value && ! value ? value then concatMap recurse (builtins.attrValues value)
      else [ value ];
  in listToAttrs (recurse deep);
  cfgType = types.either types.str (types.either types.bool types.int);
  cfg = config.programs.weechat;
  drvAttr = types.either types.str types.package;
  drvAttrsFor = packages: map (d:
    if isString d then packages.${d} else d
  );
  configStr = v:
    if isString v then ''"${v}"''
    else if isBool v then (if v then "on" else "off")
    else if isInt v then toString v
    else throw "unknown weechat config value ${toString v}";
  configure = { availablePlugins, ... }: {
    plugins = with availablePlugins;
      optional cfg.plugins.python.enable (
        python.withPackages (ps: drvAttrsFor ps cfg.plugins.python.packages)
      ) ++ optional (cfg.environment != { }) {
        # dummy for inserting env vars into wrapper script
        pluginFile = "";
        extraEnv = concatStringsSep "\n" (mapAttrsToList (k: v: "export ${k}=${escapeShellArg v}") cfg.environment);
      };
    scripts = drvAttrsFor pkgs.weechatScripts cfg.scripts;
    inherit (cfg) init;
  };
  pythonOverride = {
    python3Packages = cfg.pythonPackages;
  };
  defaultHomeDirectory = "${config.home.homeDirectory}/.weechat";
  weechatrc = "${config.home.homeDirectory}/${config.xdg.configFile."weechat/weechatrc".target}";
in {
  options.programs.weechat = {
    enable = mkEnableOption "weechat";

    package = mkOption {
      type = types.package;
      defaultText = "pkgs.weechat";
      default = cfg.packageWrapper cfg.packageUnwrapped { inherit configure; };
    };

    packageUnwrapped = mkOption {
      type = types.package;
      defaultText = "pkgs.weechat-unwrapped";
      default = pkgs.weechat-unwrapped.override pythonOverride;
    };

    packageWrapper = mkOption {
      type = types.unspecified;
      defaultText = "pkgs.wrapWeechat";
      default = pkgs.wrapWeechat.override pythonOverride;
    };

    pythonPackages = mkOption {
      type = types.unspecified;
      defaultText = "pkgs.python3Packages";
      example = literalExample "pkgs.pythonPackages";
      default = pkgs.python3Packages;
    };

    plugins = {
      python = {
        enable = mkOption {
          type = types.bool;
          default = true;
        };

        packages = mkOption {
          type = types.listOf drvAttr;
          default = [ ];
          description = "Attributes or derivations from pythonPackages that scripts might depend on";
          example = [ "weechat-matrix" ];
        };
      };
    };

    scripts = mkOption {
      type = types.listOf drvAttr;
      description = "Attributes or derivations from pkgs.weechatScripts";
      default = [ ];
      example = [ "weechat-matrix" "weechat-autosort" ];
    };

    init = mkOption {
      type = types.lines;
      description = "Commands to run on startup";
      default = "";
    };

    source = mkOption {
      type = types.listOf types.path;
      description = "Files to source on startup";
      default = [];
    };

    environment = mkOption {
      type = types.attrsOf types.str;
      description = "Extra environment variables";
      default = { };
    };

    homeDirectory = mkOption {
      type = types.nullOr types.path;
      description = "Weechat home config directory";
      default = defaultHomeDirectory;
      defaultText = "~/.weechat";
      example = literalExample "\${config.xdg.dataHome}/weechat";
    };

    config = mkOption {
      type = settingType;
      default = { };
      description = "Weechat configuration settings";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."weechat/weechatrc" = mkIf (cfg.config != { }) {
      text = concatStringsSep "\n" (mapAttrsToList
        (k: v: "/set ${k} ${configStr v}") (flatConfig cfg.config)
      );
      # NOTE: this doesn't include/re-run init commands (should it?)
      onChange = ''
        if [[ -p "${cfg.homeDirectory}/weechat_fifo" ]]; then
          echo "Refreshing weechat settings..." >&2
          sed "s-^/-*/-" "${weechatrc}" > "${cfg.homeDirectory}/weechat_fifo"
        fi
      '';
    };
    programs.weechat = {
      environment = mkIf (cfg.homeDirectory != defaultHomeDirectory) {
        WEECHAT_HOME = cfg.homeDirectory;
      };
      source = optional (cfg.config != { }) weechatrc;
      init = concatMapStringsSep "\n" (f: "/exec -sh -norc -oc cat ${f}") cfg.source;
    };
  };
}
