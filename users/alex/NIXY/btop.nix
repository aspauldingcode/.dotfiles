{ config, ... }:

# configure btop, and give btop a nix-colors enabled theme.
{

  programs.btop = {
    enable = true;
    settings = {
      color_theme = "nix-colors";
      theme_background = true;
      truecolor = true;
      force_tty = false;
      presets = "cpu:1:default,proc:0:default cpu:0:default,mem:0:default,net:0:default cpu:0:block,net:0:tty";
      vim_keys = false;
      rounded_corners = true;
      graph_symbol = "braille";
      graph_symbol_cpu = "default";
      graph_symbol_mem = "default";
      graph_symbol_net = "default";
      graph_symbol_proc = "default";
      shown_boxes = "mem net proc";
      update_ms = 2000;
      proc_sorting = "cpu lazy";
      proc_reversed = false;
      proc_tree = false;
      proc_colors = true;
      proc_gradient = true;
      proc_per_core = false;
      proc_mem_bytes = true;
      proc_cpu_graphs = true;
      proc_info_smaps = false;
      proc_left = false;
      proc_filter_kernel = false;
      proc_aggregate = false;
      cpu_graph_upper = "total";
      cpu_graph_lower = "total";
      cpu_invert_lower = true;
      cpu_single_graph = false;
      cpu_bottom = false;
      show_uptime = true;
      check_temp = true;
      cpu_sensor = "Auto";
      show_coretemp = true;
      cpu_core_map = "";
      temp_scale = "celsius";
      base_10_sizes = false;
      show_cpu_freq = true;
      clock_format = "%X";
      background_update = true;
      custom_cpu_name = "";
      disks_filter = "";
      mem_graphs = true;
      mem_below_net = false;
      zfs_arc_cached = true;
      show_swap = true;
      swap_disk = true;
      show_disks = true;
      only_physical = true;
      use_fstab = true;
      zfs_hide_datasets = false;
      disk_free_priv = false;
      show_io_stat = true;
      io_mode = false;
      io_graph_combined = false;
      io_graph_speeds = "";
      net_download = 100;
      net_upload = 100;
      net_auto = true;
      net_sync = true;
      net_iface = "";
      show_battery = true;
      selected_battery = "Auto";
      log_level = "WARNING";
    };
  };

  home.file.btop = {
    #executable = true;
    target = ".config/btop/themes/nix-colors.theme";
    text =
      let
        inherit (config.colorScheme) colors;
      in
      # python
      ''
        # Colors should be in 6 or 2 character hexadecimal or single spaced rgb decimal: "#RRGGBB", "#BW" or "0-255 0-255 0-255"
        # example for white: "#FFFFFF", "#ff" or "255 255 255".

        # All graphs and meters can be gradients
        # For single color graphs leave "mid" and "end" variable empty.
        # Use "start" and "end" variables for two color gradient
        # Use "start", "mid" and "end" for three color gradient

        # Main background, empty for terminal default, need to be empty if you want transparent background
        theme[main_bg]="#${colors.base00}"

        # Main text color
        theme[main_fg]="#${colors.base04}"

        # Title color for boxes
        theme[title]="#${colors.base05}"

        # Higlight color for keyboard shortcuts
        theme[hi_fg]="#${colors.base0A}"

        # Background color of selected items
        theme[selected_bg]="#${colors.base02}"

        # Foreground color of selected items
        theme[selected_fg]="#${colors.base0A}"

        # Color of inactive/disabled text
        theme[inactive_fg]="#${colors.base03}"

        # Color of text appearing on top of graphs, i.e uptime and current network graph scaling
        theme[graph_text]="#${colors.base03}"

        # Misc colors for processes box including mini cpu graphs, details memory graph and details status text
        theme[proc_misc]="#${colors.base04}"

        # Cpu box outline color
        theme[cpu_box]="#${colors.base03}"

        # Memory/disks box outline color
        theme[mem_box]="#${colors.base02}"

        # Net up/down box outline color
        theme[net_box]="#${colors.base02}"

        # Processes box outline color
        theme[proc_box]="#${colors.base02}"

        # Box divider line and small boxes line color
        theme[div_line]="#${colors.base02}"

        # Temperature graph colors
        theme[temp_start]="#${colors.base0A}"
        theme[temp_mid]="#${colors.base0A}"
        theme[temp_end]="#${colors.base08}"

        # CPU graph colors
        theme[cpu_start]="#${colors.base0B}"
        theme[cpu_mid]="#${colors.base0B}"
        theme[cpu_end]="#${colors.base0B}"

        # Mem/Disk free meter
        theme[free_start]="#${colors.base0B}"
        theme[free_mid]=""
        theme[free_end]="#${colors.base0B}"

        # Mem/Disk cached meter
        theme[cached_start]="#${colors.base0D}"
        theme[cached_mid]=""
        theme[cached_end]="#${colors.base0D}"

        # Mem/Disk available meter
        theme[available_start]="#${colors.base0A}"
        theme[available_mid]=""
        theme[available_end]="#${colors.base0A}"

        # Mem/Disk used meter
        theme[used_start]="#${colors.base08}" # make darker?
        theme[used_mid]=""
        theme[used_end]="#${colors.base08}" 

        # Download graph colors
        theme[download_start]="#${colors.base0E}"
        theme[download_mid]="#${colors.base0F}"
        theme[download_end]="#${colors.base06}"

        # Upload graph colors
        theme[upload_start]=
        theme[upload_mid]="#${colors.base0E}"
        theme[upload_end]="#${colors.base0F}"
      '';
  };
}
