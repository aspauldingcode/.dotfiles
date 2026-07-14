# Declarative SSH public keys (safe for public git).
# Private keys stay on disk; never commit them.
#
# Update via: nix run .#ssh-enroll -- --name <host> --pubkey ~/.ssh/id_ed25519.pub
{
  mba = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINKl9TDLSvtYglhmM79Pn3ViQheFhvsB5Jccv5LVc+2f 8amps@MyMac.local";
  "mba-asahi" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINKl9TDLSvtYglhmM79Pn3ViQheFhvsB5Jccv5LVc+2f 8amps@MyMac.local";
}
