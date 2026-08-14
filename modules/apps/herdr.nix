{
  flake.modules.homeManager.dendritic =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      cfg = config.dendritic.apps.herdr;
    in
    {
      options.dendritic.apps.herdr = {
        enable = lib.mkEnableOption "dendritic herdr" // {
          default = true;
        };
        autoStart = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Auto-start herdr in interactive shells.";
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ pkgs.herdr ];

        programs.ghostty.settings.command = lib.mkIf (
          cfg.autoStart && (config.programs.ghostty.enable or false)
        ) (lib.mkForce "${pkgs.herdr}/bin/herdr");

        programs.zsh.initContent = lib.mkMerge [
          (lib.mkIf cfg.autoStart (
            lib.mkOrder 50 ''
              if [[ -z ''${HERDR_ENV:-} && -z ''${DENDRITIC_NO_HERDR:-} && -z ''${TMUX:-} && -z ''${ZELLIJ:-} && $- == *i* ]]; then
                case ''${TERM_PROGRAM:-} in
                  vscode|cursor) ;;
                  *)
                    case ''${TERM:-} in
                      dumb|linux) ;;
                      *)
                        exec ${pkgs.herdr}/bin/herdr
                        ;;
                    esac
                    ;;
                esac
              fi
            ''
          ))
        ];

        programs.zsh.shellAliases = {
          t = "herdr";
        };
      };
    };
}
