# Example NixOS Configurations

Example NixOS Configuration using flakes.

## Usage

Clone this repository:
```bash
$ git clone https://github.com/henrirosten/test-nix-setup.git
$ cd test-nix-setup
```

### NixOS

Bootstrap nix shell with `flakes` and `nix-command`:
```bash
$ nix-shell
```

Show a list of NixOS configurations provided by this flake:
```bash
$ nix flake show
```

As an example, to build the configuration for host '`vbox1`', showing the changes that would be performed by activating the new generation, you would run:
```bash
$ sudo nixos-rebuild dry-activate --flake .#vbox1
```

To test the configuration for host '`vbox1`', try `nixos-rebuild test` which activates the configuration, but does not add it to bootloader menu:
```bash
$ sudo nixos-rebuild test --flake .#vbox1

# Reboot to rollback to the previous configuration.

# Alternatively, to rollback without reboot, try:
# List previous generations
sudo nix-env --list-generations -p /nix/var/nix/profiles/system
# As an example, to wwitch to generation id 123
sudo nix-env --switch-generation 123 -p /nix/var/nix/profiles/system
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

To activate the configuration for host '`vbox1`' and make it the default boot option, run:
```bash
$ sudo nixos-rebuild switch --flake .#vbox1
```

For more `nixos-rebuild` sub-commands; such as testing the new configuration in Qemu VM, see: https://nixos.wiki/wiki/Nixos-rebuild.

### User Environment Management
For user environment management, consider using [Nix Home Manager](https://nixos.wiki/wiki/Home_Manager).
To get started, use an existing configuration as a template such as: https://github.com/henrirosten/dotfiles or https://github.com/Misterio77/nix-starter-configs.

## Acknowledgements

- https://github.com/Misterio77/nix-starter-configs
- https://github.com/nix-community/infra
- https://samleathers.com/posts/2022-02-11-my-new-network-and-sops.html
