# To build, use:
# nix-build nixos -I nixos-config=nixos/modules/installer/cd-dvd/sd-image-rockpro64.nix -A config.system.build.sdImage
{ config, lib, pkgs, ... }:


let
  extlinux-conf-builder =
    import ../../system/boot/loader/generic-extlinux-compatible/extlinux-conf-builder.nix {
      pkgs = pkgs.buildPackages;
    };
in
{
  imports = [
    ../../profiles/base.nix
    ../../profiles/installation-device.nix
    ./sd-image.nix
  ];

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  boot.consoleLogLevel = lib.mkDefault 7;
  boot.kernelPackages = pkgs.linuxPackages_rockpro64_latest;
  boot.kernelParams = [ "console=uart8250,mmio32,0xff1a0000" ];

  sdImage = {
    populateFirmwareCommands = let
      configTxt = pkgs.writeText "config.txt" ''
        debug=on
      '';
      in ''
#        echo "dd if=${pkgs.ubootRockPro64}/idbloader.img of=$img bs=512 seek=64 oflag=sync"
#        dd if=${pkgs.ubootRockPro64}/idbloader.img of=$img bs=512 seek=64 oflag=sync
        cp ${configTxt} firmware/config.txt
      '';
    populateRootCommands = ''
      mkdir -p ./files/boot
      ${extlinux-conf-builder} -t 3 -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };
}
