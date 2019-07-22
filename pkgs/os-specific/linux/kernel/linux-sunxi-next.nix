{ stdenv, buildPackages, fetchFromGitHub, perl, buildLinux, modDirVersionArg ? null, ... } @ args:

with stdenv.lib;

buildLinux (args // rec {
  version = "5.2.0";
  modDirVersion = version;

  extraMeta.branch = "sunxi64-5.2";

  src = fetchFromGitHub {
    owner = "anarsoul";
    repo = "linux-2.6";
    rev = "3c0ea3bedc07d93945ddc50e8bac7bdae30df08a";
    sha256 = "12fdn42r1qxi20pdgjz42w1l0cklmm9azfizmwq48q52ifib46zb";
  };
} // (args.argsOverride or {}))
