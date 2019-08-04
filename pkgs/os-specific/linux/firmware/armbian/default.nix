{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "armbian-firmware";
  version = "0.0";

  src = fetchFromGitHub {
    owner = "armbian";
    repo = "firmware";
    rev = "HEAD";
    sha256 = "0knqjm2vpfx26wjqbl9v727p5n3v99aw6cf8a6i5fwp07gmrzlij";
  };

  installPhase = ''
    mkdir -p $out/lib/firmware
    cp -a * $out/lib/firmware/
  '';

  meta = with stdenv.lib; {
    description = "Firmware from Armbian";
    homepage = https://github.com/armbian/firmware;
    license = licenses.unfreeRedistributableFirmware;
    platforms = [ "aarch64-linux" ];
  };
}
