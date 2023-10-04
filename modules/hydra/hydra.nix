{
  lib,
  pkgs,
  config,
  ...
}: let
  localMachine = pkgs.writeTextFile {
    name = "local";
    text = ''
      localhost x86_64-linux - 8 2 kvm,benchmark,big-parallel,nixos-test - -
    '';
  };
  createJobsetsScript = pkgs.stdenv.mkDerivation {
    name = "create-jobsets";
    unpackPhase = ":";
    buildInputs = [pkgs.makeWrapper];
    installPhase = "install -m755 -D ${./create-jobsets.sh} $out/bin/create-jobsets";
    postFixup = ''
      wrapProgram "$out/bin/create-jobsets" \
        --prefix PATH ":" ${lib.makeBinPath [pkgs.curl]}
    '';
  };
in {
  services.hydra = {
    enable = true;
    port = 3000;
    hydraURL = "http://localhost:3000";
    notificationSender = "hydra@localhost";
    useSubstitutes = true;

    buildMachinesFiles = [
      "/etc/nix/machines"
      "${localMachine}"
    ];

    extraConfig = ''
      max_output_size = ${builtins.toString (32 * 1024 * 1024 * 1024)};
    '';
  };

  networking.firewall.allowedTCPPorts = [
    config.services.hydra.port
  ];

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_14;
    identMap = ''
      hydra-users hydra hydra
      hydra-users hydra-queue-runner hydra
      hydra-users hydra-www hydra
      hydra-users root postgres
      hydra-users postgres postgres
    '';
  };

  # delete build logs older than 30 days
  systemd.services.hydra-delete-old-logs = {
    startAt = "Sun 05:45";
    serviceConfig.ExecStart = "${pkgs.findutils}/bin/find /var/lib/hydra/build-logs -type f -mtime +30 -delete";
  };

  # hydra setup service
  systemd.services.hydra-manual-setup = {
    description = "Hydra Manual Setup";
    serviceConfig.Type = "oneshot";
    serviceConfig.RemainAfterExit = true;
    wantedBy = ["multi-user.target"];
    requires = ["hydra-init.service"];
    after = ["hydra-init.service"];
    environment = builtins.removeAttrs (config.systemd.services.hydra-init.environment) ["PATH"];
    path = with pkgs; [config.services.hydra.package netcat];
    script = ''
      if [ -e ~hydra/.setup-is-complete ]; then
        exit 0
      fi

      # create signing keys
      /run/current-system/sw/bin/install -d -m 551 /etc/nix/hydra
      /run/current-system/sw/bin/nix-store --generate-binary-cache-key hydra /etc/nix/hydra/secret /etc/nix/hydra/public
      /run/current-system/sw/bin/chown -R hydra:hydra /etc/nix/hydra
      /run/current-system/sw/bin/chmod 440 /etc/nix/hydra/secret
      /run/current-system/sw/bin/chmod 444 /etc/nix/hydra/public

      # create cache
      /run/current-system/sw/bin/install -d -m 755 /var/lib/hydra/cache
      /run/current-system/sw/bin/chown -R hydra-queue-runner:hydra /var/lib/hydra/cache

      # create admin user
      export HYDRA_ADMIN_PASSWORD=$(cat ${config.sops.secrets.hydra-admin-password.path})
      ${config.services.hydra.package}/bin/hydra-create-user admin --password "$HYDRA_ADMIN_PASSWORD" --role admin

      # wait for hydra service
      while ! nc -z localhost ${toString config.services.hydra.port}; do
        sleep 1
      done

      # create hydra jobsets
      ${createJobsetsScript}/bin/create-jobsets

      # done
      touch ~hydra/.setup-is-complete
    '';
  };

  nix.settings.trusted-users = ["hydra" "hydra-evaluator" "hydra-queue-runner"];
  nix.extraOptions = ''
    keep-going = true
  '';
}
