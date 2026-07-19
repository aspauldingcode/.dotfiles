# macrdp packaging

- `macrdp-server` — prebuilt `aarch64-darwin` binary (ScreenCaptureKit needs Xcode Swift;
  nix builders cannot reliably invoke `swift build`).
- `_package.nix` — installs that binary into the store.
- `Cargo.lock` — kept for a future source build if/when Swift is available in the builder.

## Rebuild the binary

```bash
git clone --depth 1 https://github.com/x6nux/macrdp.git /tmp/macrdp-src
cd /tmp/macrdp-src
# pin: 6be70bbd1d897a9c977984618bf89ee1108eb693
nix shell nixpkgs#cargo nixpkgs#rustc -c cargo build --release -p macrdp-server
cp -f target/release/macrdp-server \
  /etc/nix-darwin/.dotfiles/modules/apps/macrdp/macrdp-server
```
