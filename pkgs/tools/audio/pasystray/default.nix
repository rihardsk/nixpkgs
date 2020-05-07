{ stdenv, fetchFromGitHub, pkgconfig, autoreconfHook, wrapGAppsHook
, gnome3, avahi, gtk3, libappindicator-gtk3, libnotify, libpulseaudio
, xlibsWrapper, gsettings-desktop-schemas
}:

stdenv.mkDerivation rec {
  pname = "pasystray";
  version = "0.7.1";

  src = fetchFromGitHub {
    owner = "christophgysin";
    repo = "pasystray";
    rev = "${pname}-${version}";
    sha256 = "0xx1bm9kimgq11a359ikabdndqg5q54pn1d1dyyjnrj0s41168fk";
  };

  patches = [
    # https://github.com/christophgysin/pasystray/issues/90#issuecomment-306190701
    ./fix-wayland.patch
  ];

  nativeBuildInputs = [ pkgconfig autoreconfHook wrapGAppsHook ];
  buildInputs = [
    gnome3.adwaita-icon-theme
    avahi gtk3 libappindicator-gtk3 libnotify libpulseaudio xlibsWrapper
    gsettings-desktop-schemas
  ];

  meta = with stdenv.lib; {
    description = "PulseAudio system tray";
    homepage = "https://github.com/christophgysin/pasystray";
    license = licenses.lgpl21Plus;
    maintainers = with maintainers; [ exlevan kamilchm ];
    platforms = platforms.linux;
  };
}
