{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.openssh = {
    enable = true; # error: The option `services.openssh.enable' does not exist.
    settings = {
      # Authentication settings
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "yes";
      StrictModes = true;

      # Security settings
      X11Forwarding = true;
      UsePAM = true;
      UseDns = true;
      GatewayPorts = "no";

      # Logging and display
      LogLevel = "INFO";
      PrintMotd = true;

      # Access control
      AllowGroups = [ ];
      AllowUsers = [ "alex" ];
      DenyGroups = [ ];
      DenyUsers = [ ];

      # Crypto settings
      Ciphers = [
        "chacha20-poly1305@openssh.com"
        "aes256-gcm@openssh.com"
        "aes128-gcm@openssh.com"
        "aes256-ctr"
        "aes192-ctr"
        "aes128-ctr"
      ];
      KexAlgorithms = [
        "curve25519-sha256@libssh.org"
        "diffie-hellman-group-exchange-sha256"
      ];
      Macs = [
        "hmac-sha2-512-etm@openssh.com"
        "hmac-sha2-256-etm@openssh.com"
        "umac-128-etm@openssh.com"
      ];
      HostKeyAlgorithms = [
        "ssh-ed25519"
        "ssh-ed25519-cert-v01@openssh.com"
      ];
      PubkeyAcceptedKeyTypes = [
        "ssh-ed25519"
        "ssh-ed25519-cert-v01@openssh.com"
      ];
    };

    # Port and firewall settings
    openFirewall = true;
    ports = [ 22 ];
    startWhenNeeded = true;

    # SFTP configuration
    # allowSFTP = true; # error: The option `services.openssh.allowSFTP' does not exist.
    sftpFlags = [ ];
    sftpServerExecutable = "internal-sftp";

    # Additional configuration
    # authorizedKeysInHomedir = true; # error: The option `services.openssh.authorizedKeysInHomedir' does not exist.
    authorizedKeysFiles = [ ];
    # authorizedKeysCommand = null; # error: The option `services.openssh.authorizedKeysCommand' does not exist.
    # authorizedKeysCommandUser = null; #error: The option `services.openssh.authorizedKeysCommandUser' does not exist.
    # banner = null; # error: The option `services.openssh.banner' does not exist.
    extraConfig = "";

    # Listen addresses
    listenAddresses = [
      {
        addr = "0.0.0.0"; # listen on all interfaces
        port = 22;
      }
    ];

    # Host keys and known hosts can be configured here
    hostKeys = [ ];
    knownHosts = { };

    # Moduli file for DH key exchange
    moduliFile = null;
  };
}
