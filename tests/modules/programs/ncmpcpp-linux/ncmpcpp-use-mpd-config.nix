{ pkgs, ... }:

{
  config = {
    programs.ncmpcpp.enable = true;

    services.mpd.daemons.default.enable = true;
    services.mpd.daemons.default.musicDirectory = "/home/user/music";

    nixpkgs.overlays = [
      (self: super: {
        ncmpcpp = pkgs.writeScriptBin "dummy-ncmpcpp" "";
        mpd = pkgs.writeScriptBin "dummy-mpd" "";
      })
    ];

    nmt.script = ''
      assertFileContent \
        home-files/.config/ncmpcpp/config \
        ${./ncmpcpp-use-mpd-config-expected-config}

      assertPathNotExists home-files/.config/ncmpcpp/bindings
    '';
  };
}
