{
  config,
  lib,
  pkgs,
  ...
}: {
  # Basic SSH daemon configuration for Darwin
  services.openssh = {
    enable = true;
  };

  # Configure authorized keys for your user
  users.users.alex.openssh.authorizedKeys = {
    keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPAzfDAoGvCXUuw9da2Aik0LxRKEeozYB7qbNx9VE6V5 alex@NIXY.local"
    ];
    # Or you can specify files containing the keys
    keyFiles = [
      # Add paths to files containing your public keys, for example:
      # ~/.ssh/id_ed25519.pub # error: the path '~/.ssh/id_ed25519.pub' can not be resolved in pure mode
    ];
  };

  # For Darwin, we use system.activationScripts to manage SSH setup
  system.activationScripts.postActivation.text = ''
    # Create SSH directory if it doesn't exist
    echo "Setting up SSH host keys..."
    sudo mkdir -p /etc/ssh

    # Generate host key if it doesn't exist
    if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
      echo "Generating new SSH host key..."
      sudo ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
    fi

    # Set correct permissions
    sudo chmod 600 /etc/ssh/ssh_host_ed25519_key
    sudo chmod 644 /etc/ssh/ssh_host_ed25519_key.pub
  '';
}
