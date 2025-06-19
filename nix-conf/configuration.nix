{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    #    <home-manager/nixos>
    #./hardware-configuration.nix
    # imports are handled by at the flake level.
  ];

  users.users.tj = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager" "docker"];
    shell = pkgs.nushell;
  };

  wsl = {
    enable = true;
    wslConf = {
      interop.appendWindowPath = false;
      network.generateHosts = false;
      automount.root = "/mnt";
    };
    defaultUser = "tj";
    startMenuLaunchers = true;
    docker-desktop.enable = true;
  };

  home-manager.users.tj = {pkgs, ...}: {
    programs.nushell.enable = true;

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    home.stateVersion = "25.05"; # Please read the comment before changing.
  };

  nixpkgs.config.allowUnfree = true;

  nix = {
    package = pkgs.nixVersions.git;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
    settings = {
      trusted-users = ["root" "@wheel"];
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        #  ""
      ];
    };
  };

  virtualisation.docker = {
    #    enable = true;
    storageDriver = "btrfs";
    enableOnBoot = true;
    autoPrune.enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
    daemon.settings = {
      data-root = "../../docker-data";
      userland-proxy = false;
      experimental = true;
      metrics-addr = "0.0.0.0:9323";
      ipv6 = true;
      fixed-cidr-v6 = "fd00::/80";
    };
  };

  services = {
    atuin = {
      enable = true;
      maxHistoryLength = 8192;
    };
    openssh.enable = true;
  };

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
  };
}
