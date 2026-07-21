{
  lib,
  rustPlatform,
  pkg-config,
  dbus,
  stdenv,
}:
rustPlatform.buildRustPackage {
  pname = "dendritic";
  version = "0.1.0";
  src = ./.;
  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ dbus ];

  meta = {
    description = "Monolithic dendritic CLI + privileged helper";
    mainProgram = "dendritic";
    license = lib.licenses.mit;
  };
}
