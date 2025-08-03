{pkgs, ...}: {
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
  };
}
