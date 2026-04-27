{
  flake.modules.homeManager.ghostty = { pkgs, lib, config, ... }: {
    options.dendritic.apps.ghostty = {
      enable = lib.mkEnableOption "Ghostty terminal emulator";
      fontSize = lib.mkOption {
        type = lib.types.int;
        default = config.stylix.fonts.sizes.terminal;
        description = "Font size for Ghostty.";
      };
    };

    config = lib.mkIf config.dendritic.apps.ghostty.enable {
      programs.ghostty = {
        enable = true;
        # Automatically select the correct package for the platform
        package = if pkgs.stdenv.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
        
        settings = {
          font-size = config.dendritic.apps.ghostty.fontSize;
          window-decoration = true;
          macos-option-as-alt = true;
          shell-integration = "detect";
          # Use absolute path for zsh to ensure it launches correctly on macOS
          command = "${pkgs.zsh}/bin/zsh";

          # ── Cursor Animation ────────────────────────────────────────
          custom-shader = "shaders/cursor_tail.glsl";
          custom-shader-animation = "always";

          # Manually inherit colors from Stylix
          background = "#${config.lib.stylix.colors.base00}";
          foreground = "#${config.lib.stylix.colors.base05}";
          cursor-color = "#${config.lib.stylix.colors.base05}";
          selection-background = "#${config.lib.stylix.colors.base02}";
          selection-foreground = "#${config.lib.stylix.colors.base05}";

          palette = [
            "0=#${config.lib.stylix.colors.base00}"
            "1=#${config.lib.stylix.colors.base08}"
            "2=#${config.lib.stylix.colors.base0B}"
            "3=#${config.lib.stylix.colors.base0A}"
            "4=#${config.lib.stylix.colors.base0D}"
            "5=#${config.lib.stylix.colors.base0E}"
            "6=#${config.lib.stylix.colors.base0C}"
            "7=#${config.lib.stylix.colors.base05}"
            "8=#${config.lib.stylix.colors.base03}"
            "9=#${config.lib.stylix.colors.base08}"
            "10=#${config.lib.stylix.colors.base0B}"
            "11=#${config.lib.stylix.colors.base0A}"
            "12=#${config.lib.stylix.colors.base0D}"
            "13=#${config.lib.stylix.colors.base0E}"
            "14=#${config.lib.stylix.colors.base0C}"
            "15=#${config.lib.stylix.colors.base07}"
          ];
        };
      };

      # ── Cursor Shader Implementation ───────────────────────────
      xdg.configFile."ghostty/shaders/cursor_tail.glsl".text = ''
        // -- CONFIGURATION --
        vec4 TRAIL_COLOR = iCurrentCursorColor; // can change to eg: vec4(0.2, 0.6, 1.0, 0.5);
        const float DURATION = 0.09; // in seconds
        const float MAX_TRAIL_LENGTH = 0.2;
        const float THRESHOLD_MIN_DISTANCE = 1.5; // min distance to show trail (units of cursor width)
        const float BLUR = 2.0; // blur size in pixels (for antialiasing)

        // --- CONSTANTS for easing functions ---
        const float PI = 3.14159265359;

        // EaseOutCirc
        float ease(float x) {
            return sqrt(1.0 - pow(x - 1.0, 2.0));
        }

        float getSdfRectangle(in vec2 p, in vec2 xy, in vec2 b)
        {
            vec2 d = abs(p - xy) - b;
            return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
        }

        float seg(in vec2 p, in vec2 a, in vec2 b, inout float s, float d) {
            vec2 e = b - a;
            vec2 w = p - a;
            vec2 proj = a + e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
            float segd = dot(p - proj, p - proj);
            d = min(d, segd);

            float c0 = step(0.0, p.y - a.y);
            float c1 = 1.0 - step(0.0, p.y - b.y);
            float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
            float allCond = c0 * c1 * c2;
            float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
            float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond));
            s *= flip;
            return d;
        }

        float getSdfParallelogram(in vec2 p, in vec2 v0, in vec2 v1, in vec2 v2, in vec2 v3) {
            float s = 1.0;
            float d = dot(p - v0, p - v0);

            d = seg(p, v0, v3, s, d);
            d = seg(p, v1, v0, s, d);
            d = seg(p, v2, v1, s, d);
            d = seg(p, v3, v2, s, d);

            return s * sqrt(d);
        }

        vec2 normalize(vec2 value, float isPosition) {
            return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
        }

        float antialising(float distance) {
        	return 1. - smoothstep(0., normalize(vec2(BLUR, BLUR), 0.).x, distance);
        }

        float determineIfTopRightIsLeading(vec2 a, vec2 b) {
            float condition1 = step(b.x, a.x) * step(a.y, b.y); // a.x < b.x && a.y > b.y
            float condition2 = step(a.x, b.x) * step(b.y, a.y); // a.x > b.x && a.y < b.y

            // if neither condition is met, return 1 (else case)
            return 1.0 - max(condition1, condition2);
        }

        void mainImage(out vec4 fragColor, in vec2 fragCoord){
            #if !defined(WEB)
            fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
            #endif

            // normalization & setup(-1, 1 coords)
            vec2 vu = normalize(fragCoord, 1.);
            vec2 offsetFactor = vec2(-.5, 0.5);
            
            vec4 currentCursor = vec4(normalize(iCurrentCursor.xy, 1.), normalize(iCurrentCursor.zw, 0.));
            vec4 previousCursor = vec4(normalize(iPreviousCursor.xy, 1.), normalize(iPreviousCursor.zw, 0.));

            vec2 centerCC = currentCursor.xy - (currentCursor.zw * offsetFactor);
            vec2 centerCP = previousCursor.xy - (previousCursor.zw * offsetFactor);

            vec2 delta = centerCP - centerCC;
            float lineLength = length(delta);

             float sdfCurrentCursor = getSdfRectangle(vu, centerCC, currentCursor.zw * 0.5);
        	
             vec4 newColor = vec4(fragColor);
        	
             float minDist = currentCursor.w * THRESHOLD_MIN_DISTANCE;
             float progress = clamp((iTime - iTimeCursorChange) / DURATION, 0.0, 1.0);
             if (lineLength > minDist) {
                 // ANIMATION logic
                
                float head_eased = 0.0;
                float tail_eased = 0.0;

                float tail_delay_factor = MAX_TRAIL_LENGTH / lineLength;

                float isLongMove = step(MAX_TRAIL_LENGTH, lineLength);

                float head_eased_short = ease(progress);
                float tail_eased_short = ease(smoothstep(tail_delay_factor, 1.0, progress));
                float head_eased_long = 1.0;
                float tail_eased_long = ease(progress);

                head_eased = mix(head_eased_long, head_eased_short, isLongMove);
                tail_eased = mix(tail_eased_long, tail_eased_short, isLongMove);

                // detect straight moves
                vec2 delta_abs = abs(centerCC - centerCP); 
                float threshold = 0.001;
                float isHorizontal = step(delta_abs.y, threshold);
                float isVertical = step(delta_abs.x, threshold);
                float isStraightMove = max(isHorizontal, isVertical);

                // -- Making the parallelogram sdf (diagonal move) --

                // animate the TOP-LEFT corners
                vec2 head_pos_tl = mix(previousCursor.xy, currentCursor.xy, head_eased);
                vec2 tail_pos_tl = mix(previousCursor.xy, currentCursor.xy, tail_eased);

                float isTopRightLeading = determineIfTopRightIsLeading(currentCursor.xy, previousCursor.xy);
                float isBottomLeftLeading = 1.0 - isTopRightLeading;
                
                // v0, v1 : "front" of the trail (head)
                vec2 v0 = vec2(head_pos_tl.x + currentCursor.z * isTopRightLeading, head_pos_tl.y - currentCursor.w);
                vec2 v1 = vec2(head_pos_tl.x + currentCursor.z * isBottomLeftLeading, head_pos_tl.y);
                
                // v2, v3: "back" of the trail (tail)
                vec2 v2 = vec2(tail_pos_tl.x + currentCursor.z * isBottomLeftLeading, tail_pos_tl.y);
                vec2 v3 = vec2(tail_pos_tl.x + currentCursor.z * isTopRightLeading, tail_pos_tl.y - previousCursor.w);

                float sdfTrail_diag = getSdfParallelogram(vu, v0, v1, v2, v3);

                // -- Making the rectangle sdf (straight move) --

                vec2 head_center = mix(centerCP, centerCC, head_eased);
                vec2 tail_center = mix(centerCP, centerCC, tail_eased);

                vec2 min_center = min(head_center, tail_center);
                vec2 max_center = max(head_center, tail_center);
                
                vec2 box_size = (max_center - min_center) + currentCursor.zw;
                vec2 box_center = (min_center + max_center) * 0.5;

                float sdfTrail_rect = getSdfRectangle(vu, box_center, box_size * 0.5);

                // -- FINAL SELECTING AND DRAWING --
                float sdfTrail = mix(sdfTrail_diag, sdfTrail_rect, isStraightMove);
                
                vec4 trail = TRAIL_COLOR;
                float trailAlpha = antialising(sdfTrail);
                newColor = mix(newColor, trail, trailAlpha);

                // punch hole
                newColor = mix(newColor, fragColor, step(sdfCurrentCursor, 0.));
            }

            fragColor = newColor;
        }
      '';

      home.packages = [ config.programs.ghostty.package ];
    };
  };
}
