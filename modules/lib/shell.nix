{ lib }:

rec {
  # Produces a Bourne shell like variable export statement.
  export = n: v: ''export ${n}="${toString v}"'';

  export' = { colonVars ? [ ] }:
    n: v:
    let
      replaceMatch = match:
        lib.replaceStrings [ ":\$${match}:" ":\$${match}" "\$${match}:" ] [
          "\${${match}:+:\$${match}:}"
          "\${${match}:+:\$${match}}"
          "\${${match}:+\$${match}:}"
        ];

      mkValue = n: v:
        if builtins.elem n colonVars then replaceMatch n v else toString v;
    in ''export ${n}="${mkValue n v}"'';

  # Given an attribute set containing shell variable names and their
  # assignment, this function produces a string containing an export
  # statement for each set entry.
  exportAll = vars: lib.concatStringsSep "\n" (lib.mapAttrsToList export vars);

  exportAll' = opts: vars:
    lib.concatStringsSep "\n" (lib.mapAttrsToList (export' opts) vars);
}
