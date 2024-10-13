{
  description = "JackCres Flake Config";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # External flakes
    zen-browser.url = "github:omarcresp/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";

    zig.url = "github:mitchellh/zig-overlay";
    zig.inputs.nixpkgs.follows = "nixpkgs";

    ulauncher.url = "github:Ulauncher/Ulauncher/v6";
    ulauncher.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, home-manager, ... }@inputs:
  let
    lib = nixpkgs.lib;
    hlib = home-manager.lib;
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    user = "jackcres";
  in
    {
      nixosConfigurations = {
        nixos-jackcres = lib.nixosSystem {
          inherit system;
          modules = [
            ./configuration.nix
            home-manager.nixosModules.home-manager {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.jackcres = ./home.nix;
              home-manager.extraSpecialArgs = { inherit inputs; };
            }
          ];
        };
      };

      homeConfigurations = {
        jackcres = hlib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home.nix ./hyprland.nix ];
          extraSpecialArgs = { inherit inputs; };
        };
      };
    };
}
