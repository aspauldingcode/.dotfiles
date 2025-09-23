{
  lib,
  ...
}:
{
  config = {
    # Ensure the directory exists
    system.activationScripts.makeIwdDir = lib.stringAfter [ "var" ] ''
      mkdir -p /var/lib/iwd
    '';

    # Install the CA certificate
    environment.etc."iwd/ewu-ca.pem" = {
      source = ./ca.pem;
      mode = "0644";
    };

    networking.wireless.iwd.enable = true;

    networking.wireless.iwd.settings = {
      Network = {
        EnableIPv6 = true;
        RoutePriorityOffset = 300;
      };
    };

    # Write the eduroam config into the correct path
    system.activationScripts.writeEduroamConfig = lib.stringAfter [ "var" ] ''
      cat > /var/lib/iwd/eduroam.8021x <<EOF
        [Security]
        EAP-Method=PEAP
        EAP-Identity=user@ewu.edu
        EAP-Password=your_eduroam_password
        EAP-PEAP-CACert=/etc/iwd/ewu-ca.pem
        EAP-PEAP-ServerDomainMask=eastern.ewu.edu
        EAP-PEAP-Phase2-Method=MSCHAPV2
        EAP-PEAP-Phase2-Identity=user@ewu.edu
        #EAP-PEAP-Phase2-Password=your_password

        [Settings]
        AutoConnect=true
      EOF

      chmod 600 /var/lib/iwd/eduroam.8021x
    '';

    system.activationScripts.writeBubblesPSK = lib.stringAfter [ "var" ] ''
      cat > /var/lib/iwd/Bubbles.psk <<EOF
        [Security]
        PreSharedKey=7dbf9934e879860bced9246c71971b550e5a14dd0a9df2ed4733347dea812f43
        Passphrase=your_wifi_password_here
        SAE-PT-Group19=722c89608299e48428195fe8641253766c71fde567face3924f922ba5144bdbd5dc7cde5e30d9d2920c73ec263c851292bddd4bd44a563a120189bc1003b568d
        SAE-PT-Group20=eb58f5ecd33498cd4e87c924b9e28bdabbea42478b18d5995b48112d4eb2cfa9fea2d98593f665db1495bd23a1e2ed442832d731529e47b8a6ad725d9f61fe3c7f8d8fd603e62b4314c9a2a90a2a778fc27c8c450aca6da3d855a3d63eaa8037
      EOF

      chmod 600 /var/lib/iwd/Bubbles.psk
    '';
  };
}
