# This is your system's configuration file.
# Use this to configure your system environment
# (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  sops.defaultSopsFile = ./secrets.yaml;
  sops.secrets.hydra-admin-password.owner = "hydra";
  sops.secrets.ssh-host-ed25519-key.owner = "root";
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../../modules/hydra/hydra.nix
    ../../modules/openssh/openssh.nix
  ];

  virtualisation.virtualbox.guest.enable = true;

  # Bootloader
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  # Define hostname
  networking.hostName = "vbox1";
}
