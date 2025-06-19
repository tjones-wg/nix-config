# home.nix - Home Manager configuration
{ config, pkgs, inputs, ... }:

let
  # Pure config file generation (no destination!)
  nuConfigFile = pkgs.writeText "nu-config.nu" ''
    let carapace_completer = {|spans|
      carapace $spans.0 nushell ...$spans | from json
    }

    $env.config = {
      show_banner: false,
      completions: {
        case_sensitive: false
        quick: true
        partial: true
        algorithm: "fuzzy"
        external: {
          enable: true
          max_results: 100
          completer: $carapace_completer
        }
      }
    }

    $env.PATH = ($env.PATH |
      split row (char esep) |
      prepend home/tj/.apps |
      append /usr/bin/env
    )
  '';
in

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "tj";
  home.homeDirectory = "/home/tj";

  # User-specific packages
  home.packages = with pkgs; [
    # sync shell history
    atuin
    
    # Development tools
    docker
    compose2nix
    git-crypt
    sops
    just
    lunarvim
    direnv
    vscode
    starship

    # Programming languages
    python314
    go
    carapace
    
    # Additional tools you might want
    age # works well with sops
    ssh-to-age # for sops key conversion
  ];

  # Program configurations
  programs = {
    atuin = {
      enable = true;
      settings = {
       # sync_address = IODEV01";
        sync_frequency = "15m";
        dialect = "us";
      };
    };

    # Shell
    # Pure config file generation (no destination!)
  nushell = {
    enable = true;
    configFile = {
      source = nuConfigFile;
    };
    shellAliases = {
      vi = "lunarvim";
      vim = "lunarvim";
      nano = "nano";
    };
  };

  carapace = {
    enable = true;
    enableNushellIntegration = true;
  };

  starship = {
    enable = true;
    settings = {
      add_newline = true;
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
    };
  };

 
    # Version control
    git = {
      enable = true;
      userName = "tjones-wg";
      userEmail = "tj@wgcpas.com"; # Replace with your actual email
      extraConfig = {
        init.defaultBranch = "dev";
        pull.rebase = false;
        # Add git-crypt configuration if needed
      };
      
      # Git aliases
      aliases = {
        st = "status";
        co = "checkout";
        br = "branch";
        ci = "commit";
      };
    };
    
    # Terminal multiplexer
    tmux = {
      enable = true;
      terminal = "screen-256color";
      historyLimit = 100000;
      shortcut = "t";
      clock24 = true; 
      extraConfig = ''
        # Custom tmux configuration
        set -g mouse on
        set -g base-index 1
        setw -g pane-base-index 1
        
        # Key bindings
        bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"
        
        # Status bar
        set -g status-bg black
        set -g status-fg white
      '';
    };
    

    # Enable home-manager to manage itself
    home-manager.enable = true;
  };

  # Environment variables
  home.sessionVariables = {
    EDITOR = "code";
    BROWSER = "firefox";
    # SOPS configuration
    SOPS_AGE_KEY_FILE = "$HOME/.config/sops/age/keys.txt";
  };

  systemd.user.startServices = "sd-switch";
  # This value determines the Home Manager release which your
  # configuration is compatible with.
  home.stateVersion = "25.05"; # Match your system version
}
