{
  description = "JackCres Flake Config";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "nixpkgs/nixos-24.05";
    nixpkgs-zelda.url = "github:qubitnano/nixpkgs/pr/recomp";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # External flakes
    zen-browser.url = "github:omarcresp/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";

    hcp-cli.url = "github:omarcresp/hcp-cli-flake";

    zig.url = "github:mitchellh/zig-overlay";
    zig.inputs.nixpkgs.follows = "nixpkgs";

    ulauncher.url = "github:ulauncher/Ulauncher/v6";
    ulauncher.inputs.nixpkgs.follows = "nixpkgs";

    # jack-nixvim.url = "github:omarcresp/jack-nixvim";
    jack-nixvim.url = "/home/jackcres/Programming/coding-adventure/oss/jack-nixvim";
    jack-nixvim.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, home-manager, nixpkgs-stable, nixpkgs-zelda, ... }@inputs:
  let
    lib = nixpkgs.lib;
    # hlib = home-manager.lib;
    system = "x86_64-linux";
    stable = nixpkgs-stable.legacyPackages.${system};
    zelda64 = import nixpkgs-zelda {
      inherit system;
      config.allowUnfree = true;
    };
    stableOverlay = final: prev: {
      stable = import nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
      };
    };
    # pkgs = nixpkgs.legacyPackages.${system};
    # user = "jackcres";
  in
    {
      nixosConfigurations = {
        nixos-jackcres = lib.nixosSystem {
          inherit system;
          modules = [
            ({
              nixpkgs = {
                overlays = [ stableOverlay ];
                config.allowUnfree = true;
              };
            })
            ./configuration.nix
            home-manager.nixosModules.home-manager {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.jackcres = ./home.nix;
              home-manager.extraSpecialArgs = {
                inherit inputs stable;
                zelda64 = zelda64.zelda64recomp;
              };
            }
          ];
        };
      };

      # homeConfigurations = {
      #   jackcres = hlib.homeManagerConfiguration {
      #     inherit pkgs;
      #     modules = [ ./home.nix ./hyprland.nix ];
      #     extraSpecialArgs = { inherit inputs; };
      #   };
      # };
    };
}
