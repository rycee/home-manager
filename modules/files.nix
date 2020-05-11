{ pkgs, config, lib, ... }:

with lib;

let

  cfg = config.home.file;

  homeDirectory = config.home.homeDirectory;

  fileType = (import lib/file-type.nix {
    inherit homeDirectory lib pkgs;
  }).fileType;

  sourceStorePath = file:
    let
      sourcePath = toString file.source;
      sourceName = config.lib.strings.storeFileName (baseNameOf sourcePath);
    in
      if builtins.hasContext sourcePath
      then file.source
      else builtins.path { path = file.source; name = sourceName; };

  copyAccumulator = ".home-manager-copy";

in

{
  options = {
    home.file = mkOption {
      description = "Attribute set of files to link into the user home.";
      default = {};
      type = fileType "<envar>HOME</envar>" homeDirectory;
    };

    home-files = mkOption {
      type = types.package;
      internal = true;
      description = "Package to contain all home files";
    };
  };

  config = {
    lib.file.mkOutOfStoreSymlink = path:
      let
        pathStr = toString path;
        name = hm.strings.storeFileName (baseNameOf pathStr);
      in
        pkgs.runCommandLocal name {} ''ln -s ${escapeShellArg pathStr} $out'';

    # This verifies that the links we are about to create will not
    # overwrite an existing file.
    home.activation.checkLinkTargets = hm.dag.entryBefore ["writeBoundary"] (
      let
        # Paths that should be forcibly overwritten by Home Manager.
        # Caveat emptor!
        forcedPaths =
          concatMapStringsSep " " (p: ''"$HOME/${p}"'')
            (mapAttrsToList (n: v: v.target)
            (filterAttrs (n: v: v.force) cfg));

        check = pkgs.writeText "check" ''
          . ${./lib-bash/color-echo.sh}

          # A symbolic link whose target path matches this pattern will be
          # considered part of a Home Manager generation.
          homeFilePattern="$(readlink -e "${builtins.storeDir}")/*-home-manager-files/*"

          forcedPaths=(${forcedPaths})

          oldGenFiles="$1"
          newGenFiles="$2"
          shift 2
          for sourcePath in "$@" ; do
            relativePath="''${sourcePath#$newGenFiles/}"
            targetPath="$HOME/$relativePath"

            forced=""
            for forcedPath in "''${forcedPaths[@]}"; do
              if [[ $targetPath == $forcedPath* ]]; then
                forced="yeah"
                break
              fi
            done

            if [[ -n $forced ]]; then
              $VERBOSE_ECHO "Skipping collision check for $targetPath"
            elif [[ -e "$targetPath" \
                && ! "$(readlink "$targetPath")" == $homeFilePattern ]] \
                && ! cmp --quiet "$targetPath" "$oldGenFiles/$relativePath"; then
              if [[ ! -L "$targetPath" && -n "$HOME_MANAGER_BACKUP_EXT" ]] ; then
                backup="$targetPath.$HOME_MANAGER_BACKUP_EXT"
                if [[ -e "$backup" ]]; then
                  errorEcho "Existing file '$backup' would be clobbered by backing up '$targetPath'"
                  collision=1
                else
                  warnEcho "Existing file '$targetPath' is in the way, will be moved to '$backup'"
                fi
              else
                errorEcho "Existing file '$targetPath' is in the way"
                collision=1
              fi
            fi
          done

          if [[ -v collision ]] ; then
            errorEcho "Please move the above files and try again or use -b <ext> to move automatically."
            exit 1
          fi
        '';
      in
      ''
        function checkNewGenCollision() {
          local newGenFiles
          oldGenFiles="$(readlink -e "$oldGenPath/home-files")"
          newGenFiles="$(readlink -e "$newGenPath/home-files")"
          find "$newGenFiles" \( -type f -or -type l \) \
              -exec bash ${check} "$oldGenFiles" "$newGenFiles" {} +
        }

        checkNewGenCollision || exit 1
      ''
    );

    # This activation script will
    #
    # 1. Remove files from the old generation that are not in the new
    #    generation.
    #
    # 2. Switch over the Home Manager gcroot and current profile
    #    links.
    #
    # 3. Symlink files from the new generation into $HOME.
    #
    # This order is needed to ensure that we always know which links
    # belong to which generation. Specifically, if we're moving from
    # generation A to generation B having sets of home file links FA
    # and FB, respectively then cleaning before linking produces state
    # transitions similar to
    #
    #      FA   →   FA ∩ FB   →   (FA ∩ FB) ∪ FB = FB
    #
    # and a failure during the intermediate state FA ∩ FB will not
    # result in lost links because this set of links are in both the
    # source and target generation.
    home.activation.linkGeneration = hm.dag.entryAfter ["writeBoundary"] (
      let
        link = pkgs.writeText "link" ''
          newGenFiles="$1"
          copyList="$1/${copyAccumulator}"
          shift
          for sourcePath in "$@" ; do
            relativePath="''${sourcePath#$newGenFiles/}"
            if [[ "$relativePath" != "${copyAccumulator}" ]]; then
              targetPath="$HOME/$relativePath"
              if [[ -e "$targetPath" && ! -L "$targetPath" && -n "$HOME_MANAGER_BACKUP_EXT" ]] ; then
                backup="$targetPath.$HOME_MANAGER_BACKUP_EXT"
                $DRY_RUN_CMD mv $VERBOSE_ARG "$targetPath" "$backup" || errorEcho "Moving '$targetPath' failed!"
              fi
              $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$(dirname "$targetPath")"
              if grep -Fxq "$relativePath" "$copyList"; then
                $DRY_RUN_CMD cp --remove-destination $VERBOSE_ARG "$sourcePath" "$targetPath"
              else
                $DRY_RUN_CMD ln -nsf $VERBOSE_ARG "$sourcePath" "$targetPath"
              fi
            fi
          done
        '';

        cleanup = pkgs.writeText "cleanup" ''
          . ${./lib-bash/color-echo.sh}

          # A symbolic link whose target path matches this pattern will be
          # considered part of a Home Manager generation.
          homeFilePattern="$(readlink -e "${builtins.storeDir}")/*-home-manager-files/*"

          oldGenFiles="$1"
          newGenFiles="$2"
          shift 2
          for relativePath in "$@" ; do
            targetPath="$HOME/$relativePath"
            if [[ -e "$newGenFiles/$relativePath" ]] ; then
              $VERBOSE_ECHO "Checking $targetPath: exists"
            elif [[ ! "$(readlink "$targetPath")" == $homeFilePattern ]] \
                 && ! cmp --quiet "$targetPath" "$oldGenFiles/$relativePath"; then
              warnEcho "Path '$targetPath' not link into Home Manager generation. Skipping delete."
            else
              $VERBOSE_ECHO "Checking $targetPath: gone (deleting)"
              $DRY_RUN_CMD rm $VERBOSE_ARG "$targetPath"

              # Recursively delete empty parent directories.
              targetDir="$(dirname "$relativePath")"
              if [[ "$targetDir" != "." ]] ; then
                pushd "$HOME" > /dev/null

                # Call rmdir with a relative path excluding $HOME.
                # Otherwise, it might try to delete $HOME and exit
                # with a permission error.
                $DRY_RUN_CMD rmdir $VERBOSE_ARG \
                    -p --ignore-fail-on-non-empty \
                    "$targetDir"

                popd > /dev/null
              fi
            fi
          done
        '';
      in
        ''
          function linkNewGen() {
            echo "Creating home file links in $HOME"

            local newGenFiles
            newGenFiles="$(readlink -e "$newGenPath/home-files")"
            find "$newGenFiles" \( -type f -or -type l \) \
              -exec bash ${link} "$newGenFiles" {} +
          }

          function cleanOldGen() {
            if [[ ! -v oldGenPath ]] ; then
              return
            fi

            echo "Cleaning up orphan links from $HOME"

            local newGenFiles oldGenFiles
            newGenFiles="$(readlink -e "$newGenPath/home-files")"
            oldGenFiles="$(readlink -e "$oldGenPath/home-files")"

            # Apply the cleanup script on each leaf in the old
            # generation. The find command below will print the
            # relative path of the entry.
            find "$oldGenFiles" '(' -type f -or -type l ')' -printf '%P\0' \
              | xargs -0 bash ${cleanup} "$oldGenFiles" "$newGenFiles"
          }

          cleanOldGen

          if [[ ! -v oldGenPath || "$oldGenPath" != "$newGenPath" ]] ; then
            echo "Creating profile generation $newGenNum"
            $DRY_RUN_CMD nix-env $VERBOSE_ARG --profile "$genProfilePath" --set "$newGenPath"
            $DRY_RUN_CMD ln -Tsf $VERBOSE_ARG "$newGenPath" "$newGenGcPath"
          else
            echo "No change so reusing latest profile generation $oldGenNum"
          fi

          linkNewGen
        ''
    );

    home.activation.checkFilesChanged = hm.dag.entryBefore ["linkGeneration"] (
      ''
        declare -A changedFiles
      '' + concatMapStrings (v: ''
        cmp --quiet "${sourceStorePath v}" "${homeDirectory}/${v.target}" \
          && changedFiles["${v.target}"]=0 \
          || changedFiles["${v.target}"]=1
      '') (filter (v: v.onChange != "") (attrValues cfg))
    );

    home.activation.onFilesChange = hm.dag.entryAfter ["linkGeneration"] (
      concatMapStrings (v: ''
        if [[ ${"$\{changedFiles"}["${v.target}"]} -eq 1 ]]; then
          ${v.onChange}
        fi
      '') (filter (v: v.onChange != "") (attrValues cfg))
    );

    # Symlink directories and files that have the right execute bit.
    # Copy files that need their execute bit changed.
    home-files = pkgs.runCommand
      "home-manager-files"
      {
        nativeBuildInputs = [ pkgs.xlibs.lndir ];
        preferLocalBuild = true;
        allowSubstitutes = false;
      }
      (''
        mkdir -p $out

        # Needed in case /nix is a symbolic link.
        realOut="$(realpath -m "$out")"
        copylist="$(realpath -m "$realOut/${copyAccumulator}")"
        touch "$copylist"

        function insertFile() {
          local source="$1"
          local relTarget="$2"
          local executable="$3"
          local recursive="$4"
          local copy="$5"

          # Figure out the real absolute path to the target.
          local target
          target="$(realpath -m "$realOut/$relTarget")"

          # Target path must be within $HOME.
          if [[ ! $target == $realOut* ]] ; then
            echo "Error installing file '$relTarget' outside \$HOME" >&2
            exit 1
          fi

          mkdir -p "$(dirname "$target")"
          if [[ -d $source ]]; then
            if [[ $recursive || $copy ]]; then
              mkdir -p "$target"
              lndir -silent "$source" "$target"
              if [[ $copy ]]; then
                find "$source" -type f -printf '%P\0' | xargs -0 -n 1 -I '{}' echo "$relTarget/{}" >> "$copylist"
              fi
            else
              ln -s "$source" "$target"
            fi
          else
            [[ -x $source ]] && isExecutable=1 || isExecutable=""

            # Link the file into the home file directory if possible,
            # i.e., if the executable bit of the source is the same we
            # expect for the target. Otherwise, we copy the file and
            # set the executable bit to the expected value.
            if [[ $executable == inherit || $isExecutable == $executable ]]; then
              ln -s "$source" "$target"
            else
              cp "$source" "$target"

              if [[ $executable == inherit ]]; then
                # Don't change file mode if it should match the source.
                :
              elif [[ $executable ]]; then
                chmod +x "$target"
              else
                chmod -x "$target"
              fi
            fi
            if [[ $copy ]]; then
              echo "$relTarget" >> "$copylist"
            fi
          fi
        }
      '' + concatStrings (
        mapAttrsToList (n: v: ''
          insertFile "${sourceStorePath v}" \
                     "${v.target}" \
                     "${if v.executable == null
                        then "inherit"
                        else builtins.toString v.executable}" \
                     "${builtins.toString v.recursive}" \
                     "${builtins.toString v.copy}"
        '') cfg
      ));
  };
}
