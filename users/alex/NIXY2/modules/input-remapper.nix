{ pkgs, config, ... }:

{
  xdg.configFile."input-remapper-2/config.json" = {
  text = ''
{
    "version": "2.0.1",
    "autoload": {
        "Apple Internal Keyboard / Trackpad": "swap_internal_mod_keys"
    }
} 
'';
  };
  xdg.configFile."input-remapper-2/presets/Apple Internal Keyboard _ Trackpad/swap_internal_mod_keys.json" = {
    text = ''
[
    {
        "input_combination": [
            {
                "type": 1,
                "code": 125,
                "origin_hash": "4a8fbb139565ff8b56192411905e6106"
            }
        ],
        "target_uinput": "keyboard",
        "output_symbol": "Alt_L",
        "mapping_type": "key_macro"
    },
    {
        "input_combination": [
            {
                "type": 1,
                "code": 56,
                "origin_hash": "4a8fbb139565ff8b56192411905e6106"
            }
        ],
        "target_uinput": "keyboard",
        "output_symbol": "Super_L",
        "mapping_type": "key_macro"
    },
    {
        "input_combination": [
            {
                "type": 1,
                "code": 29,
                "origin_hash": "4a8fbb139565ff8b56192411905e6106"
            }
        ],
        "target_uinput": "keyboard",
        "output_symbol": "Control_L",
        "mapping_type": "key_macro"
    },
    {
        "input_combination": [
            {
                "type": 1,
                "code": 464,
                "origin_hash": "4a8fbb139565ff8b56192411905e6106"
            }
        ],
        "target_uinput": "keyboard",
        "output_symbol": "Control_L",
        "mapping_type": "key_macro"
    }
]
    '';
  };
  
}
