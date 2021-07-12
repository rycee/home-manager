{ config, lib, ... }:

let
  nullOptional = x: if x == null then [ ] else [ x ];
  nullMapOptional = f: x: if x == null then [ ] else [ (f x) ];

  concatSpace = lib.concatStringsSep " ";
  concatCommaSpace = lib.concatStringsSep ", ";
  concatNewline = lib.concatStringsSep "\n";

  cfg = config.xcompose;

  renderEscapedString = str:
    ''"${lib.replaceStrings [ ''"'' "\n" ] [ ''\"'' "\\n" ] str}"'';
  renderLiteralString = str:
    renderEscapedString (lib.replaceStrings [ "\\" ] [ "\\\\" ] str);

  ty = lib.types;

  includeRuleType = ty.submodule ({ config, lib, ... }: {
    options.include = lib.mkOption {
      type = ty.nullOr (ty.either ty.path ty.str);
      description = ''
        Path of existing compose file to include.

        Substitutions will be applied to string values, but not to path
        values.

        <variablelist><title>String path substitutions</title>
          <varlistentry>
            <term><literal>%H</literal></term>
            <listitem>
              <para>Expands to the user's home directory (the
              <envvar>HOME</envvar> environment variable).</para>
            </listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>%L</literal></term>
            <listitem>
              <para>Expands to the path of the locale specific Compose
              file (i.e.,
              <filename>/nix/store/<replaceable>...</replaceable>-libX11-<replaceable>...</replaceable>/share/X11/locale/<replaceable>localename</replaceable>/Compose</filename>).</para>
            </listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>%S</literal></term>
            <listitem>
              <para>Expands to the path of the system directory for
              locale files (i.e.,
              <filename>/nix/store/<replaceable>...</replaceable>-libX11-<replaceable>...</replaceable>/share/X11/locale</filename>).</para>
            </listitem>
          </varlistentry>
          <varlistentry>
            <term><literal>%S</literal></term>
            <listitem>
              <para>Literal <literal>%</literal>.</para>
            </listitem>
          </varlistentry>
        </itemizedlist>

        For the exact implementation, see
        <function>TransFileName</function> in
        <filename>/modules/im/ximcp/imLcPrs.c</filename> in the libX11
        source.
      '';
      default = null;
      example = lib.literalExample ''"%H/my-include.Compose"'';
    };

    options.literalInclude = lib.mkOption {
      type = ty.nullOr (ty.either ty.path ty.str);
      description = ''
        Path of existing compose file to include.

        Substitutions will not be applied to string or path values. This
        is otherwise like defining the <option>include</option> option.
      '';
      default = null;
      example = lib.literalExample ''"/home/alice/literal%include.Compose"'';
    };

    config = lib.mkIf (config.literalInclude != null) {
      include = if lib.isString config.literalInclude then
        lib.replaceStrings [ "%" ] [ "%%" ] config.literalInclude
      else
        config.literalInclude;
    };
  });

  renderIncludeRule = { include, ... }:
    let
      path = if builtins.isPath include then
        lib.replaceStrings [ "%" ] [ "%%" ] (toString include)
      else
        include;
    in "include ${renderLiteralString path}";

  sequenceEventType = ty.coercedTo ty.str (keysym: { inherit keysym; })
    (ty.submodule ({ lib, ... }: {
      options.keysym = lib.mkOption {
        type = ty.str;
        description = "Base input keysym.";
      };
      options.exactModifiers = lib.mkOption {
        type = ty.bool;
        description = "Whether the modifier list must match exactly.";
        default = false;
        example = true;
      };
      options.modifiers = lib.mkOption {
        type = ty.nullOr (ty.listOf ty.str);
        description = ''
          Modifiers to match with the keysym. A preceeding
          <literal>~</literal> means the modifier must not be present.

          Alternatively, <literal>null</literal> means that no modifier may
          be present.
        '';
        default = [ ];
      };
    }));

  renderSequenceEvent = { keysym, modifiers, exactModifiers, ... }:
    if modifiers == null then
      "None"
    else
      concatSpace (lib.optional exactModifiers "!" ++ modifiers ++ [ keysym ]);

  sequenceResultType = ty.addCheck (ty.submodule ({ config, lib, ... }: {
    options.string = lib.mkOption {
      type = ty.nullOr ty.str;
      description = ''
        String that is received as input when the sequence of events is input.

        Direct text encoded in the locale for which the compose file is to be
        used, or an escaped octal or hexadecimal character code.  Octal codes
        are specified as <code>\<replaceable>123</replaceable><code> and
        hexadecimal codes as <code>\x<replaceable>3a</replaceable></code>. It
        is not necessary to specify a locale encoded string in addition to the
        keysym name. If the string is omitted, it is figured out from the
        keysym according to the current locale.
      '';
      default = null;
    };
    options.keysym = lib.mkOption {
      type = ty.nullOr ty.str;
      description = ''
        Keysym that is received as input when the sequence of events is input.

        If a result looks like
        <code>{ string = "\\300"; keysym = "Agrave"; }</code>, the result of
        the composition is always the letter with the <literal>"\300"<literal>
        code. But if the rule is <code>{ keysym = "Agrave"; }</code>, the
        result depends on how
        <systemitem otherclass="keysym">>Agrave</systemitem> is mapped in the
        current locale.
      '';
      default = null;
    };
  })) (result: result.string != null || result.keysym != null);

  renderSequenceResult = { string, keysym, ... }:
    let
      string' = nullMapOptional renderEscapedString string;
      keysym' = nullOptional keysym;
    in concatSpace (string' ++ keysym');

  sequenceRuleType = ty.submodule ({ lib, ... }: {
    options.events = lib.mkOption {
      type = ty.nonEmptyListOf sequenceEventType;
      description = "Events comprising this compose sequence.";
      example = [ "<Multi_key>" "<period>" "<equal>" ];
    };

    options.result = lib.mkOption {
      type = sequenceResultType;
      description = ''
        String, keysym, or both that is received as input when the sequence of
        events is input.
      '';
      example = ''"•" enfilledcircbullet'';
    };

    options.comment = lib.mkOption {
      type = ty.nullOr ty.lines;
      description = ''
        Trailing comment for this compose sequence. Up to one ending newline
        is ignored.
      '';
      example = "BULLET";
    };
  });

  renderCommentLines = lines:
    let
      lines' = builtins.split "\n" lines;
      lineCount = lib.length lines' / 2 + 1;
      lines'' = builtins.genList (i:
        let line = lib.elemAt lines' (i * 2);
        in if line == "" then "#" else "# ${line}") lineCount;
    in concatNewline lines'';

  renderSequenceRule = rule:
    let
      events = builtins.map renderSequenceEvent rule.events;
      result = renderSequenceResult rule.result;
      comment = nullMapOptional renderCommentLines rule.comment;
    in concatSpace (events ++ [ ":" result ] ++ comment);

  commentRuleType = ty.submodule ({ lib, ... }: {
    options.commentLines = lib.mkOption {
      type = ty.lines;
      description = ''
        Commented lines in the resulting compose file. Up to one ending
        newline is ignored. An empty string produces a blank line.
      '';
      example = "Part 1 - Manual definitions";
    };
  });

  renderCommentRule = { commentLines, ... }:
    if commentLines == "" then "" else renderCommentLines commentLines;

  ruleType = ty.oneOf [
    (ty.addCheck commentRuleType (r: r ? commentLines))
    (ty.addCheck includeRuleType (r: r ? include))
    sequenceRuleType
  ];

  renderRule = rule:
    (if rule ? commentLines then
      renderCommentRule
    else if rule ? include then
      renderIncludeRule
    else
      renderSequenceRule) rule;

  renderRules = rules: concatNewline (builtins.map renderRule rules ++ [ "" ]);
in {
  meta.maintainers = [ lib.maintainers.bb010g ];

  options = {
    xcompose = {
      enable = lib.mkEnableOption "Enable user XCompose configuration";
      rules = lib.mkOption {
        type = ty.listOf ruleType;
        default = [ ];
        example = lib.literalExample ''
          let
            ruleOn = rule: events: rule // { inherit events; };
            minusOn = ruleOn
              { result = { string = "−"; keysym = "U2212"; };
                comment = "MINUS SIGN"; };
          in [
            { include = "%L"; }
            { commentLines = ""; } # blank line
            (minusOn [ "<Multi_key>" "<underscore>" "<minus>" ])
            (minusOn [ "<Multi_key>" "<minus>" "<underscore>" ])
          ]
        '';
        description = ''
          User compose rules.
          The Nix value declared here will be translated to the custom
          format XCompose expects.
        '';
      };
      rulesText = lib.mkOption {
        type = ty.lines;
        description = ''
          User compose rules text. It is recommended to use the
          <option>rules</option> option instead.
          </para>
          <para>
          Setting this option will override any auto-generated rules text
          through the <option>rules</option> option.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    xcompose.rulesText = lib.mkDefault (renderRules cfg.rules);
    home.file.".XCompose".text = cfg.rulesText;
  };
}
