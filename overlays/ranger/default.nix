_: (_self: super: {
  # Use ranger PR, fixes freeze after opening image in kitty: https://github.com/ranger/ranger/pull/2856
  ranger = super.ranger.overrideAttrs (old: {
    version = "1.9.3";
    src = super.fetchFromGitHub {
      owner = "Ethsan";
      repo = "ranger";
      rev = "71a06f28551611d192d3e644d95ad04023e10801";
      sha256 = "sha256-Yjdn1oE5VtJMGnmQ2VC764UXKm1PrkIPXXQ8MzQ8u1U=";
    };
    propagatedBuildInputs = old.propagatedBuildInputs ++ (with super.python3Packages; [ astroid pylint ]);
  });
})
