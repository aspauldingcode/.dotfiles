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
    text = let inherit (config.colorScheme) colors; in /* */ ''
    #Bashtop gruvbox (https://github.com/morhetz/gruvbox) theme
    #by BachoSeven

    # Colors should be in 6 or 2 character hexadecimal or single spaced rgb decimal: "#RRGGBB", "#BW" or "0-255 0-255 0-255"
    # example for white: "#FFFFFF", "#ff" or "255 255 255".

    # All graphs and meters can be gradients
    # For single color graphs leave "mid" and "end" variable empty.
    # Use "start" and "end" variables for two color gradient
    # Use "start", "mid" and "end" for three color gradient

    # Main background, empty for terminal default, need to be empty if you want transparent background
    theme[main_bg]="#1d2021"

    # Main text color
    theme[main_fg]="#a89984"

    # Title color for boxes
    theme[title]="#ebdbb2"

    # Higlight color for keyboard shortcuts
    theme[hi_fg]="#d79921"

    # Background color of selected items
    theme[selected_bg]="#282828"

    # Foreground color of selected items
    theme[selected_fg]="#fabd2f"

    # Color of inactive/disabled text
    theme[inactive_fg]="#282828"

    # Color of text appearing on top of graphs, i.e uptime and current network graph scaling
    theme[graph_text]="#585858"

    # Misc colors for processes box including mini cpu graphs, details memory graph and details status text
    theme[proc_misc]="#98971a"

    # Cpu box outline color
    theme[cpu_box]="#a89984"

    # Memory/disks box outline color
    theme[mem_box]="#a89984"

    # Net up/down box outline color
    theme[net_box]="#a89984"

    # Processes box outline color
    theme[proc_box]="#a89984"

    # Box divider line and small boxes line color
    theme[div_line]="#a89984"

    # Temperature graph colors
    theme[temp_start]="#458588"
    theme[temp_mid]="#d3869b"
    theme[temp_end]="#fb4394"

    # CPU graph colors
    theme[cpu_start]="#b8bb26"
    theme[cpu_mid]="#d79921"
    theme[cpu_end]="#fb4934"

    # Mem/Disk free meter
    theme[free_start]="#4e5900"
    theme[free_mid]=""
    theme[free_end]="#98971a"

    # Mem/Disk cached meter
    theme[cached_start]="#458588"
    theme[cached_mid]=""
    theme[cached_end]="#83a598"

    # Mem/Disk available meter
    theme[available_start]="#d79921"
    theme[available_mid]=""
    theme[available_end]="#fabd2f"

    # Mem/Disk used meter
    theme[used_start]="#cc241d"
    theme[used_mid]=""
    theme[used_end]="#fb4934"

    # Download graph colors
    theme[download_start]="#3d4070"
    theme[download_mid]="#6c71c4"
    theme[download_end]="#a3a8f7"

    # Upload graph colors
    theme[upload_start]="#701c45"
    theme[upload_mid]="#b16286"
    theme[upload_end]="#d3869b"
    '';
  };
}
