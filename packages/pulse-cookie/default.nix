{
  python3,
  fetchPypi,
  lib,
  ...
}:
python3.pkgs.buildPythonApplication rec {
  pname = "pulse-cookie";
  version = "1.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "sha256-ZURSXfChq2k8ktKO6nc6AuVaAMS3eOcFkiKahpq4ebU=";
  };

  propagatedBuildInputs = [
    python3.pkgs.pyqt6
    python3.pkgs.pyqt6-webengine
    python3.pkgs.setuptools
    python3.pkgs.setuptools_scm
  ];

  preBuild = ''
    cat > setup.py << EOF
    from setuptools import setup

    # with open('requirements.txt') as f:
    #     install_requires = f.read().splitlines()

    setup(
      name='pulse-cookie',
      packages=['pulse_cookie'],
      package_dir={"": 'src'},
      version='1.0',
      author='Raj Magesh Gauthaman',
      description='wrapper around openconnect allowing user to log in through a webkit window for mfa',
      install_requires=[
        'PyQt6-WebEngine',
      ],
      entry_points={
        'console_scripts': ['get-pulse-cookie=pulse_cookie._cli:main']
      },
    )
    EOF
  '';

  meta = with lib; {
    homepage = "https://pypi.org/project/pulse-cookie/";
    description = "wrapper around openconnect allowing user to log in through a webkit window for mfa";
    mainProgram = "get-pulse-cookie";
    license = licenses.gpl3;
  };
}
