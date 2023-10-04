{
  description = "NixOS configuration for testing";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    # Secrets with sops-nix
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };
    # Binary cache with nix-serve-ng
    nix-serve-ng = {
      url = github:aristanetworks/nix-serve-ng;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    self,
    nixpkgs,
    sops-nix,
    nix-serve-ng,
    ...
  } @ inputs: let
    inherit (self) outputs;
    # Supported systems for your flake packages, shell, etc.
    systems = [
      "x86_64-linux"
    ];
    forEachSystem = f: nixpkgs.lib.genAttrs systems (system: f pkgsFor.${system});
    pkgsFor = nixpkgs.lib.genAttrs systems (system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      });
  in {
    # Formatter for your nix files, available through 'nix fmt'
    formatter = forEachSystem (pkgs: pkgs.alejandra);
    # Development shell, available through 'nix develop'
    devShells = forEachSystem (pkgs: import ./shell.nix {inherit pkgs;});
    # NixOS configuration entrypoint
    nixosConfigurations = {
      # Available through 'nixos-rebuild switch --flake .#vbox1'
      # Configuration for host 'vbox1'
      vbox1 = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          nix-serve-ng.nixosModules.default
          sops-nix.nixosModules.sops
          ./hosts/vbox1/configuration.nix
        ];
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
