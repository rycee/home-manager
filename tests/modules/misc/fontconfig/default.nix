{
  fontconfig-no-font-package = ./no-font-package.nix;
  fontconfig-single-font-package = ./single-font-package.nix;
  # Disabled due to test failing with message
  #
  #  Expected directory home-path/lib/fontconfig/cache to exist but it was not found.
  #
  # Verbose output from fc-cache:
  #
  #  Font directories:
  #          /nix/store/da…g5-home-manager-path/lib/X11/fonts
  #          /nix/store/da…g5-home-manager-path/share/fonts
  #          /nix/store/da…g5-home-manager-path/share/fonts/truetype
  #  /nix/store/da…g5-home-manager-path/lib/X11/fonts: skipping, no such directory
  #  /nix/store/da…g5-home-manager-path/share/fonts: caching, new cache contents: 1 fonts, 1 dirs
  #  /nix/store/da…g5-home-manager-path/share/fonts/truetype: caching, new cache contents: 3 fonts, 0 dirs
  #  /nix/store/da…g5-home-manager-path/share/fonts/truetype: skipping, looped directory detected
  #  /nix/store/da…g5-home-manager-path/lib/fontconfig/cache: cleaning cache directory
  #  /nix/store/da…g5-home-manager-path/lib/fontconfig/cache: invalid cache file: 786068e7df13f7c2105017ef3d78e351-x86_64.cache-7
  #  /nix/store/da…g5-home-manager-path/lib/fontconfig/cache: invalid cache file: 4766193978ddda4bd196f2b98c00fb00-x86_64.cache-7
  #fontconfig-multiple-font-packages = ./multiple-font-packages.nix;
  fontconfig-simple = ./simple.nix;
  fontconfig-complex = ./complex.nix;
}
