{ ... }:

{
  users.users = {
    tester = {
      initialPassword = "changemeonfirstlogin";
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIFbxhIZjGU6JuMBMMyeaYNXSltPCjYzGZ2WSOpegPuQ"
      ];
      extraGroups = ["wheel" "networkmanager"];
    };
  };
}