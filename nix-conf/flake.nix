{
  description = "My System";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    devenv.url = "github:cachix/devenv/latest";
    devenv.inputs.nixpkgs.follows = "unstable";
  };

  outputs = {
    self,
    nixpkgs,
    nixos-wsl,
    unstable,
    home-manager,
    sops-nix,
    devenv,
  } @ inputs: let
    inherit (self) outputs;
    systems = ["x86_64-linux" "aarch64-linux"];
    forEachSystem = nixpkgs.lib.genAttrs systems;
    pkgsFor = system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
  in {
    # Available through 'nixos-rebuild --flake .#your-hostname'
    nixosConfigurations = {
      # FIXME replace with your hostname
      your-hostname = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs outputs;
          pkgs-unstable = import unstable {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
        };
        modules = [
          nixos-wsl.nixosModules.default
          ./configuration.nix
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.tj = ./home.nix;
              extraSpecialArgs = {
                inherit inputs outputs;
              };
            };
          }
        ];
      };
    };

    # Development shells
    devShells = forEachSystem (
      system: let
        pkgs = pkgsFor system;
      in {
        default = pkgs.mkShell {
          name = "dev-shell";
          buildInputs = with pkgs; [
            # Nix development tools
            alejandra
            statix
            nil

            # Python development tools
            black
            ruff
            python3

            # JavaScript/Node.js development tools
            nodejs
            nodePackages.eslint
            nodePackages.prettier

            # General development tools
            pre-commit
            git

            # System tools
            coreutils
            findutils
            gnused
          ];

          shellHook = ''
            echo "🚀 Development environment loaded!"
            echo "Available tools:"
            echo "  - alejandra (Nix formatter)"
            echo "  - statix (Nix linter)"
            echo "  - nil (Nix LSP)"
            echo "  - black, ruff (Python tools)"
            echo "  - nodejs, eslint, prettier (JS tools)"
            echo "  - pre-commit (Git hooks)"
            echo ""
            echo "Run 'nix flake check' to run all checks"
          '';
        };
      }
    );

    # Formatter for 'nix fmt'
    formatter = forEachSystem (system: (pkgsFor system).alejandra);

    # Checks for 'nix flake check'
    checks = forEachSystem (
      system: let
        pkgs = pkgsFor system;
      in {
        # Nix formatting check
        alejandra-fmt =
          pkgs.runCommand "alejandra-fmt-check" {
            buildInputs = [pkgs.alejandra];
          } ''
            cd ${self}
            alejandra --check .
            touch $out
          '';

        # Nix static analysis check
        statix-lint =
          pkgs.runCommand "statix-lint-check" {
            buildInputs = [pkgs.statix];
          } ''
            cd ${self}
            statix check .
            touch $out
          '';

        # Pre-commit hooks check (if .pre-commit-config.yaml exists)
        pre-commit-check =
          pkgs.runCommand "pre-commit-check" {
            buildInputs = [pkgs.pre-commit];
          } ''
            cd ${self}
            if [ -f .pre-commit-config.yaml ]; then
              pre-commit run --all-files
            fi
            touch $out
          '';
      }
    );

    # NixOS modules (if you have custom modules)
    #    nixosModules = import ./modules/nixos;

    # Home Manager modules (if you have custom modules)
    #    homeManagerModules = import ./modules/home-manager;
  };
}
