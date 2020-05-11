{ homeDirectory, lib, pkgs }:

with lib;

{
  # Constructs a type suitable for a `home.file` like option. The
  # target path may be either absolute or relative, in which case it
  # is relative the `basePath` argument (which itself must be an
  # absolute path).
  #
  # Arguments:
  #   - basePathDesc   docbook compatible description of the base path
  #   - basePath       the file base path
  fileType = basePathDesc: basePath: types.loaOf (types.submodule (
    { name, config, ... }: {
      options = {
        target = mkOption {
          type = types.str;
          apply = p:
            let
              absPath = if hasPrefix "/" p then p else "${basePath}/${p}";
            in
              removePrefix (homeDirectory + "/") absPath;
          description = ''
            Path to target file relative to ${basePathDesc}.
          '';
        };

        text = mkOption {
          default = null;
          type = types.nullOr types.lines;
          description = "Text of the file.";
        };

        source = mkOption {
          type = types.path;
          description = ''
            Path of the source file. The file name must not start
            with a period since Nix will not allow such names in
            the Nix store.
            </para><para>
            This may refer to a directory.
          '';
        };

        executable = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = ''
            Set the execute bit. If <literal>null</literal>, defaults to the mode
            of the <varname>source</varname> file or to <literal>false</literal>
            for files created through the <varname>text</varname> option.
          '';
        };

        recursive = mkOption {
          type = types.bool;
          default = false;
          description = ''
            If the file source is a directory, then this option
            determines whether the directory should be recursively
            linked to the target location. This option has no effect
            if the source is a file.
            </para><para>
            If <literal>false</literal> (the default) then the target
            will be a symbolic link to the source directory. If
            <literal>true</literal> then the target will be a
            directory structure matching the source's but whose leafs
            are symbolic links to the files of the source directory.
          '';
        };

        copy = mkOption {
          type = types.bool;
          default = false;
          description = ''
            Copy the file instead of creating a symbolic link.
          '';
        };

        onChange = mkOption {
          type = types.lines;
          default = "";
          description = ''
            Shell commands to run when file has changed between
            generations. The script will be run
            <emphasis>after</emphasis> the new files have been linked
            into place.
          '';
        };

        force = mkOption {
          type = types.bool;
          default = false;
          visible = false;
          description = ''
            Whether the target path should be unconditionally replaced
            by the managed file source. Warning, this will silently
            delete the target regardless of whether it is a file or
            link.
          '';
        };
      };

      config = {
        target = mkDefault name;
        source = mkIf (config.text != null) (
          mkDefault (pkgs.writeTextFile {
            inherit (config) executable text;
            name = hm.strings.storeFileName name;
          })
        );
      };
    }
  ));
}
