{...}: {
  users.users = {
    hrosten = {
      initialPassword = "changemeonfirstlogin";
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHFuB+uEjhoSdakwiKLD3TbNpbjnlXerEfZQbtRgvdSz"
      ];
      extraGroups = ["wheel" "networkmanager"];
    };
  };
}
