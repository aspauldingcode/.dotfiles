{ lib, ... }:

# Configure application filetype defaults.
{
  xdg.mimeApps = {
    enable = true;
    associations = lib.mkForce {
      added = {
        # applications
        "application/pdf" = [
          "org.kde.okular.desktop"
          "brave-browser.desktop"
          "org.kde.gwenview.desktop"
        ];

        # audio
        "audio/mp4" = "org.kde.elisa.desktop";
        "audio/vnd.wave" = "org.kde.elisa.desktop";

        # images
        # RASTER images
        "image/bmp" = "org.kde.gwenview.desktop";
        "image/gif" = [
          "org.kde.gwenview.desktop"
          "org.kde.okular.desktop"
        ];
        "image/jpeg" = [
          "org.kde.gwenview.desktop"
          "org.kde.okular.desktop"
        ];
        "image/mng" = "org.kde.gwenview.desktop";
        "image/png" = [
          "org.kde.gwenview.desktop"
          "org.kde.okular.desktop"
        ];
        "image/psd" = "org.kde.gwenview.desktop";
        "image/raw" = "org.kde.gwenview.desktop";
        "image/svg" = "org.kde.gwenview.desktop";
        "image/tiff" = [
          "org.kde.gwenview.desktop"
          "org.kde.okular.desktop"
        ];
        "image/xcf" = "org.kde.gwenview.desktop";

        # VECTOR images
        "application/illustrator" = "org.kde.gwenview.desktop";
        "application/postscript" = "org.kde.gwenview.desktop";
        "image/svg+xml" = "org.kde.gwenview.desktop";
        "image/vnd.dxf" = "org.kde.gwenview.desktop";

        # applications:
        "applications/pdf" = "org.kde.okular.desktop";
        "applications/epub+zip" = "org.kde.okular.desktop";
        "applications/vnd.djvu" = "org.kde.okular.desktop";
        "text/markdown" = "org.kde.okular.desktop";
        "image/webp" = "org.kde.okular.desktop";

        # comics:
        "application/vnd.comicbook-rar" = "org.kde.okular.desktop";
        "application/vnd.comicbook+zip" = "org.kde.okular.desktop";

        # archives
        "application/ace" = "org.kde.ark.desktop";
        "application/apk" = "org.kde.ark.desktop";
        "application/arj" = "org.kde.ark.desktop";
        "application/arc" = "org.kde.ark.desktop";
        "application/bz2" = "org.kde.ark.desktop";
        "application/cab" = "org.kde.ark.desktop";
        "application/cabinet" = "org.kde.ark.desktop";
        "application/dmg" = "org.kde.ark.desktop";
        "application/ear" = "org.kde.ark.desktop";
        "application/gz" = "org.kde.ark.desktop";
        "application/iso" = "org.kde.ark.desktop";
        "application/jar" = "org.kde.ark.desktop";
        "application/lzh" = "org.kde.ark.desktop";
        "application/lzma" = "org.kde.ark.desktop";
        "application/pea" = "org.kde.ark.desktop";
        "application/rar" = "org.kde.ark.desktop";
        "application/tar" = "org.kde.ark.desktop";
        "application/tbz2" = "org.kde.ark.desktop";
        "application/tgz" = "org.kde.ark.desktop";
        "application/txz" = "org.kde.ark.desktop";
        "application/uha" = "org.kde.ark.desktop";
        "application/war" = "org.kde.ark.desktop";
        "application/wim" = "org.kde.ark.desktop";
        "application/xz" = "org.kde.ark.desktop";
        "application/z" = "org.kde.ark.desktop";
        "application/zip" = [
          "org.kde.ark.desktop"
          "xarchiver.desktop"
        ];
        "application/zoo" = "org.kde.ark.desktop";
        "application/zpaq" = "org.kde.ark.desktop";

        # video
        "video/3GP" = "org.kde.gwenview.desktop";
        "video/AVI" = "org.kde.gwenview.desktop";
        "video/DIVX" = "org.kde.gwenview.desktop";
        "video/FLV" = "org.kde.gwenview.desktop";
        "video/H264" = "org.kde.gwenview.desktop";
        "video/H265" = "org.kde.gwenview.desktop";
        "video/HEVC" = "org.kde.gwenview.desktop";
        "video/M2TS" = "org.kde.gwenview.desktop";
        "video/M4V" = "org.kde.gwenview.desktop";
        "video/MKV" = "org.kde.gwenview.desktop";
        "video/MOV" = "org.kde.gwenview.desktop";
        "video/MP4" = "org.kde.gwenview.desktop";
        "video/MPEG" = "org.kde.gwenview.desktop";
        "video/OGG" = "org.kde.gwenview.desktop";
        "video/RM" = "org.kde.gwenview.desktop";
        "video/RMVB" = "org.kde.gwenview.desktop";
        "video/SWF" = "org.kde.gwenview.desktop";
        "video/TS" = "org.kde.gwenview.desktop";
        "video/VOB" = "org.kde.gwenview.desktop";
        "video/VP9" = "org.kde.gwenview.desktop";
        "video/WEBM" = "org.kde.gwenview.desktop";
        "video/WMV" = "org.kde.gwenview.desktop";
        "video/XVID" = "org.kde.gwenview.desktop";

        # misc
        "x-scheme-handler/magnet" = "userapp-transmission-gtk-6G6QC2.desktop";
      };
      #removed = {
      #    mimetype1 = "foo5.desktop";
      #};
    };
    defaultApplications = {
      # pdf
      "applications/pdf" = "org.kde.okular.desktop";

      # audio
      "audio/mp4" = "org.kde.elisa.desktop";
      "audio/vnd.wave" = "org.kde.elisa.desktop";

      # archives
      "application/zip" = "org.kde.ark.desktop";

      # file browser default
      "inode/directory" = "org.kde.dolphin.desktop";

      # misc
      "x-scheme-handler/magnet" = "userapp-transmission-gtk-6G6QC2.desktop";
    };
  };
}

# xdg-mime returns Thunar.desktop but xdg-open opens nautilus?
# xdg-mime uses mimeapps.list to determine the default application to use.

/* Current config:
   [Added Associations]
   application/pdf=org.kde.okular.desktop;brave-browser.desktop;
   application/zip=xarchiver.desktop;
   audio/mp4=org.kde.elisa.desktop;
   audio/vnd.wave=org.kde.elisa.desktop;
   x-scheme-handler/magnet=userapp-transmission-gtk-6G6QC2.desktop;

   [Default Applications]
   application/pdf=org.kde.okular.desktop;
   application/zip=xarchiver.desktop
   audio/mp4=org.kde.elisa.desktop;
   audio/vnd.wave=org.kde.elisa.desktop;
   x-scheme-handler/magnet=userapp-transmission-gtk-6G6QC2.desktop
*/
