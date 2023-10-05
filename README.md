# Example NixOS Configurations

Example NixOS Configuration using flakes.

### Highlights
Example flakes-based NixOS configurations for host profiles '**vbox1**' and '**laptop**':
- '**vbox1**' includes the following configuration:
    - hydra: using [ghaf](https://github.com/tiiuae/ghaf) jobset as an example (currently [disabled](./modules/hydra/create-jobsets.sh) by default)
    - binary cache: with [nix-serve-ng](https://github.com/aristanetworks/nix-serve-ng) signing packages that can be verified with public key: `cache.vbox1:/hvpES9H9KQ24QyxWl6kg+AUhFu/9zsVu8+XePhnL3k=`.
    - automatic nix store garbage collection: when free disk space in `/nix/store` drops below [threshold value](./hosts/common.nix) automatically remove garbage
    - openssh server
    - pre-defined users: allow ssh access for a set of users based on ssh public keys
    - secrets: uses [sops-nix](https://github.com/Mic92/sops-nix) to manage secrets - secrets, such as hydra admin password and binary cache signing key, are stored encrypted based on host ssh key
- '**laptop**' includes the following configuration:
    - dummy configuration for reference, no services configured

## Secrets
For deployment secrets (such as binary cache signing key), the example configurations use the [sops-nix](https://github.com/Mic92/sops-nix).

The general idea is: each host have `secrets.yaml` file that contains the encrypted secrets required by that host. As an example, the `secrets.yaml` file for host vbox1 defines a secret '[`cache-sig-key`](./hosts/vbox1/secrets.yaml)' which is used by the host vbox1 in [its](./hosts/vbox1/configuration.nix) binary cache [configuration](./modules/binarycache/binary-cache.nix) to sign the packages in the cache. All secrets in `secrets.yaml` can be decrypted with the host's ssh key - sops automatically decrypts the host secrets when the system activates (i.e. on boot or whenever nixos-rebuild switch occurs) and places the decrypted secrets in the configured file paths.

The `secrets.yaml` file is created and edited with the `sops` utility. The '[`.sops.yaml`](.sops.yaml)' file tells sops what secrets get encrypted with what keys. For a detailed example, see the following section.

## Starting off in your environment
This section attempts to outline the required initial manual setup to help those who plan to apply these configurations (or something based on them) on your environment.

Clone this repository:
```bash
$ git clone https://github.com/henrirosten/test-nix-setup.git
$ cd test-nix-setup
```

Bootstrap nix shell with `flakes` and `nix-command` as well as the `sops` commands that we will be using.
```bash
# For the sake of example, we will run all the commands
# in nix-shell on the host to which you are planning to
# apply the new NixOS configuration
$ nix-shell
```

#### Add your sops key
You will need a key for your user to encrypt and decrypt sops secrets. We will use an age key converted from your ssh ed25519 key:
```bash
# In nix-shell
$ mkdir -p ~/.config/sops/age
# if you don't have ed25519, generate one with:
$ ssh-keygen -t ed25519 -a 100
# convert the ed25519 key to age key:
$ ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt
# print the age public key
$ ssh-to-age < ~/.ssh/id_ed25519.pub
age18jtr8nw8dw7qqgx0wl2547u805y7m7ay73a8xlhfxedksrujhgrsu5ftwe
```
Add the above age public key to the `.sops.yaml` with your username. You will also want to remove all the example keys from that file.

#### Add your host sops key
```bash
# In nix-shell
$ ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
age15jhcpmj00hqha52l82vecf7gzr8l3ka3sdt63dx8pzkwdteff5vqs4a6c3
```

Now, add the above age public key to the `.sops.yaml` with the host name you are planning use for the host.

At this point, your `.sops.yaml` should look something like (we'll use `myhost` and `myadmin` for the new host and user names):

```bash
keys:
  - &myadmin age18jtr8nw8dw7qqgx0wl2547u805y7m7ay73a8xlhfxedksrujhgrsu5ftwe
  - &myhost age15jhcpmj00hqha52l82vecf7gzr8l3ka3sdt63dx8pzkwdteff5vqs4a6c3
creation_rules:
  - path_regex: secrets.yaml$
    key_groups:
    - age:
      - *myadmin
      - *myhost
```

#### Add yourself as user
Copy one of the user configurations under ['users'](./users/) as template for your user, and modify the username and the ssh key to match yours:
```bash
$ cp users/tester.nix users/myadmin.nix
# Modify the username and 'myadmin' public ssh key to match
# the public key you are going to use to access the server
$ vim users/myadmin.nix
```

The end result should look something like:
```bash
$ cat users/myadmin.nix
{...}: {
  users.users = {
    myadmin = {
    # ^^^^^ Change the username
      initialPassword = "changemeonfirstlogin";
      isNormalUser = true;
      # Change the ssh public key:
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHFuB+uEjhoSdakwiKLD3TbNpbjnlXerEfZQbtRgvdSz"
      ];
      extraGroups = ["wheel" "networkmanager"];
    };
  };
}
```

#### Add your host configuration 
Copy one of the host configurations under ['hosts'](./hosts/) as template for your host:
```bash
$ cp -r hosts/vbox1 hosts/myhost
```

Copy the hardware-configuration.nix from your current NixOS system:
```bash
$ cp /etc/nixos/hardware-configuration.nix hosts/myhost/
```

You will also need to add your new host configuration to the `flake.nix` file.
```
    ...
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
      # HERE: Add your new host config: ==>
      myhost = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          nix-serve-ng.nixosModules.default
          sops-nix.nixosModules.sops
          ./hosts/myhost/configuration.nix
        ];
      };
    ...
   };
   ...
```

#### Modify your host configuration 
Modify the host 'myhost' configuration based on your needs. For this example, the only change we will make are the user configuration and the hostname. 

From the `hosts/myhost/configuration.nix` remove the user imports for 'tester' and 'hrosten', and replace with the import of user 'myadmin', so the import becomes something like:
```
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../../modules/hydra/hydra.nix
    ../../modules/openssh/openssh.nix
    ../../modules/binarycache/binary-cache.nix
    ../../users/myadmin.nix
  ];
```

Replace the hostname 'vbox1' with 'myhost' editing the value of `networking.hostname`:
```bash
$ grep -r vbox1 hosts/myhost/
hosts/myhost/configuration.nix:  networking.hostName = "vbox1";
#                                   Replace with myhost ^^^^^
```

Ensure the boot.loader configuration in `hosts/myhost/configuration.nix` is what you expect. If you are already running NixOS, check the existing configuration in `/etc/nixos/configuration.nix`:
```bash
$ grep boot.loader /etc/nixos/configuration.nix
boot.loader.grub.enable = true;
boot.loader.grub.device = "/dev/sda";
```

While editing the `hosts/myhost/configuration.nix`, you might want to remove some of the configured services, or add your own services based on what you are planning to use the server for. For instance, if you don't want to configure hydra for your host, simply remove the line that imports `../../modules/hydra/hydra.nix`.

#### Generate and encrypt your secrets
At this point, the configuration is otherwise ready, but you have not generated any secrets yet.

First, remove possible earlier secrets you might have copied from vbox1. 
(Note: you will obviously not be able to decrypt the secrets from the original vbox1 '[`secrets.yaml`](./hosts/vbox1/secrets.yaml)' since you don't have the private key that matches one of the age keys in the original '[`.sops.yaml`](.sops.yaml)' file.)
```bash
$ rm hosts/myhost/secrets.yaml
```
If you are using the vbox1 as a template configuration, you are going to need at least the following secrets:
- `hydra-admin-password`: this will specify the admin password for hydra
- `cache-sig-key`: this will specify the nix binary cache private signing key

Run the following command to generate your `cache-sig-key`:

```bash
$ nix-store --generate-binary-cache-key cache.myhost ../cache-secret ../cache-public
$ cat ../cache-secret
$ cache.myhost:JqIOEIMiGY6aXXaH4Zx6tlOXtdRbVBWB2jPl3pQM3LFBTxEcYCV46AXP9MRWZu4rcESixi2s5mfUu/Uc3tzITQ==
```
Side note: to use your binary cache, you would configure the substituters as follows:

```bash
$ cat ../cache-public
cache.myhost:g2JcrmWFk5eq5j95fTl63hn+Jqgr9ehsOpxd4TwDHyM=

# To use your binary cache, configure the substituters
# Replace with myhost IP:
substituters = http://192.168.1.101:5000
# Replace with your content from ../cache-public:
trusted-public-keys = cache.myhost:g2JcrmWFk5eq5j95fTl63hn+Jqgr9ehsOpxd4TwDHyM=
```

Now, you are ready to generate your host secrets:

```bash
# This will open the secrets.yaml in an editor:
$ sops hosts/myhost/secrets.yaml
```
The above command opens an editor, where you can edit the secrets.
Remove the example content, and replace with your secrets, so the content would look something like:

```bash
hydra-admin-password: do_not_use_this_same_password_or_cache_sig_key
cache-sig-key: cache.myhost:JqIOEIMiGY6aXXaH4Zx6tlOXtdRbVBWB2jPl3pQM3LFBTxEcYCV46AXP9MRWZu4rcESixi2s5mfUu/Uc3tzITQ==
```

When you save and exit the editor, sops will encrypt your secrets and saves them to the file you specified: `hosts/myhost/secrets.yaml`.
Notice: the example sops configuration we defined in `.sops.yaml`, both `myadmin` and `myhost` can decrypt all the secrets. For production setups, you would want to apply the principle of least privilege and only allow decryption for the hosts or users who need access to the specific secret content. See, for instance, [nix-community/infra](https://github.com/nix-community/infra/blob/master/.sops.yaml) for a more complete example.

Now, if you re-run `sops hosts/myhost/secrets.yaml`, sops will again decrypt the file allowing you to edit or add new secrets.

Finally, `git add` your changes (and consider starting off with your new configuration in your own repository).

#### Quick sanity checks

After adding your configuration, check nix formatting and fix possible issues:
```bash
$ nix fmt
```

Similarly, check that your configuration evaluates properly and fix possible issues:
```bash
$ nix flake show

├───devShells
│   └───x86_64-linux
│       └───default: development environment 'nix-shell'
├───formatter
│   └───x86_64-linux: package 'alejandra-3.0.0'
└───nixosConfigurations
    ├───laptop: NixOS configuration
    ├───myhost: NixOS configuration     # <-- HERE, you created this!
    └───vbox1: NixOS configuration
```

In the following section, replace `vbox1` with `myhost` to apply your new configuration.

## Applying NixOS configuration

Show a list of NixOS configurations provided by this flake:
```bash
$ nix flake show
```

As an example, to build the configuration for host `vbox1`, showing the changes that would be performed by activating the new generation, you would run:
```bash
$ sudo nixos-rebuild dry-activate --flake .#vbox1
```

To test the configuration for host `vbox1`, try `nixos-rebuild test` which activates the configuration, but does not add it to bootloader menu:
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

To activate the configuration for host `vbox1` and make it the default boot option, run:
```bash
$ sudo nixos-rebuild switch --flake .#vbox1
```

For more `nixos-rebuild` sub-commands; such as testing the new configuration in Qemu VM, see: https://nixos.wiki/wiki/Nixos-rebuild.

## User Environment Management
For user environment management, consider using [Nix Home Manager](https://nixos.wiki/wiki/Home_Manager).
To get started, use an existing configuration as a template such as: https://github.com/henrirosten/dotfiles or https://github.com/Misterio77/nix-starter-configs.

## Testing configurations
TODO

## Acknowledgements

- https://github.com/Misterio77/nix-starter-configs
- https://github.com/nix-community/infra
- https://samleathers.com/posts/2022-02-11-my-new-network-and-sops.html
