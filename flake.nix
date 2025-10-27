{
  description = "Multi-system, multi-arch Nix flake example with nix-darwin, determinate-nix, sops-nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-darwin.url = "github:LnL7/nix-darwin";
    sops-nix.url = "github:Mic92/sops-nix";
    determinate-nix.url = "github:DeterminateSystems/determinate";
  };

  outputs = { self, nixpkgs, nixpkgs-darwin, flake-utils, nix-darwin, sops-nix, determinate-nix, ... }:
    let
      hardwareDir = ./hardware;
      makeNixosConfigurations =
        if builtins.pathExists hardwareDir then
          let
            files = builtins.attrNames (builtins.readDir hardwareDir);
            nixFiles = builtins.filter (f: builtins.match ".*\\.nix" f != null) files;
          in
          builtins.listToAttrs (map (fname:
            let
              name = builtins.substring 0 (builtins.stringLength fname - 4) fname;
              systemFile = hardwareDir + "/${name}.system";
              systemStr = if builtins.pathExists systemFile then
                builtins.replaceStrings ["\n" "\r"] ["" ""] (builtins.readFile systemFile)
              else
                "x86_64-linux";
            in {
              name = name;
              value = nixpkgs.lib.nixosSystem {
                system = systemStr;
                modules = [ (hardwareDir + "/${fname}") ];
              };
            }) nixFiles)
        else {};
    in
    (flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ] (system:
      let
        nixpkgsInput = if builtins.match ".*-darwin" system != null then nixpkgs-darwin else nixpkgs;
        pkgs = import nixpkgsInput {
          inherit system;
          config = { allowUnfree = true; };
        };

        sharedPackages = with pkgs; [
          git
          curl
          wget
          rustup
          ripgrep
          fd
          bat
          tree
          yazi
          neovim
        ];

        exampleApps = with pkgs; [
          firefox
          vlc
          htop
        ];

        linuxDE = if builtins.match ".*-linux" system != null then with pkgs; [ xfce4 xfce4-terminal ] else [];
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "example-env";
          version = "1.0";
          buildInputs = sharedPackages ++ exampleApps ++ linuxDE;
          # optional: build output script
          unpackPhase = ":"; 
          installPhase = ''
            mkdir -p $out/bin
            echo "Example environment ready" > $out/bin/hello
            chmod +x $out/bin/hello
          '';
        };

        # nix-darwin configuration
        darwinConfigurations = if builtins.match ".*-darwin" system != null then {
          myMac = nix-darwin.lib.darwinSystem {
            inherit system;
            modules = [
              {
                # Let Determinate Nix manage Nix itself on macOS
                nix.enable = false;
                nixpkgs.overlays = [
                  (final: prev: {
                    rust = prev.rustChannel.latest.stable;
                  })
                ];
                environment.systemPackages = sharedPackages ++ exampleApps;
              }
            ];
          };
        } else {};

        # sops-nix secrets placeholder
        sopsSecrets = sops-nix.lib.sopsSecrets {
          inherit pkgs;
          secrets = {};
        };
      }
    )) // {
      nixosConfigurations = makeNixosConfigurations;
    };
}