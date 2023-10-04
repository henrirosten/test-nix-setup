{
  config,
  pkgs,
  ...
}: {
  services = {
    nix-serve = {
      enable = true;
      secretKeyFile = config.sops.secrets.cache-sig-key.path;
    };
  };
  networking.firewall.allowedTCPPorts = [5000];
}
