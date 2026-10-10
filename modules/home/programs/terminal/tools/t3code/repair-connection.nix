{
  lib,
  writeShellApplication,
  python3,
  openssh,
  electron_44,
  libsecret,
}:
writeShellApplication {
  name = "t3-repair";
  runtimeInputs = [
    python3
    openssh
  ];
  text = ''
    exec ${lib.getExe python3} ${./repair-connection.py} \
      ${lib.getExe electron_44} ${libsecret}/lib ${./repair-catalog.cjs} "$@"
  '';
}
