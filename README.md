# Example NixOS Configurations

Example NixOS Configuration using flakes.

### Highlights
Example flakes-based NixOS configurations for profiles '**vbox1**' and '**laptop**':
- '**vbox1**' includes the following configuration:
    - hydra: using [ghaf](https://github.com/tiiuae/ghaf) jobset as an example
    - binary cache: with [nix-serve-ng](https://github.com/aristanetworks/nix-serve-ng) signing packages with public key: `cache.vbox1:/hvpES9H9KQ24QyxWl6kg+AUhFu/9zsVu8+XePhnL3k=`.
    - automatic nix store garbage collection: when free disk space in `/nix/store` drops below threshold value, automatically remove garbage
    - openssh server: with pre-defined host ssh key
    - pre-defined users: allow ssh access for a set of users based on ssh public keys
    - secrets: uses [sops-nix](https://github.com/Mic92/sops-nix) to manage secrets - secrets, such as hydra admin password and binary cache signing key, are stored encrypted based on host ssh key
- '**laptop**' includes the following coniguration:
    - dummy configuration for reference, no services configured

## Secrets
For deployment secrets (such as binary cache signing key), the example configurations use the [sops-nix](https://github.com/Mic92/sops-nix).

The general idea is: each host have `secrets.yaml` file that contains the ecrypted secrets required by that host. As an example, the `secrets.yaml` file for host vbox1 defines a secret '[`cache-sig-key`](./hosts/vbox1/secrets.yaml)' which is used by the host vbox1 in [its](./hosts/vbox1/configuration.nix) binary cache [configuration](./modules/binarycache/binary-cache.nix) to sign the packages in the cache. All secrets in `secrets.yaml` can be decrypted with the host's ssh key - sops automatically decrypts the host secrets when the system activates (i.e. on boot or whenever nixos-rebuild switch occurs) and places the decrypted secrets in the configured file paths.

The `secrets.yaml` file is created and edited with the `sops` utility. The '[`.sops.yaml`](.sops.yaml)' file tells sops what secrets get encrypted with what keys. For a detail example, see the following section.

## Initial setup (adding new hosts)
TODO

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
# As an example, to witch to generation id 123
sudo nix-env --switch-generation 123 -p /nix/var/nix/profiles/system
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

To activate the configuration for host '`vbox1`' and make it the default boot option, run:
```bash
$ sudo nixos-rebuild switch --flake .#vbox1
```

For more `nixos-rebuild` sub-commands; such as testing the new configuration in Qemu VM, see: https://nixos.wiki/wiki/Nixos-rebuild.

## User Environment Management
For user environment management, consider using [Nix Home Manager](https://nixos.wiki/wiki/Home_Manager).
To get started, use an existing configuration as a template such as: https://github.com/henrirosten/dotfiles or https://github.com/Misterio77/nix-starter-configs.

## Acknowledgements

- https://github.com/Misterio77/nix-starter-configs
- https://github.com/nix-community/infra
- https://samleathers.com/posts/2022-02-11-my-new-network-and-sops.html
