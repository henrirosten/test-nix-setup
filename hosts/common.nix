{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: let
  asGB = size: toString (size * 1024 * 1024 * 1024);
in {
  imports = [
    ../users/hrosten.nix
    ../users/tester.nix
  ];

  nixpkgs.config.allowUnfree = true;

  nix = {
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mapAttrs (_: value: {flake = value;}) inputs;
    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Subsituters
      trusted-public-keys = [
        "cache.vedenemo.dev:RGHheQnb6rXGK5v9gexJZ8iWTPX6OcSeS56YeXYzOcg="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
      substituters = [
        "https://cache.vedenemo.dev"
        "https://cache.nixos.org"
      ];
      # Auto-free the /nix/store:
      # free up to 50GB whenever there is less than 30GB left:
      min-free = asGB 30;
      max-free = asGB 50;
      # check the free disk space every 10 seconds
      min-free-check-interval = 10;
    };
    # Garbage collection
    gc.automatic = true;
    gc.options = pkgs.lib.mkDefault "--delete-older-than 14d";
  };

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone
  time.timeZone = "Europe/Helsinki";

  # Select internationalisation properties
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fi_FI.UTF-8";
    LC_IDENTIFICATION = "fi_FI.UTF-8";
    LC_MEASUREMENT = "fi_FI.UTF-8";
    LC_MONETARY = "fi_FI.UTF-8";
    LC_NAME = "fi_FI.UTF-8";
    LC_NUMERIC = "fi_FI.UTF-8";
    LC_PAPER = "fi_FI.UTF-8";
    LC_TELEPHONE = "fi_FI.UTF-8";
    LC_TIME = "fi_FI.UTF-8";
  };

  # Enable the X11 windowing system
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver = {
    layout = "fi";
    xkbVariant = "";
  };

  # Configure console keymap
  console.keyMap = "fi";

  # List packages installed in system profile
  environment.systemPackages = with pkgs; [
    wget
    curl
    vim
    git
    htop
    nix-info
  ];

  # Shell
  programs.bash.enableCompletion = true;
  programs.fish.enable = true;

  # Disable ssh askpass
  programs.ssh.askPassword = "";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";
}
