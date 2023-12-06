_: (_self: super: {
  # Use swaylock-effects PR, fixes freeze after opening image in kitty: https://github.com/swaylock-effects/ranger/pull/2856
  swaylock-effects = super.swaylock-effects.overrideAttrs
    (_old: {
      version = "1.7.0.0";

      src = super.fetchFromGitHub {
        owner = "jirutka";
        repo = "swaylock-effects";
        rev = "v1.7.0.0";
        sha256 = "sha256-cuFM+cbUmGfI1EZu7zOsQUj4rA4Uc4nUXcvIfttf9zE=";
      };
    });
})
