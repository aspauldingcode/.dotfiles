{ pkgs, ... }:
### System Configuration.nix for Darwin
{
  imports = [
    ./packages.nix
    ./darwin-sudoers.nix
    ./darwin-defaults.nix
    ./homebrew-pkgs.nix
    ./yabai-sa.nix
    ./wg-quick.nix
  ];
  # Allow Unfree
  nixpkgs.config.allowUnsupportedSystem = true;

  fonts.fontDir.enable = true;
  fonts.fonts = with pkgs; [
    dejavu_fonts
    powerline-fonts
    powerline-symbols
    font-awesome_5
    jetbrains-mono
    # (pkgs.callPackage ./apple-fonts.nix {})
    (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" "Hack" ]; })
  ];
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

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true;  # default shell on catalina
  programs.bash.enable = true;
  programs.fish.enable = true; #NOT Borne COMPAT? 
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
       interval = {
         Hour = 24; # Automaitcally collect garbage each day
       };
       options = ""; # Example: "--max-freed $((64 * 1024**3))"
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
  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
