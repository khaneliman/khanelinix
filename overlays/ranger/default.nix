_: (_final: prev: {
  # Use ranger PR, fixes freeze after opening image in kitty: https://github.com/ranger/ranger/pull/2856
  ranger = prev.ranger.overrideAttrs (old: {
    version = "136416c7e2ecc27315fe2354ecadfe09202df7dd";
    src = prev.fetchFromGitHub {
      owner = "ranger";
      repo = "ranger";
      rev = "136416c7e2ecc27315fe2354ecadfe09202df7dd";
      hash = "sha256-nW4KlatugmPRPXl+XvV0/mo+DE5o8FLRrsJuiKbFGyY=";
    };
    propagatedBuildInputs = old.propagatedBuildInputs ++ (with prev.python3Packages; [ astroid pylint ]);
  });
})
