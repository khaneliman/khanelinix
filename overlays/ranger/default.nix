_: _final: prev: {
  # Use ranger PR, fixes freeze after opening image in kitty: https://github.com/ranger/ranger/pull/2856
  ranger = prev.ranger.overrideAttrs (old: {
    version = "1.9.3-unstable";

    src = prev.fetchFromGitHub {
      owner = "ranger";
      repo = "ranger";
      rev = "38bb8901004b75a407ffee4b9e176bc0a436cb15";
      hash = "sha256-NpsrABk95xHNvhlRjKFh326IW83mYj1cmK3aE9JQSRo=";
    };

    propagatedBuildInputs = old.propagatedBuildInputs ++ (with prev.python3Packages; [ astroid pylint ]);
  });
}
