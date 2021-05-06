{ lib
, buildPythonPackage
, fetchPypi
, setuptools-scm
}:

buildPythonPackage rec {
  pname = "adafruit-platformdetect";
  version = "3.8.0";

  src = fetchPypi {
    pname = "Adafruit-PlatformDetect";
    inherit version;
    sha256 = "sha256-AjUpxdY/5IoWMBtufP3OVnMpUwpxgpCNWoydH1w+t+Y=";
  };

  nativeBuildInputs = [ setuptools-scm ];

  # Project has not published tests yet
  doCheck = false;
  pythonImportsCheck = [ "adafruit_platformdetect" ];

  meta = with lib; {
    description = "Platform detection for use by Adafruit libraries";
    homepage = "https://github.com/adafruit/Adafruit_Python_PlatformDetect";
    license = with licenses; [ mit ];
    maintainers = with maintainers; [ fab ];
  };
}
