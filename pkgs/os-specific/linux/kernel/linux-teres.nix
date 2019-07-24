{ stdenv, buildPackages, fetchFromGitHub, perl, buildLinux, modDirVersionArg ? null, ... } @ args:

with stdenv.lib;

(buildLinux (args // rec {
  version = "3.10.0";
  modDirVersion = version;

  extraMeta.branch = "rel3";

  src = fetchFromGitHub {
    owner = "OLIMEX";
    repo = "DIY-LAPTOP";
    rev = "6b903740d7f395827b4b746dc384b079698c4019";
    sha256 = "0g9a87im7incg0kkxaplp1lhyxrjfixq2z6bzv172sw5adjhqz5z";
  };
  defconfig = "olimex_teres1_defconfig";
} // (args.argsOverride or {}))).overrideAttrs (old: {
  sourceRoot = "source/SOFTWARE/A64-TERES/linux-a64";
})
