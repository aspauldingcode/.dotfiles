{ ... }:
# Module to enable yabai scripting additions automatically but use homebrew yabai instead

{
  launchd.daemons.yabai-sa = let yabai = "/opt/homebrew/bin/yabai"; in {
    script = ''
    ${yabai} --install-sa
    ${yabai} --load-sa
    '';
    serviceConfig.RunAtLoad = true;
    serviceConfig.KeepAlive.SuccessfulExit = false;
  };

  environment.etc."sudoers.d/yabai".text =
    let
      yabai = "/opt/homebrew/bin/yabai";
      # sha = builtins.hashFile "sha256" "${yabai}";
    in
    "%admin ALL=(root) NOPASSWD: ${yabai} --load-sa";
  }
