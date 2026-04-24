{
  flake.modules.homeManager.mobile = { pkgs, inputs, ... }: {
    # If using ansible or similar setup for Sileo packages on a jailbroken iPhone
    home.packages = with pkgs; [
      ansible
      # Add other iOS automation tools here
    ];
  };
}
