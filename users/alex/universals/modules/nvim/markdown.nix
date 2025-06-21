{ pkgs, ... }:

{
  programs.nixvim.plugins = {
    # Note-taking
    obsidian = {
      enable = false; # Cross that bridge when we get there...
      settings = {
        new_notes_location = "current_dir";
        workspaces = [
          {
            name = "work";
            path = "~/obsidian/work";
          }
          {
            name = "school";
            path = "~/obsidian/school";
          }
        ];
      };
    };

    neorg = {
      enable = true;
      settings.load = {
        "core.defaults" = {
          # Load all the default modules
        };
        "core.concealer" = {
          # Allows for the use of icons
        };
        "core.dirman" = {
          # Manages workspaces and directories
        };
      };
    };

    markdown-preview = {
      enable = true;
      settings = {
        auto_close = 1;
        auto_start = 1;
        browser = "firefox";
        browserfunc = "";
        combine_preview = 0;
        combine_preview_auto_refresh = 1;
        command_for_global = 0;
        echo_preview_url = 1;
        filetypes = [ "markdown" ];
        highlight_css = "";
        images_path = "";
        markdown_css = "";
        open_ip = "";
        open_to_the_world = 0;
        page_title = "MarkdownPreview";
        port = "8080";
        refresh_slow = 0;
        theme = "dark";
      };
    };
  };
}
