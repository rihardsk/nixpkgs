{ stdenv, buildPackages, fetchFromGitHub, perl, buildLinux, modDirVersionArg ? null, ... } @ args:

with stdenv.lib;

buildLinux (args // rec {
  version = "4.4.189";
  modDirVersion = version;

  #extraMeta.branch = "orange-pi-4.19";

  src = fetchFromGitHub {
    owner = "ayufan-rock64";
    repo = "linux-kernel";
    rev = "4.4.189-1226-rockchip-ayufan";
    sha256 = "0k6rvvrblwf29q0dlcfy5cybhx0rigr805qw1p65clfx607hd0a5";
  };
  defconfig = "rk3399pro_npu_defconfig";
  extraConfig = ''
    SND_SOC_CX20810 n
  '';
} // (args.argsOverride or {}))
