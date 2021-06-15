{ config, lib, pkgs, ... }:

with lib;

let
  dummy-gnome-shell-extensions = pkgs.runCommand "dummy-package" { } ''
    mkdir -p $out/share/gnome-shell/extensions/dummy-package
    touch $out/share/gnome-shell/extensions/dummy-package/test
  '';

  test-extension = pkgs.runCommand "test-extension" { } ''
    mkdir -p $out/share/gnome-shell/extensions/test-extension
    touch $out/share/gnome-shell/extensions/test-extension/test
  '';

  test-extension-uuid =
    pkgs.runCommand "test-extension-uuid" { uuid = "test-extension-uuid"; } ''
      mkdir -p $out/share/gnome-shell/extensions/test-extension-uuid
      touch $out/share/gnome-shell/extensions/test-extension-uuid/test
    '';

  test-theme = pkgs.runCommand "test-theme" { } ''
    mkdir -p $out/share/themes/Test/gnome-shell
    touch $out/share/themes/Test/gnome-shell/test
  '';

  expectedEnabledExtensions = [
    "user-theme@gnome-shell-extensions.gcampax.github.com"
    "test-extension"
    "test-extension-uuid"
  ];

  actualEnabledExtensions =
    catAttrs "value" config.dconf.settings."org/gnome/shell".enabled-extensions;

in {
  nixpkgs.overlays = [
    (self: super: {
      gnome3 = super.gnome3.overrideScope' (gself: gsuper: {
        gnome-shell-extensions = dummy-gnome-shell-extensions;
      });
    })
  ];

  programs.gnome-shell.enable = true;

  programs.gnome-shell.extensions = [
    {
      id = "test-extension";
      package = test-extension;
    }
    { package = test-extension-uuid; }
  ];

  programs.gnome-shell.theme = {
    name = "Test";
    package = test-theme;
  };

  assertions = [
    {
      assertion =
        config.dconf.settings."org/gnome/shell".disable-user-extensions
        == false;
      message = "Expected disable-user-extensions to be false.";
    }
    {
      assertion =
        all (e: elem e actualEnabledExtensions) expectedEnabledExtensions;
      message = ''
        Expected enabled-extensions to contain all of:
          ${toString expectedEnabledExtensions}
        But it was:
          ${toString actualEnabledExtensions}
      '';
    }
    {
      assertion =
        config.dconf.settings."org/gnome/shell/extensions/user-theme".name
        == "Test";
      message = "Expected extensions/user-theme/name to be 'Test'.";
    }
  ];

  nmt.script = ''
    assertFileExists home-path/share/gnome-shell/extensions/dummy-package/test
    assertFileExists home-path/share/gnome-shell/extensions/test-extension/test
    assertFileExists home-path/share/gnome-shell/extensions/test-extension-uuid/test
    assertFileExists home-path/share/themes/Test/gnome-shell/test
  '';
}
