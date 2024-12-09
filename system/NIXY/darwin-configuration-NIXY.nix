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
    ./modules/dipshit-macos-permissions.nix
    # ./modules/openssh.nix

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
    # optimise.automatic = true;
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
      ln -sf "${inputs.nixpkgs.legacyPackages.aarch64-darwin.jdk23}/zulu-23.jdk" "/Library/Java/JavaVirtualMachines/"
    '';

    postUserActivation.text =
    let
      systemType = pkgs.stdenv.hostPlatform.system;
      homebrewPath = if systemType == "aarch64-darwin" then "/opt/homebrew/bin" else if systemType == "x86_64-darwin" then "/usr/local/bin" else throw "Homebrew Unsupported architecture: ${systemType}";
      inherit (config.colorScheme) palette;
      desktoppr = "/usr/local/bin/desktoppr";
      wallpaper = "/Users/Shared/Wallpaper/wallpaper-nix-colors.png";
      m = "${homebrewPath}/m";
    in
    ''
      echo "Recoloring Wallpapers to ${config.colorscheme.slug} color scheme..."
      mkdir -p /Users/Shared/Wallpaper/
      ${pkgs.python3.withPackages (ps: [ ps.pillow ps.numpy ps.tqdm ])}/bin/python3 ${./../../users/alex/extraConfig/recolor_base16_inputs_efficient.py} ${./../../users/alex/extraConfig/wallpapers/gruvbox-nix.png} /Users/Shared/Wallpaper/wallpaper-nix-colors.png ${config.colorScheme.variant} ${palette.base00},${palette.base01},${palette.base02},${palette.base03},${palette.base04},${palette.base05},${palette.base06},${palette.base07},${palette.base08},${palette.base09},${palette.base0A},${palette.base0B},${palette.base0C},${palette.base0D},${palette.base0E},${palette.base0F}
      echo "Setting ${config.colorscheme.variant} wallpaper..."
      ${m} wallpaper "${wallpaper}"
      # fix a bug with desktoppr not updating the desktop immediately
      echo "Wallpapers recolored!"

      # set darkmode/lightmode for the system
      echo "Setting ${config.colorscheme.variant}mode for the system..."
      toggle-darkmode ${config.colorscheme.variant}
    '';
  };
}
