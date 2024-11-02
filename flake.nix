{
  description = "JackCres Flake Config";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "nixpkgs/nixos-24.05";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # External flakes
    zen-browser.url = "github:omarcresp/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";

    hcp-cli.url = "github:omarcresp/hcp-cli-flake";

    pulumi-overlay.url = "github:saiintbrisson/nixpkgs";

    zig.url = "github:mitchellh/zig-overlay";
    zig.inputs.nixpkgs.follows = "nixpkgs";

    ulauncher.url = "github:Ulauncher/Ulauncher/v6";
    ulauncher.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, home-manager, nixpkgs-stable, pulumi-overlay, ... }@inputs:
  let
    lib = nixpkgs.lib;
    # hlib = home-manager.lib;
    system = "x86_64-linux";
    stable = nixpkgs-stable.legacyPackages.${system};
    pulumi = pulumi-overlay.legacyPackages.${system};
    pulumiOverlay = final: prev: {
      pulumi = import pulumi-overlay {
        inherit system;
        config.allowUnfree = true;
      };
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
                overlays = [ stableOverlay pulumiOverlay ];
                config.allowUnfree = true;
              };
            })
            ./configuration.nix
            home-manager.nixosModules.home-manager {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.jackcres = ./home.nix;
              home-manager.extraSpecialArgs = { inherit inputs stable pulumi; };
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
