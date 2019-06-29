# To build, use:
# nix-build nixos -I nixos-config=nixos/modules/installer/cd-dvd/sd-image-teres.nix -A config.system.build.sdImage
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
  nixpkgs.config.packageOverrides = pkgs: {
    linux_sunxi = pkgs.linux_sunxi.override {
        extraConfig = ''
          SUNXI_CODEC y
          SUNXI_I2S y
          SUNXI_SNDCODEC y
          8723CS y
          R8152 y
          HALL y
        '';
    };
  };
  boot.kernelPackages = pkgs.linuxPackages_sunxi;
  boot.kernelParams = ["console=tty0" "console=ttyS0,115200n8" "no_console_suspend"];

  sdImage = {
    populateFirmwareCommands = let
      configTxt = pkgs.writeText "config.txt" ''
        debug=on
      '';
      in ''
        cp ${configTxt} firmware/config.txt
      '';
    populateRootCommands = ''
      mkdir -p ./files/boot
      ${extlinux-conf-builder} -t 3 -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };
}
