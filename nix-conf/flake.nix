{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nixos-wsl.inputs.nixpkgs.follows= "nixpkgs";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix = {
     url = "github:mic92/sops-nix";
     inputs.nixpkgs.follows = "unstable";
   };
    devenv.url = "github:cachix/devenv/latest";
  };

  outputs = { 
  self, 
  nixpkgs, 
  nixos-wsl, 
  unstable, 
  home-manager, 
  ... 
  } @inputs: 
  let
    inherit (self) outputs;
  in {
      # Available through 'nixos-rebuild --flake .#your-hostname'
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs outputs;};
        modules = [
          nixos-wsl.nixosModules.default
          ./configuration.nix
           # Home manager as NixOS module
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.tj = ./home.nix;
            }
       ];
      };
    };
  #    homeConfigurations = {
      # FIXME replace with your username@hostname
   #   "tj@nixos" = home-manager.lib.homeManagerConfiguration {
 #       pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
 #       extraSpecialArgs = {inherit inputs outputs;};
        # > Our main home-manager configuration file <
 #       modules = [./home.nix];
   #   };
    #};
    
#  outputs = self.nixosConfigurations;
  };
}
