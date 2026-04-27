{ inputs, ... }:

{
  imports = [
    {
      config = {
        _module.args.inputs = inputs;
        nixpkgs.hostPlatform = "x86_64-linux";
        nixpkgs.config.allowUnfree = true;
        
        # System Manager specific setup
        system-manager.allowInsecure = false;
      };
    }

    # Pull in Feature Modules from the Hub (System Level)
    inputs.self.modules.nixos.shell
    inputs.self.modules.nixos.secrets
    inputs.self.modules.nixos.styling
  ];
}
