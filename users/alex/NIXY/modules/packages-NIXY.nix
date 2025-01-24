{
  pkgs,
  config,
  lib,
  ...
}:

let
  systemType = pkgs.stdenv.hostPlatform.system;
  homebrewPath =
    if systemType == "aarch64-darwin" then
      "/opt/homebrew/bin"
    else if systemType == "x86_64-darwin" then
      "/usr/local/bin"
    else
      throw "Homebrew Unsupported architecture: ${systemType}";
  jq = "${pkgs.jq}/bin/jq";
  yabai = "${homebrewPath}/yabai";
  sketchybar = "${homebrewPath}/sketchybar";
  borders = "${homebrewPath}/borders";
  skhd = "${homebrewPath}/skhd";
  inherit (config.colorScheme) palette;
in
{
  nixpkgs = {
    config = {
      allowUnfree = true;
      #allowUnfreePredicate = (_: true);
      allowUnsupportedSystem = false;
      allowBroken = false;
    };
  };

  home.packages = with pkgs; [
    # autotiling
    #ncdu
    calcurse
    losslesscut-bin
    chatgpt-cli
    cowsay
    cmus
    cmusfm
    bat
    flameshot
    newsboat
    audacity
    pkgconf
    # ncurses
    nmap
    neofetch
    darwin.cctools-port # is it needed tho?
    tshark
    termshark
    ffmpeg
    tigervnc
    gcal
    # wireshark
    # nmapsi4
    #ruby
    obs-cmd # remotely start/stop recording using cli and obs-websocket plugin
    obsidian
    libnotify
    sl
    asciidoctor
    fzf
    lavat
    libsForQt5.ki18n
    # bonsai #Only available on mac?
    rustc
    tt
    obsidian
    cargo
    utm
    mas
    vscode
    audacity
    #yazi to upgrade temporarily with homebrew
    thefuck
    zsh-completions
    zoom-us
    unar
    # python39
    (pkgs.python311.withPackages (ps: [
      ps.tkinter
      ps.pygame
      ps.pandas
      ps.termcolor
      ps.plyvel
      ps.opencv4
      ps.tqdm
      ps.pillow
      ps.numpy
      ps.torch
      ps.torchvision
      ps.diffusers
      ps.transformers
      ps.accelerate
      ps.raylib-python-cffi
      # ps.sklearn-deap
      #ps.pyautogui # broken
      # ps.pep517
      ps.biplist
      # ps.build
      #ps.i3ipc
      #ps.matplotlib # broken macos atm?
      ps.frida
    ]))
    # Frida packages
    fridaPackages.frida-tools # CLI tools like frida-ps, frida-ls-devices, etc.
  ];
}
