# This is your system's configuration file.
# Use this to configure your system environment
# (it replaces /etc/nixos/configuration.nix)

{ inputs, lib, config, pkgs, ... }: 

{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
  ];

  virtualisation.virtualbox.guest.enable = true;

  # Bootloader
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  # Define hostname
  networking.hostName = "vbox1";
}
