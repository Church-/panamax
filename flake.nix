{
  description = "Panamax crates.io mirroring service";

  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; };

  outputs = { self, nixpkgs }: {
    nixosModules."panamax" = { config, lib, pkgs, ... }:
      with lib;
      let cfg = config.services.panamax;
      in {
        options = {
          services.panamax = {
            enable = lib.mkEnableOption "panamax";
            path = mkOption {
              type = types.str;
              default = "world";
            };
            port = mkOption {
              type = types.int;
              default = 8080;
            };
          };
        };

        config = lib.mkIf cfg.enable {
          systemd.services.panamax = {
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            script = ''
              ${pkgs.panamax}/bin/panamax serve -p ${
                toString cfg.port
              } ${cfg.path}
            '';
            serviceConfig = {
              Type = "simple";
              ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
              Restart = "on-failure";
              StateDirectory = "panamax";
              WorkingDirectory = "/var/lib/panamax/";
            };
          };
          systemd.services.panamax-sync = {
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            script = ''
              ${pkgs.panamax}/bin/panamax sync ${cfg.path}
            '';
            serviceConfig = {
              Type = "simple";
              ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
              StateDirectory = "panamax";
              WorkingDirectory = "/var/lib/panamax/";
            };
          };
          systemd.timers.panamax-sync = {
            wantedBy = [ "timers.target" ];
            partOf = [ "panamax-sync.service" ];
            timerConfig = {
              OnBootSec = "15min";
              OnUnitActiveSec = "1d";
              Unit = "panamax-sync.service";
            };
          };
        };
      };
  };
}
