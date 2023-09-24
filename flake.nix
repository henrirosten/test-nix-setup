{
  description = "NixOS configuration for testing";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
  };

  outputs = { self, nixpkgs, ... } @ inputs: 

  let
    inherit (self) outputs;
  in {
    # NixOS configuration entrypoint
    nixosConfigurations = {
      # Available through 'nixos-rebuild switch --flake .#vbox1'
      # Configuration for host 'vbox1'
      vbox1 = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [./hosts/vbox1/configuration.nix];
      };
      # Available through 'nixos-rebuild switch --flake .#laptop'
      # Configuration for host 'laptop'
      laptop = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [./hosts/laptop/configuration.nix];
      };
    };
  };
}
