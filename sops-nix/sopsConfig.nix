{ nixpkgs, user }:

let
  # Common sops configuration shared between NixOS and Home Manager
  commonSopsConfigBase = {
    sops = {
      defaultSopsFile = ./secrets.yaml;
      defaultSopsFormat = "yaml";
      age = {
        # sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        keyFile = "/var/lib/sops-nix/key.txt";
        generateKey = true;
      };
    };
  };

  # NixOS-specific sops configuration (with owner and mode)
  nixosSopsConfig = nixpkgs.lib.recursiveUpdate commonSopsConfigBase {
    sops.secrets = {
      test_secret = {
        owner = user;
        mode = "0400";
      };
      claude_api_key = {
        owner = user;
        mode = "0400";
      };
      openai_api_key = {
        owner = user;
        mode = "0400";
      };
      azure_openai_api_key = {
        owner = user;
        mode = "0400";
      };
      bedrock_keys = {
        owner = user;
        mode = "0400";
      };
      wifi_bubbles_passwd = {
        owner = user;
        mode = "0400";
      };
      wifi_eduroam_userID = {
        owner = user;
        mode = "0400";
      };
      wifi_eduroam_passwd = {
        owner = user;
        mode = "0400";
      };
      GH_TOKEN = {
        owner = user;
        mode = "0400";
      };
    };
  };

  # Home Manager-specific sops configuration (without owner and mode)
  hmSopsConfig = nixpkgs.lib.recursiveUpdate commonSopsConfigBase {
    sops.secrets = {
      test_secret = { };
      claude_api_key = { };
      openai_api_key = { };
      azure_openai_api_key = { };
      bedrock_keys = { };
      wifi_bubbles_passwd = { };
      wifi_eduroam_userID = { };
      wifi_eduroam_passwd = { };
      GH_TOKEN = { };
    };
  };

  # For backward compatibility, keep commonSopsConfig pointing to the NixOS version
  commonSopsConfig = nixosSopsConfig;
in
{
  inherit
    commonSopsConfigBase
    nixosSopsConfig
    hmSopsConfig
    commonSopsConfig
    ;
}
