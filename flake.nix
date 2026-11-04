{
  description = "AnimeFlow, packaged from the official Linux release";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      animeflow = pkgs.callPackage ./nix/package.nix { };
    in
    {
      packages.${system} = {
        inherit animeflow;
        default = animeflow;
      };
      apps.${system}.default = {
        type = "app";
        program = "${animeflow}/bin/animeflow";
      };
    };
}
