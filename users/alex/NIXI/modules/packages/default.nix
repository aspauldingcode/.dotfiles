{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # calcurse
    chatgpt-cli
    # jetbrains.idea-community-bin
    unstable.jetbrains.clion
    cowsay
    # cmus
    nix-search-cli
    # cmusfm
    # bat
    hashcat
    # pmbootstrap # FIXME: breaks?
    # newsboat
    utm
    sops
    age
    gh
    pkgconf
    nmap
    # filezilla # no darwin support nixpkgs derivation
    ffmpeg
    unstable.gowall
    gcal
    sops
    # wireshark
    # nmapsi4
    #ruby
    obsidian
    libnotify
    asciidoctor
    fzf
    # tigervnc
    lavat
    # bonsai #Only available on mac?
    tt
    obsidian
    unstable.cargo
    mas
    pay-respects # replacement for thefuck which was removed
    zsh-completions
    zoom-us
    unar
    # python39
    # (pkgs.python311.withPackages (ps: [
    #   ps.tkinter
    #   ps.pygame
    #   ps.pandas
    #   ps.moviepy
    #   ps.termcolor
    #   ps.plyvel
    #   ps.opencv4
    #   ps.tqdm
    #   ps.pillow
    #   ps.pillow-heif
    #   ps.numpy
    #   ps.torch
    #   ps.torchvision
    #   ps.diffusers
    #   ps.transformers
    #   ps.accelerate
    #   ps.raylib-python-cffi
    #   # ps.sklearn-deap
    #   #ps.pyautogui # broken
    #   # ps.pep517
    #   ps.biplist
    #   # ps.build
    #   #ps.i3ipc
    #   #ps.matplotlib # broken macos atm?
    #   ps.frida
    # ]))
    # Frida packages
    # fridaPackages.frida-tools # CLI tools like frida-ps, frida-ls-devices, etc.
  ];
}
