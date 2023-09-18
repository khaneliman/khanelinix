_: (_final: prev: {
  dooit = prev.dooit.overrideAttrs (old: {
    pname = "dooit";
    version = "2.0.1";

    src = prev.fetchFromGitHub {
      owner = "kraanzu";
      repo = "dooit";
      rev = "v2.0.1";
      hash = "sha256-iQAGD6zrBBd4fJONaB7to1OJpAJUO0zeA1xhVQZBkMc=";
    };

    propagatedBuildInputs = old.propagatedBuildInputs ++
      [ prev.python3.pkgs.python-dateutil ];
  });
})
