# docker.nix - Docker module for NixOS configuration
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.myDocker;
in
{
  options.services.myDocker = {
    enable = mkEnableOption "Enable Docker with custom configuration";

    rootless = mkOption {
      type = types.bool;
      default = false;
      description = "Enable rootless Docker for improved security";
    };

    storageDriver = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "btrfs";
      description = "Docker storage driver (useful for btrfs filesystems)";
    };

    dataRoot = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/var/lib/docker-data";
      description = "Custom data root directory for Docker";
    };

    registryMirrors = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "https://mirror.gcr.io" ];
      description = "List of registry mirrors for faster pulls";
    };

    addressPools = mkOption {
      type = types.listOf (types.submodule {
        options = {
          base = mkOption {
            type = types.str;
            example = "172.30.0.0/16";
            description = "Base IP range for Docker networks";
          };
          size = mkOption {
            type = types.int;
            example = 24;
            description = "Subnet size";
          };
        };
      });
      default = [ { base = "172.30.0.0/16"; size = 24; } ];
      description = "Custom address pools to avoid network conflicts";
    };

    enableCompose = mkOption {
      type = types.bool;
      default = true;
      description = "Enable docker-compose";
    };

    users = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Users to add to the docker group";
    };

    containers = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          image = mkOption { type = types.str; description = "Container image"; };
          ports = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "Port mappings";
          };
          volumes = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "Volume mounts";
          };
          environment = mkOption {
            type = types.attrsOf types.str;
            default = {};
            description = "Environment variables";
          };
          autoStart = mkOption {
            type = types.bool;
            default = true;
            description = "Start container automatically";
          };
        };
      });
      default = {};
      description = "OCI containers to run as systemd services";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.docker = {
      enable = !cfg.rootless;
      storageDriver = cfg.storageDriver;
      daemon.settings = {
        experimental = true;
        registry-mirrors = cfg.registryMirrors;
        default-address-pools = cfg.addressPools;
        log-driver = "journald";
        dns = [ "1.1.1.1" "8.8.8.8" ];
      } // optionalAttrs (cfg.dataRoot != null) {
        data-root = cfg.dataRoot;
      };

      rootless = mkIf cfg.rootless {
        enable = true;
        setSocketVariable = true;
        daemon.settings = {
          registry-mirrors = cfg.registryMirrors;
          dns = [ "1.1.1.1" "8.8.8.8" ];
        };
      };
    };

    environment.systemPackages = with pkgs; [
      docker
    ] ++ optional cfg.rootless podman
      ++ optional cfg.enableCompose docker-compose;

    users.users = mkMerge (map (user: {
      ${user} = {
        extraGroups = [ "docker" ];
      };
    }) cfg.users);

    virtualisation.oci-containers = mkIf (cfg.containers != {}) {
      backend = if cfg.rootless then "podman" else "docker";
      containers = mapAttrs (_: c: {
        inherit (c) image ports volumes environment autoStart;
      }) cfg.containers;
    };

    systemd.tmpfiles.rules = mkIf cfg.rootless (
      map (user: "f /var/lib/systemd/linger/${user} 0644 root root - -") cfg.users
    );

    system.activationScripts.enableLingering = mkIf cfg.rootless {
      text = concatMapStringsSep "\n" (user: "loginctl enable-linger ${user}") cfg.users;
    };
  };
}
