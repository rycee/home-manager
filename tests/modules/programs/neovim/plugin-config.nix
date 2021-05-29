{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.neovim = {
      enable = true;
      extraConfig = ''
        " This should be present in vimrc
      '';
      plugins = with pkgs.vimPlugins; [
        vim-nix
        {
          plugin = vim-commentary;
          config = ''
            " This should be present too
            autocmd FileType c setlocal commentstring=//\ %s
            autocmd FileType c setlocal comments=://
          '';
        }
      ];
      extraLuaPackages = [
        pkgs.lua51Packages.luautf8
      ];
    };

    nmt.script = ''
      vimrc="$TESTED/home-files/.config/nvim/init.vim"
      assertFileExists home-files/.config/nvim/init.vim
      # We need to remove the unkown store paths in the config
      TESTED="" assertFileContent \
        <( ${pkgs.perl}/bin/perl -pe "s|\Q$NIX_STORE\E/[a-z0-9]{32}-|$NIX_STORE/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-|g" < "$vimrc"
         ) \
        "${./plugin-config.vim}"
    '';
  };
}

