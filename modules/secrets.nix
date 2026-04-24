{
  flake.modules.nixos.secrets = { pkgs, inputs, ... }: {
    imports = [ inputs.sops-nix.nixosModules.sops ];

    environment.systemPackages = with pkgs; [
      sops
      age
    ];

    sops = {
      defaultSopsFormat = "yaml";
      defaultSopsFile = ../secrets/secrets.yaml; # Ensure this file exists before applying
      age = {
        keyFile = "/var/lib/sops-nix/key.txt"; # Rotatable age key
        generateKey = true; # Generate if missing
      };
    };
  };

  flake.modules.darwin.secrets = { pkgs, inputs, ... }: {
    imports = [ inputs.sops-nix.darwinModules.sops ];

    environment.systemPackages = with pkgs; [
      sops
      age
    ];

    sops = {
      defaultSopsFormat = "yaml";
      defaultSopsFile = ../secrets/secrets.yaml;
      age.keyFile = "/var/lib/sops-nix/key.txt";
    };
  };

  flake.modules.homeManager.secrets = { pkgs, inputs, ... }: {
    imports = [ inputs.sops-nix.homeManagerModules.sops ];

    home.packages = with pkgs; [
      sops
      age
    ];

    sops = {
      defaultSopsFormat = "yaml";
      defaultSopsFile = ../secrets/secrets.yaml;
      age.keyFile = "/home/admin/.config/sops/age/keys.txt";
    };
  };
}
