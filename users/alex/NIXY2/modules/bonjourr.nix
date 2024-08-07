
{ buildFirefoxXpiAddon, fetchurl, lib, stdenv }:

{
  bonjourr = buildFirefoxXpiAddon {
    pname = "bonjourr";
    version = "19.2.4";
    addonId = "{12345678-1234-1234-1234-123456789abc}"; # Replace with actual addon ID if known
    url = "https://addons.mozilla.org/firefox/downloads/file/3748349/bonjourr_startpage-19.2.4.xpi";
    sha256 = "2f3e5c8ff63db1a7655ba7f0e8b1a8d1ecb8a8b5ef88f97f58c2f3f9481d5e60"; # Replace with actual sha256 hash

    meta = with lib; {
      homepage = "https://bonjourr.fr/";
      description = "Minimalist and lightweight startpage; Improve your web browsing experience with Bonjourr, a beautiful, customizable and lightweight homepage inspired by iOS.";
      license = licenses.gpl3;
      mozPermissions = [
        "storage"
        "unlimitedStorage"
        "bookmarks"
      ];
      platforms = platforms.all;
    };
  };
}
