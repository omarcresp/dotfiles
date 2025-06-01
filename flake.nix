{
  description = "JackCres nix system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-zelda.url = "github:qubitnano/nixpkgs/pr/recomp";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    mac-app-util.url = "github:hraban/mac-app-util";
    mac-app-util.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    zen-browser.url = "github:omarcresp/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";

    cursor.url = "github:omarcresp/cursor-flake";
    cursor.inputs.nixpkgs.follows = "nixpkgs";

    zig.url = "github:mitchellh/zig-overlay";
    zig.inputs.nixpkgs.follows = "nixpkgs";

    ulauncher.url = "github:ulauncher/Ulauncher/v6";
    ulauncher.inputs.nixpkgs.follows = "nixpkgs";

    jack-nixvim.url = "github:omarcresp/jack-nixvim";
    jack-nixvim.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, home-manager, nix-homebrew, nixpkgs, mac-app-util, ... }: let
    user = "jackcres";
    zelda64 = import inputs.nixpkgs-zelda {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };
    nixpkgsCfg = { config.allowUnfree = true; };
  in {
    darwinConfigurations.pro = nix-darwin.lib.darwinSystem {
      specialArgs = { inherit inputs user; };
      modules = [
        nix-homebrew.darwinModules.nix-homebrew
        mac-app-util.darwinModules.default
        ./hosts/mbp/system.nix
        home-manager.darwinModules.home-manager
        {
          nixpkgs = nixpkgsCfg;

          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.sharedModules = [ mac-app-util.homeManagerModules.default ];
          home-manager.users.${user} = ./hosts/mbp/home.nix;
          home-manager.extraSpecialArgs = { inherit inputs user; };
        }
      ];
    };

    nixosConfigurations = {
      nixos-jackcres = nixpkgs.lib.nixosSystem {
        system = null;
        specialArgs = { inherit inputs user; };
        modules = [
          { nixpkgs = nixpkgsCfg; }
          ./hosts/nixos/system.nix
          home-manager.nixosModules.home-manager
          {
            nixpkgs = nixpkgsCfg;

            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.users.${user} = ./hosts/nixos/home.nix;
            home-manager.extraSpecialArgs = { inherit inputs user; zelda64 = zelda64.zelda64recomp; };
          }
        ];
      };
    };
  };
}
