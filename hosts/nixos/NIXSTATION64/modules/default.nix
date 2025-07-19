{ pkgs, ... }:
{
  imports = [
    # ./greetd  # Commented out - greetd configuration moved back to main config
    ./packages
    ./theme
    ./virtual-machines
    ./way-displays
  ];
}
