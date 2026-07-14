# Make Cursor / VS Code Remote SSH work on NixOS hosts.
#
# Remote servers download a prebuilt Node binary that expects a normal FHS
# dynamic linker. nix-ld provides that; wget+nodejs cover Cursor's download
# and system-node fallback paths.
{
  flake.modules.nixos.dendritic =
    {
      pkgs,
      lib,
      ...
    }:
    {
      programs.nix-ld = {
        enable = true;
        # Common libs for IDE remote servers + native extension hosts.
        libraries = with pkgs; [
          stdenv.cc.cc
          zlib
          openssl
          curl
          icu
          libuuid
          libgcc
        ];
      };

      environment.systemPackages = [
        # programs.nix-ld enables the linker/libs but does not put the
        # `nix-ld` binary on PATH; Cursor Remote smoke checks expect it.
        pkgs.nix-ld
        pkgs.wget
        pkgs.nodejs_22
      ];

      # Cursor/VS Code remote needs agent forwarding / TCP forwarding for the
      # extension host tunnel. OpenSSH defaults allow this; be explicit.
      services.openssh.settings = {
        AllowTcpForwarding = lib.mkDefault true;
        AllowAgentForwarding = lib.mkDefault true;
      };
    };
}
