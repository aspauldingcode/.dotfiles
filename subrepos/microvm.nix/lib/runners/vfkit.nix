{ pkgs
, microvmConfig
, withDriveLetters
, ...
}:

let
  inherit (pkgs) lib;
  inherit (vmHostPackages.stdenv.hostPlatform) system;
  inherit (microvmConfig) vmHostPackages;

  vfkitPkg = microvmConfig.vfkit.package;

  inherit (microvmConfig)
    vcpu mem user interfaces shares socket hostName
    storeOnDisk storeDisk kernel initrdPath kernelParams
    balloon devices credentialFiles vsock graphics;

  inherit (microvmConfig.vfkit) extraArgs logLevel;

  volumesWithLetters = withDriveLetters microvmConfig;

  # vfkit requires uncompressed kernel
  kernelPath = "${kernel.out}/${pkgs.stdenv.hostPlatform.linux-kernel.target}";

  kernelConsole = if graphics.enable then "tty0" else "hvc0";

  kernelCmdLine = [ "console=${kernelConsole}" "reboot=t" "panic=-1" ] ++ kernelParams;


  deviceArgs =
    [
      "--device" "virtio-rng"
    ]
    ++ (if graphics.enable then [
      "--device" "virtio-gpu"
      "--device" "virtio-input,keyboard"
      "--device" "virtio-input,pointing"
    ] else [
      "--device" "virtio-serial,stdio"
    ])
    ++ lib.optionals storeOnDisk [
      "--device" "virtio-blk,path=${storeDisk},readonly"
    ]
    ++ (builtins.concatMap ({ image, ... }: [
      "--device" "virtio-blk,path=${image}"
    ]) volumesWithLetters)
    ++ (builtins.concatMap ({ proto, source, tag, ... }:
      if proto == "virtiofs" then [
        "--device" "virtio-fs,sharedDir=${source},mountTag=${tag}"
      ]
      else
        throw "vfkit does not support ${proto} share. Use proto = \"virtiofs\" instead."
    ) shares)
    ++ (builtins.concatMap ({ type, id, mac, ... }:
      if type == "user" then [
        "--device" "virtio-net,nat,mac=${mac}"
      ]
      else if type == "bridge" then
        throw "vfkit bridge networking requires vmnet-helper which is not yet implemented. Use type = \"user\" for NAT networking."
      else
        throw "vfkit does not support ${type} networking on macOS. Use type = \"user\" for NAT networking."
    ) interfaces);

  canShutdown = socket != null;

  allArgs = [
    "--cpus" (toString vcpu)
    "--memory" (toString mem)
    "--kernel" kernelPath
    "--initrd" initrdPath
    "--kernel-cmdline" (builtins.concatStringsSep " " kernelCmdLine)
  ]
  ++ lib.optionals (logLevel != null) [ "--log-level" logLevel ]
  ++ lib.optionals graphics.enable [ "--gui" ]
  ++ deviceArgs
  ++ extraArgs;

in
{
  inherit canShutdown;
  tapMultiQueue = false;
  requiresMacvtapAsFds = false;
  supportsNotifySocket = false;

  preStart = lib.optionalString (socket != null) "rm -f ${socket}\n";

  command =
    let
      # Validation
      check = cond: msg: if cond then throw msg else null;
      errors = [
        (check (!vmHostPackages.stdenv.hostPlatform.isDarwin) "vfkit only works on macOS (Darwin)")
        (check (vmHostPackages.stdenv.hostPlatform.isAarch64 != pkgs.stdenv.hostPlatform.isAarch64) "Architecture mismatch")
        (check (user != null) "vfkit does not support changing user")
        (check (balloon) "vfkit does not support memory ballooning")
        (check (devices != []) "vfkit does not support device passthrough")
        (check (credentialFiles != {}) "vfkit does not support credentialFiles")
      ];
      valid = lib.all (e: e == null) errors;
    in
    if !valid then lib.findFirst (e: e != null) null errors
    else
      let
        vfkitArgs = lib.concatStringsSep " " (map lib.escapeShellArg allArgs);
      in
      "bash -c " + lib.escapeShellArg ''
        ARGS=(${vfkitArgs})
        ${lib.optionalString (socket != null) ''
          S=${lib.escapeShellArg socket}
          [[ "$S" != /* ]] && S="$PWD/$S"
          ARGS+=(--restful-uri "unix://$S")
        ''}
        ${lib.optionalString (vsock.cid != null) ''
          V="${hostName}-vsock.sock"
          [[ "$V" != /* ]] && V="$PWD/$V"
          ARGS+=(--device "virtio-vsock,port=1024,socketURL=$V")
        ''}
        exec ${lib.getExe vfkitPkg} "''${ARGS[@]}"
      '';

  shutdownCommand = lib.optionalString canShutdown ''
    S="${socket}"; [[ "$S" != /* ]] && S="$PWD/$S"
    echo '{"state": "Stop"}' | ${lib.getExe vmHostPackages.socat} - "UNIX-CONNECT:$S"
  '';
}
