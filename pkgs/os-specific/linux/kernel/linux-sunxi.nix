{ stdenv, buildPackages, fetchFromGitHub, perl, buildLinux, modDirVersionArg ? null, ... } @ args:

with stdenv.lib;

buildLinux (args // rec {
  version = "4.19.56";
  modDirVersion = "4.19.56";

  extraMeta.branch = "orange-pi-4.19";

  src = fetchFromGitHub {
    owner = "megous";
    repo = "linux";
    rev = "orange-pi-4.19";
    sha256 = "1xfirljlharr9p6d6v66bzwmg4vgixdlqq009p9gi5qm8l5bra03";
  };
} // (args.argsOverride or {}))
