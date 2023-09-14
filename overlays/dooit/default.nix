_: (_final: prev: {
  dooit = prev.dooit.overrideAttrs (old: {
    pname = "dooit";
    version = "2.0.0";
    format = "pyproject";

    src = prev.fetchFromGitHub {
      owner = "kraanzu";
      repo = "dooit";
      rev = "v2.0.0";
      hash = "sha256-Ipj3ltuewbMIUYRffxxPcJgIPxP5dJAkHpo14ZZKq+k=";
    };

    propagatedBuildInputs = old.propagatedBuildInputs ++
      [ prev.python3.pkgs.parsedatetime ];
  });
})
