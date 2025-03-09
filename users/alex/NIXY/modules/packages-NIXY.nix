{
  pkgs,
  ...
}:

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
    calcurse
    chatgpt-cli
    cowsay
    cmus
    cmusfm
    bat
    pmbootstrap
    newsboat
    pkgconf
    nmap
    ffmpeg
    gcal
    sops
    # wireshark
    # nmapsi4
    #ruby
    obsidian
    libnotify
    asciidoctor
    fzf
    lavat
    # bonsai #Only available on mac?
    tt
    obsidian
    cargo
    mas
    thefuck
    zsh-completions
    zoom-us
    unar
    # python39
    (pkgs.python311.withPackages (ps: [
      ps.tkinter
      ps.pygame
      ps.pandas
      ps.moviepy
      ps.termcolor
      ps.plyvel
      ps.opencv4
      ps.tqdm
      ps.pillow
      ps.pillow-heif
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
