{ rustPlatform, lib, ... }:
rustPlatform.buildRustPackage {
  pname = "dendritic-appearance";
  version = "0.2.0";
  src = ./.;
  cargoLock.lockFile = ./Cargo.lock;
  meta = {
    description = "Dendritic light/dark appearance state machine";
    mainProgram = "dendritic-appearance";
    license = lib.licenses.mit;
  };
}
