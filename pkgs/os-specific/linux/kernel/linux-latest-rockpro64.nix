{ stdenv, buildPackages, fetchFromGitLab, perl, buildLinux, modDirVersionArg ? null, ... } @ args:

with stdenv.lib;

buildLinux (args // rec {
  version = "5.4.0-rc6";
  modDirVersion = version;

  src = fetchFromGitLab {
    domain = "gitlab.manjaro.org";
    owner = "tsys";
    repo = "linux-pinebook-pro";
    rev = "85e1be0d55202031452e1dbc2b383a79d97a6605";
    sha256 = "09m8rgzfk384yfm09swmza15laxj5469q37v4y54fcb1j0axlc4v";
  };

  extraConfig = ''                                                                                             
    CRYPTO_AEGIS128_SIMD n
  '';
} // (args.argsOverride or {}))
