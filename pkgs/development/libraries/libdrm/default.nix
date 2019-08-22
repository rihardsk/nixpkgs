{ stdenv, fetchgit, pkgconfig, meson, ninja, libpthreadstubs, libpciaccess, valgrind-light }:

stdenv.mkDerivation rec {
  pname = "libdrm";
  version = "2.4.99";

  src = fetchgit {
    url = "https://gitlab.freedesktop.org/mesa/drm.git";
    rev = "14922551aa33e7592d2421cc89cf20a860a65310";
    sha256 = "1aly2bbmp64f9yaj5pnj1nw25vgb0rzpw1n3kif6ngxxsq1x5r19";
  };

  outputs = [ "out" "dev" "bin" ];

  nativeBuildInputs = [ pkgconfig meson ninja ];
  buildInputs = [ libpthreadstubs libpciaccess valgrind-light ];

  postPatch = ''
    for a in */*-symbol-check ; do
      patchShebangs $a
    done
  '';

  mesonFlags =
    [ "-Dinstall-test-programs=true" ]
    ++ stdenv.lib.optionals (stdenv.isAarch32 || stdenv.isAarch64)
      [ "-Dtegra=true" "-Detnaviv=true" ]
    ++ stdenv.lib.optional (stdenv.hostPlatform != stdenv.buildPlatform) "-Dintel=false"
    ;

  enableParallelBuilding = true;

  meta = {
    homepage = https://dri.freedesktop.org/libdrm/;
    description = "Library for accessing the kernel's Direct Rendering Manager";
    license = "bsd";
    platforms = stdenv.lib.platforms.unix;
  };
}
