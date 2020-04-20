let
  commonConfig = ./common/letsencrypt/common.nix;

  dnsScript = {writeScript, dnsAddress, bash, curl}: writeScript "dns-hook.sh" ''
    #!${bash}/bin/bash
    set -euo pipefail
    echo '[INFO]' "[$2]" 'dns-hook.sh' $*
    if [ "$1" = "present" ]; then
      ${curl}/bin/curl --data '{"host": "'"$2"'", "value": "'"$3"'"}' http://${dnsAddress}:8055/set-txt
    else
      ${curl}/bin/curl --data '{"host": "'"$2"'"}' http://${dnsAddress}:8055/clear-txt
    fi
  '';

in import ./make-test-python.nix {
  name = "acme";

  nodes = rec {
    letsencrypt = { nodes, lib, ... }: {
      imports = [ ./common/letsencrypt ];
      networking.nameservers = lib.mkForce [
        nodes.dnsserver.config.networking.primaryIPAddress
      ];
    };

    dnsserver = { nodes, pkgs, ... }: {
      networking.firewall.allowedTCPPorts = [ 8055 53 ];
      networking.firewall.allowedUDPPorts = [ 53 ];
      systemd.services.pebble-challtestsrv = {
        enable = true;
        description = "Pebble ACME challenge test server";
        wantedBy = [ "network.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.pebble}/bin/pebble-challtestsrv -dns01 ':53' -defaultIPv6 '' -defaultIPv4 '${nodes.webserver.config.networking.primaryIPAddress}'";
          # Required to bind on privileged ports.
          User = "root";
          Group = "root";
        };
      };
    };

    acmeStandalone = { nodes, lib, config, pkgs, ... }: {
      imports = [ commonConfig ];
      networking.nameservers = lib.mkForce [
        nodes.dnsserver.config.networking.primaryIPAddress
      ];
      networking.firewall.allowedTCPPorts = [ 80 ];
      security.acme = {
        server = "https://acme-v02.api.letsencrypt.org/dir";
        certs."standalone.com" = {
            webroot = "/var/lib/acme/acme-challenges";
        };
      };
      systemd.targets."acme-finished-standalone.com" = {
        after = [ "acme-standalone.com.service" ];
        wantedBy = [ "acme-standalone.com.service" ];
      };
      services.nginx.enable = true;
      services.nginx.virtualHosts."standalone.com" = {
        locations."/.well-known/acme-challenge".root = "/var/lib/acme/acme-challenges";
      };
    };

    webserver = { nodes, config, pkgs, lib, ... }: {
      imports = [ commonConfig ];
      networking.firewall.allowedTCPPorts = [ 80 443 ];
      networking.nameservers = lib.mkForce [
        nodes.dnsserver.config.networking.primaryIPAddress
      ];

      # A target remains active. Use this to probe the fact that
      # a service fired eventhough it is not RemainAfterExit
      systemd.targets."acme-finished-a.example.com" = {
        after = [ "acme-a.example.com.service" ];
        wantedBy = [ "acme-a.example.com.service" ];
      };

      services.nginx.enable = true;

      services.nginx.virtualHosts."a.example.com" = {
        enableACME = true;
        forceSSL = true;
        locations."/".root = pkgs.runCommand "docroot" {} ''
          mkdir -p "$out"
          echo hello world > "$out/index.html"
        '';
      };

      security.acme.server = "https://acme-v02.api.letsencrypt.org/dir";

      specialisation.second-cert.configuration = {pkgs, ...}: {
        systemd.targets."acme-finished-b.example.com" = {
          after = [ "acme-b.example.com.service" ];
          wantedBy = [ "acme-b.example.com.service" ];
        };
        services.nginx.virtualHosts."b.example.com" = {
          enableACME = true;
          forceSSL = true;
          locations."/".root = pkgs.runCommand "docroot" {} ''
            mkdir -p "$out"
            echo hello world > "$out/index.html"
          '';
        };
      };

      specialisation.dns-01.configuration = {pkgs, config, nodes, lib, ...}: {
        security.acme.certs."example.com" = {
          domain = "*.example.com";
          dnsProvider = "exec";
          dnsPropagationCheck = false;
          credentialsFile = with pkgs; writeText "wildcard.env" ''
            EXEC_PATH=${dnsScript { inherit writeScript bash curl; dnsAddress = nodes.dnsserver.config.networking.primaryIPAddress; }}
          '';
          user = config.services.nginx.user;
          group = config.services.nginx.group;
        };
        systemd.targets."acme-finished-example.com" = {
          after = [ "acme-example.com.service" ];
          wantedBy = [ "acme-example.com.service" ];
        };
        systemd.services."acme-example.com" = {
          before = [ "nginx.service" ];
          wantedBy = [ "nginx.service" ];
        };
        services.nginx.virtualHosts."c.example.com" = {
          forceSSL = true;
          sslCertificate = config.security.acme.certs."example.com".directory + "/cert.pem";
          sslTrustedCertificate = config.security.acme.certs."example.com".directory + "/full.pem";
          sslCertificateKey = config.security.acme.certs."example.com".directory + "/key.pem";
          locations."/".root = pkgs.runCommand "docroot" {} ''
            mkdir -p "$out"
            echo hello world > "$out/index.html"
          '';
        };
      };

      # When nginx depends on a service that is slow to start up, requesting used to fail
      # certificates fail.  Reproducer for https://github.com/NixOS/nixpkgs/issues/81842
      specialisation.slow-startup.configuration = { pkgs, config, nodes, lib, ...}: {
        systemd.services.my-slow-service = {
          wantedBy = [ "multi-user.target" "nginx.service" ];
          before = [ "nginx.service" ];
          preStart = "sleep 5";
          script = "${pkgs.python3}/bin/python -m http.server";
        };
        systemd.targets."acme-finished-d.example.com" = {
          after = [ "acme-d.example.com.service" ];
          wantedBy = [ "acme-d.example.com.service" ];
        };
        services.nginx.virtualHosts."d.example.com" = {
          forceSSL = true;
          enableACME = true;
          locations."/".proxyPass = "http://localhost:8000";
        };
      };
    };

    client = {nodes, lib, ...}: {
      imports = [ commonConfig ];
      networking.nameservers = lib.mkForce [
        nodes.dnsserver.config.networking.primaryIPAddress
      ];
    };
  };

  testScript = {nodes, ...}:
    let
      newServerSystem = nodes.webserver.config.system.build.toplevel;
      switchToNewServer = "${newServerSystem}/bin/switch-to-configuration test";
    in
    # Note, wait_for_unit does not work for oneshot services that do not have RemainAfterExit=true,
    # this is because a oneshot goes from inactive => activating => inactive, and never
    # reaches the active state. To work around this, we create some mock target units which
    # get pulled in by the oneshot units. The target units linger after activation, and hence we
    # can use them to probe that a oneshot fired. It is a bit ugly, but it is the best we can do
    ''
      client.start()
      dnsserver.start()

      letsencrypt.wait_for_unit("default.target")
      dnsserver.wait_for_unit("pebble-challtestsrv.service")
      client.succeed(
          'curl --data \'{"host": "acme-v02.api.letsencrypt.org", "addresses": ["${nodes.letsencrypt.config.networking.primaryIPAddress}"]}\' http://${nodes.dnsserver.config.networking.primaryIPAddress}:8055/add-a'
      )
      client.succeed(
          'curl --data \'{"host": "standalone.com", "addresses": ["${nodes.acmeStandalone.config.networking.primaryIPAddress}"]}\' http://${nodes.dnsserver.config.networking.primaryIPAddress}:8055/add-a'
      )

      letsencrypt.start()
      acmeStandalone.start()

      letsencrypt.wait_for_unit("default.target")
      letsencrypt.wait_for_unit("pebble.service")

      with subtest("can request certificate with HTTPS-01 challenge"):
          acmeStandalone.wait_for_unit("default.target")
          acmeStandalone.succeed("systemctl start acme-standalone.com.service")
          acmeStandalone.wait_for_unit("acme-finished-standalone.com.target")

      client.wait_for_unit("default.target")

      client.succeed("curl https://acme-v02.api.letsencrypt.org:15000/roots/0 > /tmp/ca.crt")
      client.succeed(
          "curl https://acme-v02.api.letsencrypt.org:15000/intermediate-keys/0 >> /tmp/ca.crt"
      )

      with subtest("Can request certificate for nginx service"):
          webserver.wait_for_unit("acme-finished-a.example.com.target")
          client.succeed(
              "curl --cacert /tmp/ca.crt https://a.example.com/ | grep -qF 'hello world'"
          )

      with subtest("Can add another certificate for nginx service"):
          webserver.succeed(
              "/run/current-system/specialisation/second-cert/bin/switch-to-configuration test"
          )
          webserver.wait_for_unit("acme-finished-b.example.com.target")
          client.succeed(
              "curl --cacert /tmp/ca.crt https://b.example.com/ | grep -qF 'hello world'"
          )

      with subtest("Can request wildcard certificates using DNS-01 challenge"):
          webserver.succeed(
              "${switchToNewServer}"
          )
          webserver.succeed(
              "/run/current-system/specialisation/dns-01/bin/switch-to-configuration test"
          )
          webserver.wait_for_unit("acme-finished-example.com.target")
          client.succeed(
              "curl --cacert /tmp/ca.crt https://c.example.com/ | grep -qF 'hello world'"
          )

      with subtest("Can request certificate of nginx when startup is delayed"):
          webserver.succeed(
              "${switchToNewServer}"
          )
          webserver.succeed(
              "/run/current-system/specialisation/slow-startup/bin/switch-to-configuration test"
          )
          webserver.wait_for_unit("acme-finished-d.example.com.target")
          client.succeed("curl --cacert /tmp/ca.crt https://d.example.com/")
    '';
}
