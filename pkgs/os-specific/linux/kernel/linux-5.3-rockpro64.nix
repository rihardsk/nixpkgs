{ stdenv, buildPackages, fetchFromGitHub, perl, buildLinux, modDirVersionArg ? null, ... } @ args:

with stdenv.lib;

buildLinux (args // rec {
  version = "5.3.0-rc4";
  modDirVersion = version;

  #extraMeta.branch = "orange-pi-4.19";

  src = fetchFromGitHub {
    owner = "ayufan-rock64";
    repo = "linux-mainline-kernel";
    rev = "5.3.0-rc4-1118-ayufan";
    sha256 = "198vrqp10wcwxs12jqcy4adxjqpy5xkrr4il0qnfxwi4y5fwja2z";
  };
} // (args.argsOverride or {}))
