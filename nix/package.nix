{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  wrapGAppsHook3,
  makeDesktopItem,
  copyDesktopItems,
  alsa-lib,
  at-spi2-atk,
  cairo,
  fontconfig,
  freetype,
  fribidi,
  gdk-pixbuf,
  glib,
  glib-networking,
  gnutls,
  gtk3,
  harfbuzz,
  lcms2,
  libarchive,
  libdrm,
  libepoxy,
  libgbm,
  libGL,
  libpulseaudio,
  libsecret,
  libsoup_3,
  libunwind,
  libva,
  libvdpau,
  libx11,
  libxcb,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  libxscrnsaver,
  libxv,
  lz4,
  pango,
  vulkan-loader,
  wayland,
  webkitgtk_4_1,
  xz,
  zlib,
}:

let
  # Written by .github/workflows/nix-update.yml on every release.
  release = lib.importJSON ./release.json;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "animeflow";
  inherit (release) version;

  src = fetchurl {
    url = "https://github.com/openAnimeFlow/AnimeFlow/releases/download/v${finalAttrs.version}/AnimeFlow-linux-${finalAttrs.version}.tar.gz";
    inherit (release) hash;
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    autoPatchelfHook
    wrapGAppsHook3
    copyDesktopItems
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    cairo
    fontconfig
    freetype
    fribidi
    gdk-pixbuf
    glib
    glib-networking
    gnutls
    gtk3
    harfbuzz
    lcms2
    libarchive
    libdrm
    libepoxy
    libgbm
    libGL
    libpulseaudio
    libsecret
    libsoup_3
    libunwind
    libva
    libvdpau
    libx11
    libxcb
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    libxscrnsaver
    libxv
    lz4
    pango
    stdenv.cc.cc.lib
    wayland
    webkitgtk_4_1
    xz
    zlib
  ];

  # libdartjni links libjvm, but the desktop app does not load it.
  autoPatchelfIgnoreMissingDeps = [ "libjvm.so" ];

  # dlopen resolves against the calling library's RUNPATH, which is not transitive:
  # the Dart VM needs $ORIGIN to find libmpv, and libmdk/libmpv need the GPU loaders.
  appendRunpaths = [
    "$ORIGIN"
    (lib.makeLibraryPath [
      libGL
      libva
      libvdpau
      vulkan-loader
    ])
  ];

  dontBuild = true;
  dontConfigure = true;
  dontStrip = true;

  desktopItems = [
    (makeDesktopItem {
      name = "animeflow";
      desktopName = "AnimeFlow";
      comment = "Anime video player";
      exec = "animeflow %U";
      icon = "animeflow";
      startupWMClass = "com.example.anime_flow";
      categories = [
        "AudioVideo"
        "Video"
        "Player"
      ];
    })
  ];

  # The Flutter runner resolves data/ and lib/ from /proc/self/exe, so the tree stays intact.
  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/animeflow $out/bin
    cp -r anime_flow data lib $out/lib/animeflow/
    chmod +x $out/lib/animeflow/anime_flow
    ln -s $out/lib/animeflow/anime_flow $out/bin/animeflow
    install -Dm644 ${../assets/features/logo.png} $out/share/pixmaps/animeflow.png
    runHook postInstall
  '';

  meta = {
    description = "Cross-platform anime player with Bangumi sync and DanDanPlay danmaku";
    homepage = "https://github.com/openAnimeFlow/AnimeFlow";
    license = lib.licenses.agpl3Only;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "animeflow";
    platforms = [ "x86_64-linux" ];
  };
})
