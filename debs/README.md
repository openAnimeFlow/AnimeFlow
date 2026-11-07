# Packages

Put one `.deb` per package version here, named
`<Package>_<Version>_<Architecture>.deb`, and push.

Each package's control file needs these fields:

```debcontrol
Package: com.example.tweak
Name: Example Tweak
Version: 1.0.0
Architecture: iphoneos-arm64
Description: A short description.
Maintainer: Your Name <you@example.com>
Author: Your Name <you@example.com>
Section: Tweaks
```

`Section` is the package's category (Tweaks, Applications, Utilities,
Themes…); the index refuses a package without it. `Depiction`,
`SileoDepiction` and `Icon` may point into `depictions/<package id>/`.
Rootless packages are `iphoneos-arm64`, roothide ones `iphoneos-arm64e`.
