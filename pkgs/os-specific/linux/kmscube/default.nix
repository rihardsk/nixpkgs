{ stdenv, fetchgit, autoreconfHook, libdrm, libX11, libGL, mesa, pkgconfig }:

stdenv.mkDerivation {
  name = "kmscube-2018-06-17";

  src = fetchgit {
    url = git://anongit.freedesktop.org/mesa/kmscube;
    rev = "f632b23a528ed6b4e1fddd774db005c30ab65568";
    sha256 = "0rr58h8g1nj94ng13hdd6nn44155xg48xafyi0v843lvh09k88vh";
  };

  nativeBuildInputs = [ autoreconfHook pkgconfig ];
  buildInputs = [ libdrm libX11 libGL mesa ];

  meta = with stdenv.lib; {
    description = "Example OpenGL app using KMS/GBM";
    homepage = https://gitlab.freedesktop.org/mesa/kmscube;
    license = licenses.mit;
    maintainers = with maintainers; [ dezgeg ];
    platforms = platforms.linux;
  };
}
