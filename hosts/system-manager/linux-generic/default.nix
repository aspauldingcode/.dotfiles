{ inputs, ... }:

{
  imports = [
    {
      config = {
        nixpkgs.hostPlatform = "x86_64-linux";
        nixpkgs.config.allowUnfree = true;
        
        # System Manager specific setup
        system-manager.allowAnyDistro = true;
      };
    }

    # Pull in Feature Modules from the Hub (System Level)
    inputs.self.modules.nixos.shell
    inputs.self.modules.nixos.secrets
  ];
}
