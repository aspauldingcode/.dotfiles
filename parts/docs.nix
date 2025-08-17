# Documentation Module - Flake documentation
{ inputs, ... }:
{
  perSystem =
    {
      config,
      self',
      inputs',
      pkgs,
      system,
      ...
    }:
    {
      packages = {
        # Documentation package
        docs = pkgs.stdenv.mkDerivation {
          name = "dotfiles-docs";
          src = ../docs;
          buildInputs = with pkgs; [ mdbook ];
          buildPhase = ''
            mdbook build
          '';
          installPhase = ''
            mkdir -p $out
            cp -r book/* $out/
          '';
        };
      };

      apps = {
        # Documentation server
        docs-serve = {
          type = "app";
          program = "${pkgs.writeShellScript "docs-serve" ''
            cd ${../docs}
            exec ${pkgs.mdbook}/bin/mdbook serve --open
          ''}";
        };
      };
    };
}
