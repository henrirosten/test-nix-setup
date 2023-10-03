{
  lib,
  pkgs,
  config,
  ...
}: {
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
    settings.PasswordAuthentication = false;
    # Needs to be set from the importing module
    settings.HostKey = config.sops.secrets.ssh-host-ed25519-key.path;
  };
}
