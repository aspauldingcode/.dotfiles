{ ... }:

{
  programs.cava = {
    enable = true;
    settings = {
      /*
        Based on the config file, these settings are marked as deprecated:
        mode (since v0.6.0)
        overshoot (since v0.6.0)
        integral (since v0.8.0)
        gravity (since v0.8.0)
        ignore (since v0.8.0)
        The reason is that newer versions of CAVA have replaced these with improved alternatives like noise_reduction.
      */
      general = {
        framerate = 60;
        autosens = 1;
        overshoot = 20;
        sensitivity = 100;
      };

      input = {
        method = "portaudio";
        source = "Background Music";
      };

      output = {
        method = "ncurses";
        channels = "stereo";
      };

      smoothing = {
        monstercat = 0;
        waves = 0;
        noise_reduction = 77;
      };
    };
  };
}
