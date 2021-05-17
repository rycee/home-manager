{ config, lib, pkgs, ... }:
with lib; {
  config = {
    programs.wezterm = {
      enable = true;

      keybindings = [
        {
          modifiers = [ ];
          key = "l";
        }
        {
          key = "l";
          action = "wezterm.action {ActivateTabRelative = 1}";
        }
        {
          modifiers = [ "SHIFT" "CTRL" ];
          key = "h";
          action = "wezterm.action {ActivateTabRelative = -1}";
        }
      ];

      mousebindings = [
        {
          button = "Left";
          event = "Up";
          count = 1;
          modifiers = [ "CTRL" ];
          action = ''"OpenLinkAtMouseCursor"'';
        }
        {
          button = "Right";
          event = "Down";
          count = 1;
          action = ''wezterm.action { SendString = "woot" }'';
        }
      ];

      settings = {
        enable_wayland = true;
        font_size = 10.0;
        line_height = 1.0;
      };

      extraSettings = ''
        wezterm.on("trigger-vim-with-scrollback", function(window, pane)
          local scrollback = pane:get_lines_as_text();

          local name = os.tmpname();
          local f = io.open(name, "w+");
          f:write(scrollback);
          f:flush();
          f:close();

          window:perform_action(wezterm.action{SpawnCommandInNewWindow={
            args={"vim", name}}
          }, pane)

          wezterm.sleep_ms(1000);
          os.remove(name);
        end)
      '';

      extraReturnSettings = ''
        font = wezterm.font("FiraCode Nerd Font Mono"),
      '';
    };

    nmt.script = ''
      assertFileContent \
        home-files/.config/wezterm/wezterm.lua \
        ${./everything-expected.lua}
    '';
  };
}
