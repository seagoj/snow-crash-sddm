{
  description = "Snow Crash SDDM theme — Nix package and NixOS module";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system:
        let pkgs = import nixpkgs { inherit system; }; in
        {
          default = pkgs.callPackage ./package.nix { };
        });

      nixosModules.default = ./nixosModules/default.nix;
      # Alias so users can import via either name; mirrors the
      # convention used by agenix / sops-nix.
      nixosModules.snow-crash = self.nixosModules.default;
    };
}