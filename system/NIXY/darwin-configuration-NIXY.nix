{ config, pkgs, inputs, ... }:
### System Configuration.nix for Darwin
{
  imports = [
    ./scripts-NIXY.nix
    ./modules/homebrew-pkgs.nix
    ./modules/darwin-defaults.nix
    ./modules/launch-agents.nix
    # ./modules/yabai-sa.nix
    # ./modules/wg-quick.nix
    ./modules/packages.nix
    ./modules/theme.nix

    # ./customDerivations/apple-fonts.nix
    # ./customDerivations/mousecape.nix
    # ./customDerivations/macforge.nix
    # ./customDerivations/cursorcerer.nix
    # ./customDerivations/instantview.nix
    ./customDerivations/recording-indicator-utility.nix
    # ./customDerivations/okular.nix

    ./modules/windowManagement/borders.nix
    ./modules/windowManagement/cursorcerer.nix
    ./modules/windowManagement/karabiner.nix
    ./modules/windowManagement/macforge.nix
    ./modules/windowManagement/yabai.nix
    ./modules/windowManagement/sketchybar.nix
    ./modules/windowManagement/skhd.nix
    ./modules/windowManagement/toggle-scripts.nix
    ./modules/windowManagement/unmenu.nix
    # ./modules/nix-the-planet.nix
  ];
  # programs.okular.enable = true;

  fonts = {
    packages = with pkgs; [
      dejavu_fonts
      powerline-fonts
      powerline-symbols
      font-awesome_5
      jetbrains-mono
      # (pkgs.callPackage ./apple-fonts.nix {})
      (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" "Hack" ]; })
    ];
  };
  # system.build = builtins.exec "echo 'hello, world.'";
  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  networking = {
    computerName = "NIXY"; # REQUIRED! "NIXY" to build nix flakes
    #FIXME: first install - Check to see if it works with computerName!
    # OTHERWISE: 'scutil --set NIXY' for the first time install.
    hostName = "NIXY";
    localHostName = "NIXY";
    knownNetworkServices = [
      "AX88179A"
      "USB 10/100 LAN"
      "Thunderbolt Bridge"
      "Wi-Fi"
    ];
  };

  #Sudoer's file to symlink. removes the need for a password for the admin group
  environment.etc."sudoers.d/admin-no-passwd".text = ''
    %admin ALL = (ALL) NOPASSWD: ALL
  '';

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs = {
    zsh.enable = true;  # default shell on catalina
    bash.enable = true;
    fish.enable = true; #NOT Borne COMPAT? 
    # Recording Indicator Utility
    recordingIndicatorUtility = {
      enable = true;
      # package = pkgs.recordingIndicatorUtility;
      showIndicator = false;
      showWarning = false;
    };
    # unmenu = {
      # enable = true;
    #   qwerty/Hotkey = "alt-d";
    #   findApps = true;
    #   findExecutables = true;
    #   dirs = [
    #     "/System/Applications/"
    #     "/Applications/"
    #   ];
    # };
  };

  users.users.alex.shell = pkgs.zsh; 
  nix = {
    # https://nixos.wiki/wiki/Distributed_build
    # distributedBuilds = false; # set true after configuration
    # buildMachines = [ ]; #FIXME: add NIXSTATION64 as a builder!
    # below are per build machine (* is the entry of the machine in the list above)
    # buildMachines.*.hostName = ""; # Example: "nixbuilder.example.org"
    # buildMachines.*.mandatoryFeatures
    # buildMachines.*.maxJobs
    # nix.buildMachines.*.protocol
    # nix.buildMachines.*.publicHostKey
    # nix.buildMachines.*.speedFactor
    # nix.buildMachines.*.sshKey
    # nix.buildMachines.*.sshUser
    # nix.buildMachines.*.supportedFeatures = [ "kvm" "big-parallel" ];
    # nix.buildMachines.*.systems = [ "x86_64-linux" "aarch64-linux" ];

    gc = {
      automatic = true;
      interval.Hour = 23; # Automaitcally collect garbage each day
      options = "--delete-older-than 30d --delete-old-generations 10"; 
    };
    settings = {
      auto-optimise-store = true;
      # FIXME: add cahcix.nixos.org so I don't have to rebuild home-manager all the time
      # substituters = [ 
      #   "https://cache.nixos.org/" 
      # ];
      # trusted-public-keys = [ 
      #   "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs=" 
      # ]; # By default, only the key for cache.nixos.org is included
      # trusted-substituters = [
      #   "https://hydra.nixos.org/"
      # ];
      trusted-users = [
        "root"
        "@admin" # anyone in the wheel group
      ];
    };
    extraOptions = ''
    extra-platforms = aarch64-darwin x86_64-darwin
    experimental-features = nix-command flakes
    '';
  };

  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    config = {
      allowUnfree = true;
      allowUnfreePredictate = (_: true);
      allowUnsupportedSystem = true;
    };
  };

  # system.activationScripts.script.text = ''
    # cp /home/alex/.dotfiles/users/alex/face.png /var/lib/AccountsService/icons/alex
  # '';

  #system.activationScripts.extraActivation.text = ''
  #  ln -sf "${inputs.nixpkgs.legacyPackages.aarch64-darwin.jdk20}/zulu-20.jdk" "/Library/Java/JavaVirtualMachines/"
  #'';

  system.stateVersion = 5;
  system.activationScripts = {
    extraActivation.text = ''
      # symlink (zulu) jdk22 to /Library/Java/JavaVirtualMachines/ # NEEDED for macOS!!
      ln -sf "${inputs.nixpkgs.legacyPackages.aarch64-darwin.jdk22}/zulu-22.jdk" "/Library/Java/JavaVirtualMachines/"
    '';

    postUserActivation.text =
    let
      inherit (config.colorScheme) colors;
    in
    ''
      rsyncArgs="--archive --checksum --chmod=-w --copy-unsafe-links --delete"
      apps_source="${config.system.build.applications}/Applications"
      moniker="Nix Trampolines"
      app_target_base="$HOME/Applications"
      app_target="$app_target_base/$moniker"
      mkdir -p "$app_target"
      ${pkgs.rsync}/bin/rsync $rsyncArgs "$apps_source/" "$app_target"

      echo "Recoloring Wallpapers..."
      mkdir -p /Users/Shared/Wallpaper/
      ${pkgs.python3.withPackages (ps: [ ps.pillow ps.numpy ps.tqdm ])}/bin/python3 ${./../../users/alex/extraConfig/recolor_base16_hue_filter_efficient.py} ${./../../users/alex/extraConfig/wallpapers/galaxy.png} /Users/Shared/Wallpaper/wallpaper-nix-colors.png ${colors.base00},${colors.base01},${colors.base02},${colors.base03},${colors.base04},${colors.base05},${colors.base06},${colors.base07},${colors.base08},${colors.base09},${colors.base0A},${colors.base0B},${colors.base0C},${colors.base0D},${colors.base0E},${colors.base0F}
      echo "Wallpapers recolored!"
    '';
  };
}
