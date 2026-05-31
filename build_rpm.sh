#!/bin/bash
set -e

# Disable git proxy temporarily for flutter build to prevent github fetch errors
HTTP_PROXY_VAL=$(git config --global --get http.proxy || true)
HTTPS_PROXY_VAL=$(git config --global --get https.proxy || true)

git config --global --unset http.proxy || true
git config --global --unset https.proxy || true

echo "Building Flutter app for Linux..."
flutter pub get
flutter build linux --release

# Restore git proxy
if [ -n "$HTTP_PROXY_VAL" ]; then
    git config --global http.proxy "$HTTP_PROXY_VAL"
fi
if [ -n "$HTTPS_PROXY_VAL" ]; then
    git config --global https.proxy "$HTTPS_PROXY_VAL"
fi

echo "Preparing RPM build environment..."
RPM_BUILD_DIR="$(pwd)/build/rpmbuild"
mkdir -p "$RPM_BUILD_DIR"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

cat << 'EOF' > "$RPM_BUILD_DIR/SPECS/anime_flow.spec"
%define __brp_check_rpaths %{nil}

Name:           anime_flow
Version:        2.0.0
Release:        1%{?dist}
Summary:        AnimeFlow - Anime Video App built with Flutter
License:        Unknown
URL:            https://github.com/openAnimeFlow/AnimeFlow
BuildArch:      x86_64

%description
AnimeFlow is a highly customizable anime video application supporting multiple platforms.

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/opt/anime_flow
cp -a %{workspace_dir}/build/linux/x64/release/bundle/* $RPM_BUILD_ROOT/opt/anime_flow/

# Add desktop file
mkdir -p $RPM_BUILD_ROOT/usr/share/applications
cat << 'DESKTOP' > $RPM_BUILD_ROOT/usr/share/applications/anime_flow.desktop
[Desktop Entry]
Version=1.0
Name=AnimeFlow
Comment=Anime Video App
Exec=/opt/anime_flow/anime_flow
Icon=anime_flow
Terminal=false
Type=Application
Categories=Video;AudioVideo;
DESKTOP

# Add icon
mkdir -p $RPM_BUILD_ROOT/usr/share/icons/hicolor/512x512/apps
cp %{workspace_dir}/assets/logo/Logo.png $RPM_BUILD_ROOT/usr/share/icons/hicolor/512x512/apps/anime_flow.png

%files
/opt/anime_flow/
/usr/share/applications/anime_flow.desktop
/usr/share/icons/hicolor/512x512/apps/anime_flow.png

%changelog
* Sun May 31 2026 Wang Yang <20234832@stu.cqu.edu.cn> - 2.0.0-1
- Auto-generated RPM build
EOF

echo "Building RPM..."
rpmbuild -bb \
  --define "_topdir $RPM_BUILD_DIR" \
  --define "_builddir $RPM_BUILD_DIR/BUILD" \
  --define "workspace_dir $(pwd)" \
  "$RPM_BUILD_DIR/SPECS/anime_flow.spec"

echo "====================================="
echo "Done! RPM is available in:"
ls -l "$RPM_BUILD_DIR/RPMS/x86_64/"
echo "====================================="
