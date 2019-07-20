{ stdenv, buildPackages, fetchFromGitHub, perl, buildLinux, modDirVersionArg ? null, ... } @ args:

with stdenv.lib;

buildLinux (args // rec {
  version = "4.19.56";
  modDirVersion = "4.19.56";

  extraMeta.branch = "sunxi-next";

  src = fetchFromGitHub {
    owner = "linux-sunxi";
    repo = "linux-sunxi";
    rev = "HEAD";
    sha256 = "1xfirljlharr9p6d6v66bzwmg4vgixdlqq009p9gi5qm8l5bra03";
  };
} // (args.argsOverride or {}))
