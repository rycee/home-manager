{ runCommand, lib, bash, coreutils, findutils, gettext, gnused, less

# Extra path to Home Manager. If set then this path will be tried
# before `$HOME/.config/nixpkgs/home-manager` and
# `$HOME/.nixpkgs/home-manager`.
, path ? null }:

let

  pathStr = if path == null then "" else path;

in runCommand "home-manager" {
  preferLocalBuild = true;
  allowSubstitutes = false;
  nativeBuildInputs = [ gettext ];
  meta = with lib; {
    description = "A user environment configurator";
    maintainers = [ maintainers.rycee ];
    platforms = platforms.unix;
    license = licenses.mit;
  };
} ''
  install -v -D -m755  ${./home-manager} $out/bin/home-manager

  substituteInPlace $out/bin/home-manager \
    --subst-var-by bash "${bash}" \
    --subst-var-by coreutils "${coreutils}" \
    --subst-var-by findutils "${findutils}" \
    --subst-var-by gettext "${gettext}" \
    --subst-var-by gnused "${gnused}" \
    --subst-var-by less "${less}" \
    --subst-var-by HOME_MANAGER_PATH '${pathStr}' \
    --subst-var-by TEXTDOMAINDIR "$out/share/locale"

  install -D -m755 ${./completion.bash} \
    $out/share/bash-completion/completions/home-manager
  install -D -m755 ${./completion.zsh} \
    $out/share/zsh/site-functions/_home-manager

  mkdir -p $out/share/locale/sv/LC_MESSAGES
  msgfmt -o $out/share/locale/sv/LC_MESSAGES/home-manager.mo ${./po/sv.po}
''
