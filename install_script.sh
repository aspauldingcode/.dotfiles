#!/bin/bash
if command -v nix >/dev/null 2>&1; then
  echo "Nix is already installed."
else
  echo -e "\nThis script requires superuser privileges."
  sudo echo ""
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
  echo "Sourcing the nix-daemon.sh script..."
  if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
    . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
  fi
fi
 
if [ "$(uname)" == "Darwin" ]; then
  echo -e "We will need to install Nix-Darwin on this Mac to continue."
  sleep 2
 
  # Check if nix is installed, if not, run the following:
  if command -v darwin-rebuild >/dev/null 2>&1; then
    echo "Nix-Darwin is already installed."
  else
    echo -e "Nix-Darwin is not installed. Installing..."
    
    # Install Nix-Darwin
    nix_build_url="https://github.com/LnL7/nix-darwin/archive/master.tar.gz"
    installer_path="./result/bin/darwin-installer"
    
    nix_build() {
      echo -e "\nDownloading and building Nix-Darwin..."
      nix-build $nix_build_url -A installer
    }
    
    run_installer() {
      echo -e "Running Nix-Darwin installer..."
      ./$installer_path
    }
    
    nix_build
    run_installer
  fi

  echo -e "We will need to install Homebrew on this Mac to continue."
  sleep 2
  
  # Check if brew is installed, if not, run the following:
  if command -v brew >/dev/null 2>&1; then
    echo "Homebrew is already installed."
  else
    echo -e "Homebrew is not installed. Installing..."
    
    # Check architecture and set brew shellenv accordingly
    brew_check_architecture() {
      architecture=$(arch)
      
      echo -e "\nDetected architecture: $architecture"
      
      if [ "$architecture" == "x86_64" ]; then
        echo -e "Running on 64-bit architecture."
        { echo; echo 'eval "$(/usr/local/bin/brew shellenv)"'; } >> "$HOME/.zprofile"
        eval "$(/usr/local/bin/brew shellenv)"
      else
        echo -e "Running on non-x86_64 architecture."
        { echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"'; } >> "$HOME/.zprofile"
        eval "$(/opt/homebrew/bin/brew shellenv)"
      fi
    }
    brew_check_architecture
    
    # Install Homebrew
    yes | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
  fi
fi

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
            read -p "Continue? (y/n): " continue_answer
            if [ "$continue_answer" != "y" ]; then
                echo -e "\nExiting setup script."
                exit 1
            fi
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

echo "CLONING THE REPO TO ~/.dotfiles!"
brew install git
/bin/git clone git@github.com:aspauldingcode/.dotfiles $HOME/.dotfiles

cd ~/.dotfiles

if [ "$(uname)" == "Darwin" ]; then
  echo "setting default shell back to zsh"
  chsh -s /bin/zsh
  sudo chsh -s /bin/zsh
  echo -e "\nRebuilding nix-darwin flake..."
  sleep 2
  darwin-rebuild switch --flake .#$new_computer_name
  home-manager switch --flake .#alex@$new_computer_name
  fix-wm
  defaults write com.apple.dock ResetLaunchPad -bool true
else
  sudo nixos-rebuild switch --flake .#$new_computer_name
  home-manager switch --flake .#alex@$new_computer_name
  echo "Done. Running 'fix-wm'..."
  fix-wm
  echo "Completed."
  date +"%r"
fi

echo "Running the .dotfiles flake install..."
nix run github:aspauldingcode/.dotfiles
