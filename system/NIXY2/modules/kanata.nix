{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.kanata = {
    enable = true; # Enable the Kanata service

    keyboards = {
      "internalKeyboard" = {
        devices = [ "/dev/input/event2" ]; # Use the event associated with your internal keyboard

        config = ''
          (defsrc
            grv  1    2    3    4    5    6    7    8    9    0    -    =    bspc
            tab  q    w    e    r    t    y    u    i    o    p    [    ]    \
            caps a    s    d    f    g    h    j    k    l    ;    '    ret
            lsft z    x    c    v    b    n    m    ,    .    /    rsft
            lctl lalt lmet           spc            ralt rmet rctl
          )

          (deflayer default
            grv  1    2    3    4    5    6    7    8    9    0    -    =    bspc
            tab  q    w    e    r    t    y    u    i    o    p    [    ]    \
            caps a    s    d    f    g    h    j    k    l    ;    '    ret
            lsft z    x    c    v    b    n    m    ,    .    /    rsft
            lctl lmet lalt           spc            ralt rmet rctl
          )

          (deflayer dvorak
            grv  1    2    3    4    5    6    7    8    9    0    [    ]    bspc
            tab  '    ,    .    p    y    f    g    c    r    l    /    =    \
            caps a    o    e    u    i    d    h    t    n    s    -    ret
            lsft ;    q    j    k    x    b    m    w    v    z    rsft
            lctl lmet lalt           spc            ralt rmet rctl
          )
        ''; # The config must be a string, written in Kanata's expected format
      };
    };
  };
}
