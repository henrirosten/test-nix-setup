# This is your system's configuration file.
# Use this to configure your system environment
# (it replaces /etc/nixos/configuration.nix)

{ inputs, lib, config, pkgs, ... }: 

{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../../modules/hydra/hydra.nix
  ];

  virtualisation.virtualbox.guest.enable = true;

  # Bootloader
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  # Define hostname
  networking.hostName = "vbox1";

  # Systemd service to start VBoxClient-all 
  systemd.services.vbox-client-start = {
    description = "Service to start VBoxClient-all";
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = true;
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [ config.boot.kernelPackages.virtualboxGuestAdditions ];
    script = ''
      set -x
      VBoxClient-all
    '';
  };
}
