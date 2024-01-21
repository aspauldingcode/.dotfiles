{
  description = "Universal Flake by Alex - macOS and NixOS";

  inputs = {
    nixpkgs.url =       "github:nixos/nixpkgs/nixos-unstable";
    darwin.url =        "github:lnl7/nix-darwin";
    nix-darwin.url =    "github:LnL7/nix-darwin";
    home-manager.url =  "github:nix-community/home-manager";
    nixvim.url =        "github:nix-community/nixvim";
    nix-colors.url =    "github:misterio77/nix-colors"; 
  };

  outputs = { self, nixpkgs, darwin, nix-darwin, home-manager, nixvim, flake-parts, nix-colors }: 
  let inherit (self) inputs;
    # Define common specialArgs for nixosConfigurations and homeConfigurations
    commonSpecialArgs = { inherit inputs nixvim flake-parts nix-colors self; };
    darwinSpecialArgs = { inherit nix-darwin self; };
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    eachSystem = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

    # Define NixOS configurations
    nixosConfigurations = {
      NIXSTATION64 = nixpkgs.lib.nixosSystem {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        specialArgs = commonSpecialArgs;
        modules = [ ./system/NIXSTATION64/configuration.nix ];
      };
      NIXEDUP = nixpkgs.lib.nixosSystem {
        pkgs = nixpkgs.legacyPackages.aarch64-linux;
        specialArgs = commonSpecialArgs;
        modules = [ ./system/NIXEDUP/configuration.nix ];
      };
    };

    # Define Darwin (macOS) configurations
    darwinConfigurations = {
      NIXY = darwin.lib.darwinSystem {
        specialArgs = [ commonSpecialArgs darwinSpecialArgs ];
        modules = [ ./system/NIXY/darwin-configuration.nix ];
      };
    };

    # Define home-manager configurations for Users
    homeConfigurations = {

      # User: "Alex"
      "alex@NIXY" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        extraSpecialArgs = [ commonSpecialArgs darwinSpecialArgs ];
        modules = [ ./users/alex/NIXY/home-NIXY.nix ];
      };

      "alex@NIXEDUP" = home-manager.lib.homeManagerConfiguration { 
        pkgs = nixpkgs.legacyPackages.aarch64-linux;
        extraSpecialArgs = commonSpecialArgs;
        modules = [ ./users/alex/NIXEDUP/home-NIXEDUP.nix];
      };

      "alex@NIXSTATION64" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = commonSpecialArgs;
        modules = [ ./users/alex/NIXSTATION64/home-NIXSTATION64.nix ];
      };

    # User: "Su Su"
    "susu@NIXY" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      extraSpecialArgs = [ commonSpecialArgs darwinSpecialArgs ];
      modules = [ ./users/susu/home-NIXY.nix ];
    };

    "susu@NIXSTATION64" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = commonSpecialArgs;
      modules = [ ./users/susu/home-NIXSTATION64.nix ];
    };
  };
  in {
      # Return all the configurations
      nixosConfigurations = nixosConfigurations;
      homeConfigurations = homeConfigurations;
      darwinConfigurations = darwinConfigurations;
      apps = eachSystem (pkgs: {
      default = let
        setup = pkgs.writeScriptBin "setup" /* bash */ '' 
        #!/bin/bash

        echo -e "\n\n"

        expected_user="alex"
        current_user=$(whoami)

        if [ "$current_user" != "$expected_user" ]; then
          echo "Warning: This script must be run by the user '$expected_user'."
          exit 1
        fi

        echo -e "The current user is: $current_user. Continuing...\n"

        check_and_prompt_change() {
          new_computer_name="$1"
          current_system_name=$(hostname)

          if [ "$current_system_name" != "$new_computer_name" ]; then
            echo -e "\nWarning: The current system name is '$current_system_name', but you provided '$new_computer_name'."
            read -p "Would you like to change it to '$new_computer_name'? (y/n): " change_option
            if [ "$change_option" == "y" ]; then
              # Additional steps for changing system name based on platform
              if [ "$(uname)" == "Darwin" ]; then
                # macOS platform
                sudo scutil --set HostName "$new_computer_name"
                sudo scutil --set LocalHostName "$new_computer_name"
                sudo scutil --set ComputerName "$new_computer_name"
                # Verify if the change was successful
                updated_system_name=$(hostname)
                if [ "$updated_system_name" != "$new_computer_name" ]; then
                  echo -e "\nError: Failed to change the system name to '$new_computer_name' on this macOS system."
                  echo "Please do it manually through 'System Settings'. Then, reboot and run the script again."
                  exit 1
                else
                  echo -e "\nSystem name, LocalHostName, and ComputerName changed to: $current_system_name"
                  echo -e "rebooting macOS in 3 seconds (re-run the script after)..."
                  sleep 3
                  sudo reboot -h now & exit
                fi
              else
                # Default for other platforms (Linux, etc.)
                sudo hostnamectl set-hostname "$new_computer_name"
                echo -e "\nSystem name changed to: $current_system_name"
              fi
            else
              echo -e "\nYou'll need to change the system name to $new_computer_name before continuing."
              sleep 2
              echo -e "\nExiting setup script."
              exit 1
            fi
          else
            echo -e "\nSystem name matched: $new_computer_name"
          fi
        }
        
        make_sshkey() {
          # Check if the SSH key file for the current computer already exists
          ssh_key_file="$HOME/.ssh/$new_computer_name"
          
          if [ -f "$ssh_key_file" ]; then
            echo -e "\nWarning: An SSH key file '$new_computer_name' already exists in '$HOME/.ssh'."
            echo "Please make sure you want to proceed, as generating a new key will overwrite the existing one."
            read -p "Do you still want to proceed? (y/n): " overwrite_answer
            if [ "$overwrite_answer" != "y" ]; then
                echo -e "\nExiting setup script."
                exit 1
            fi
          fi

          read -p "Have you set up an SSH key for this computer? (y/n): " ssh_key_answer
          if [ "$ssh_key_answer" == "n" ]; then
            # Generate SSH key using ssh-keygen
            ssh-keygen -t ed25519 -f "$HOME/.ssh/$new_computer_name" -q -N ""
            
            # Open GitHub SSH key creation page in the default browser
            echo -e "\nPlease visit the following link to add the SSH key to your GitHub account:"
            echo "https://github.com/settings/ssh/new"
            
            # Display instructions for the user
            echo -e "\nWhen prompted, use the following information:"
            echo "Name: $new_computer_name"
            echo "Key: $(cat $HOME/.ssh/$new_computer_name.pub)"
          else
            read -p "Continue? (y/n): " continue_answer
            if [ "$continue_answer" != "y" ]; then
                echo -e "\nExiting setup script."
                exit 1
            fi
          fi
        }

        PS3="Select the computer you are setting up: "
        selected_option=""

        select computer in "NIXSTATION64" "NIXY" "NIXEDUP" "NEW" "EXIT"; do
          case $computer in
            "NIXSTATION64")
              selected_option="NIXSTATION64"
              echo -e "\nSetting up NIXSTATION64..."
              # Add setup steps for NIXSTATION64
              check_and_prompt_change "NIXSTATION64"
              
              make_sshkey 
              break
              ;;
            "NIXY")
              selected_option="NIXY"
              echo -e "\nSetting up NIXY..."
              # Add setup steps for NIXY
              check_and_prompt_change "NIXY"

              make_sshkey
              break
              ;;
            "NIXEDUP")
              selected_option="NIXEDUP"
              echo -e "\nSetting up NIXEDUP..."
              # Add setup steps for NIXEDUP
              check_and_prompt_change "NIXEDUP"

              make_sshkey
              break
              ;;
            "NEW")
              if [ -z "$selected_option" ]; then
                echo -e "\nPlease choose options 1, 2, or 3 before selecting 'NEW'."
              else
                echo -e "\nSetting up a new computer..."
                # Add setup steps for a new computer
                read -p "Enter the name for the new computer: " new_computer_name
                check_and_prompt_change "$new_computer_name"
                echo -e "\nWe can only run this, but not rebuild. you must add changes to the repo to add $new_computer_name to the list of devices."
              fi
              break
              ;;
            "EXIT")
              echo -e "\nExiting setup script."
              exit 0
              ;;
            *)
              echo -e "\nInvalid option. Please choose a valid computer or EXIT (5)."
              ;;
          esac
        done
        
        # CLONE THE REPO TO ~/.dotfiles!
        ${pkgs.git}/bin/git clone git@github.com:aspauldingcode/.dotfiles $HOME/.dotfiles
        # run the rebuild!
        rebuild -r -f #FIXME: allow -r -f on NIXSTATION64

        '';
      in {
        type = "app";
        program = "${setup}/bin/setup";
      };
    });
  };
}
