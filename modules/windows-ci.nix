# Flake checks for Windows IoT LTSC dual-boot (pure; no disk mutation, no ISO download).
{
  perSystem =
    { pkgs, lib, ... }:
    let
      scripts = [
        ./pkgs/_dendritic-windows-bootstrap.sh
        ./pkgs/_dendritic-windows-finalize.sh
        ./pkgs/_dendritic-windows-label-gpt.sh
        ./pkgs/_dendritic-windows-offline-shrink.sh
      ];
      unattend = ./pkgs/_dendritic-windows-unattend.xml;
      expectedSha = "67cec5865eaa037a72ddc633a717a10a2bed50778862267223ddb9c60ef5da68";
      expectedFwlink = "https://go.microsoft.com/fwlink/?linkid=2289029";

      scriptsArgs = lib.concatMapStringsSep " " (p: "${p}") scripts;
    in
    {
      checks.windows-dualboot =
        pkgs.runCommand "windows-dualboot-check"
          {
            nativeBuildInputs = [
              pkgs.shellcheck
              pkgs.libxml2
              pkgs.bash
              pkgs.gnugrep
              pkgs.coreutils
            ];
          }
          ''
            set -euo pipefail
            echo "== shellcheck =="
            shellcheck -e SC2154,SC2086,SC2046,SC2034,SC2001,SC2016,SC2207 ${scriptsArgs}

            echo "== unattend.xml (silent Setup → partition 3) =="
            xmllint --noout ${unattend}
            grep -q 'AcceptEula>true</AcceptEula>' ${unattend}
            grep -q 'WillShowUI>Never</WillShowUI>' ${unattend}
            grep -q 'SkipMachineOOBE>true</SkipMachineOOBE>' ${unattend}
            grep -q 'PartitionID>3</PartitionID>' ${unattend}
            grep -q '__DENDRITIC_IMAGE_INDEX__' ${unattend}
            grep -q 'HideOnlineAccountScreens>true</HideOnlineAccountScreens>' ${unattend}
            grep -q 'PreventDeviceEncryption' ${unattend}
            grep -q 'dendritic-windows-ready' ${unattend}
            grep -q '__DENDRITIC_PASSWORD__' ${unattend}
            grep -q 'shutdown /r' ${unattend}

            echo "== bootstrap uses wininstall media + BootNext =="
            grep -q 'wininstall' ${./pkgs/_dendritic-windows-bootstrap.sh}
            grep -q -- '--bootnext' ${./pkgs/_dendritic-windows-bootstrap.sh}
            grep -q 'Windows Setup (dendritic)' ${./pkgs/_dendritic-windows-bootstrap.sh}
            grep -q 'media-ready' ${./pkgs/_dendritic-windows-bootstrap.sh}
            grep -q 'rsync' ${./pkgs/_dendritic-windows-bootstrap.sh}
            grep -q 'PARTLABEL=windows missing' ${./pkgs/_dendritic-windows-bootstrap.sh}
            ! grep -q 'wimlib-imagex apply' ${./pkgs/_dendritic-windows-bootstrap.sh}
            ! grep -q 'pending-shrink' ${./pkgs/_dendritic-windows-bootstrap.sh}

            echo "== module defaults (pinned) =="
            test "${expectedSha}" = "67cec5865eaa037a72ddc633a717a10a2bed50778862267223ddb9c60ef5da68"
            test "${expectedFwlink}" = "https://go.microsoft.com/fwlink/?linkid=2289029"

            echo "== bootstrap self-test =="
            export DENDRITIC_WINDOWS_SELFTEST=1
            export DENDRITIC_WINDOWS_DISK=/dev/null
            export DENDRITIC_WINDOWS_MOUNT=/tmp
            export DENDRITIC_WINDOWS_SIZE_GIB=64
            export DENDRITIC_WINDOWS_EDITION_NAME='IoT Enterprise LTSC'
            export DENDRITIC_WINDOWS_CACHE=/tmp
            export DENDRITIC_WINDOWS_STATE=/tmp
            export DENDRITIC_WINDOWS_UNATTEND_TEMPLATE=${unattend}
            export DENDRITIC_WINDOWS_PASSWORD_FILE=/tmp/dendritic-windows-ci-password
            export DENDRITIC_WINDOWS_ISO_SHA256=${expectedSha}
            export DENDRITIC_WINDOWS_ISO_URL=${expectedFwlink}
            export DENDRITIC_WINDOWS_ISO_NAME=ci.iso
            echo 'testpass' >"$DENDRITIC_WINDOWS_PASSWORD_FILE"
            bash ${./pkgs/_dendritic-windows-bootstrap.sh}

            echo "windows-dualboot-check OK"
            touch $out
          '';
    };
}
