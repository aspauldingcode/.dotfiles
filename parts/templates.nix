# Templates Module - Flake templates
{ inputs, ... }:
{
  flake.templates = {
    # Default template
    default = {
      path = ../templates/default;
      description = "A basic flake template";
    };

    # NixOS system template
    nixos-system = {
      path = ../templates/nixos-system;
      description = "A NixOS system configuration template";
    };

    # Darwin system template
    darwin-system = {
      path = ../templates/darwin-system;
      description = "A Darwin system configuration template";
    };

    # Home Manager template
    home-manager = {
      path = ../templates/home-manager;
      description = "A Home Manager configuration template";
    };

    # Development shell template
    devshell = {
      path = ../templates/devshell;
      description = "A development shell template";
    };
  };
}