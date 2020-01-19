{ stdenv, fetchgit, pkgconfig, libGL, ApplicationServices, autoconf, automake, libtool }:

stdenv.mkDerivation rec {
  pname = "glu";
  version = "9.0.1";

  src = fetchgit {
    url = "https://gitlab.freedesktop.org/mesa/glu.git";
    rev = "dd4e18eb7557a31a3c8318d6612801329877c745";
    sha256 = "12ds0l9lasabzkqfm65ihhjc0zq9w2rgz2ijkcfr3njgpzjs367n";
  };

  preConfigure = ''
    ./autogen.sh
  '';

  nativeBuildInputs = [ pkgconfig autoconf automake libtool ];
  propagatedBuildInputs = [ libGL ]
    ++ stdenv.lib.optional stdenv.isDarwin ApplicationServices;

  outputs = [ "out" "dev" ];

  meta = {
    description = "OpenGL utility library";
    homepage = https://cgit.freedesktop.org/mesa/glu/;
    license = stdenv.lib.licenses.sgi-b-20;
    platforms = stdenv.lib.platforms.unix;
    broken = stdenv.hostPlatform.isAndroid;
  };
}
