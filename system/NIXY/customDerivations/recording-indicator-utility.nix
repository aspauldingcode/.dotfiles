{ pkgs, lib, config, ... }:

let
  recordingIndicatorUtility = pkgs.stdenv.mkDerivation {
    pname = "RecordingIndicatorUtility";
    version = "2.0";

    src = pkgs.fetchurl {
      url = "https://github.com/cormiertyshawn895/RecordingIndicatorUtility/releases/download/2.0/RecordingIndicatorUtility.2.0.zip";
      sha256 = "sha256-KqYsgloj+fNqNtN7WYR6O0j8PahSnOcoo6AdNTiEt0U=";
    };

    nativeBuildInputs = [ pkgs.unzip ];

    installPhase = ''
      mkdir -p $out/Applications
      unzip $src -d $out/Applications
    '';

    meta = with lib; {
      description = "Tool for managing recording indicators on macOS";
      license = licenses.mit;
      platforms = platforms.darwin;
      homepage = "https://github.com/cormiertyshawn895/RecordingIndicatorUtility";
    };
  };

  toggleRecordingIndicatorScript = pkgs.writeScript "toggle-recording-indicator" ''
    #!${pkgs.stdenv.shell}
    
    toggle_recording_indicator() {
      osascript <<EOF
        tell application "Recording Indicator Utility"
          activate
          delay 1 -- Wait for the app to fully load
          tell application "System Events"
            tell process "Recording Indicator Utility"
              set toggleButton to first button of first group of first window
              set toggleState to value of toggleButton
              if ${if config.programs.recordingIndicatorUtility.showIndicator then "toggleState is 0" else "toggleState is 1"} then
                -- Toggle is ${if config.programs.recordingIndicatorUtility.showIndicator then "on" else "off"}, so we can click to turn it ${if config.programs.recordingIndicatorUtility.showIndicator then "off" else "on"}
                click toggleButton
                log "Turned ${if config.programs.recordingIndicatorUtility.showIndicator then "on" else "off"} Recording Indicator"
              else
                -- Toggle is already ${if config.programs.recordingIndicatorUtility.showIndicator then "on" else "off"}, no action needed
                log "Recording Indicator is already ${if config.programs.recordingIndicatorUtility.showIndicator then "on" else "off"}"
              end if
            end tell
          end tell
          quit
        end tell
EOF
      # save state to statefile
      echo "${if config.programs.recordingIndicatorUtility.showIndicator then "on" else "off"}" > "$statefile"
    }
   
    statefile="/var/lib/recording_indicator_state.log"
    desired_state="${if config.programs.recordingIndicatorUtility.showIndicator then "on" else "off"}"

    # generate the statefile, set default to "on"
    if [ ! -f "$statefile" ]; then
      echo "on" > "$statefile"
    fi

    current_state=$(cat "$statefile")

    if [ "$current_state" != "$desired_state" ]; then
      toggle_recording_indicator
      echo "$desired_state" > "$statefile"
    fi
  '';
in
{
  options.programs.recordingIndicatorUtility = {
    enable = lib.mkEnableOption "Recording Indicator Utility";
    showIndicator = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Show or hide the recording indicator. Requires restart.";
    };
    showWarning = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Acknowledge the system override alert for the Recording Indicator Utility.";
    };
  };

  config = lib.mkIf config.programs.recordingIndicatorUtility.enable {
    environment.systemPackages = [ recordingIndicatorUtility ];

    # Set default for acknowledging system override alert
    system.defaults.CustomUserPreferences."com.mac.RecordingIndicatorUtility".AcknowledgedSystemOverrideAlert = if config.programs.recordingIndicatorUtility.showWarning then 0 else 1;

    system.activationScripts.postActivation.text = lib.mkAfter ''
      # Set default for showing recording indicator
      ${toggleRecordingIndicatorScript}
    '';
  };
}