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
#          ./modules/docker.nix
           # Home manager as NixOS module
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.tj = ./home.nix;
            }
#          {
#            services.myDocker = {
#              enable = true;
#              rootless = true;
#              enableCompose = true;
#              users = [ "tj" ];

#              registryMirrors = [ "https://mirror.gcr.io" ];
#              addressPools = [
#                { base = "172.30.0.0/16"; size = 24; }
#              ];

#              containers = {
#                redis = {
#                  image = "redis:7-alpine";
#                  ports = [ "6379:6379" ];
#                  volumes = [ "/var/lib/redis:/data" ];
#                  environment = {
#                    REDIS_APPENDONLY = "yes";
#                  };
#                };
#                nginx = {
#                  image = "nginx:alpine";
#                  ports = [ "8080:80" ];
#                  volumes = [ "/var/www:/usr/share/nginx/html:ro" ];
#                };
#              };
#            };
#          }
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
