_: {
  programs.nixvim.filetype = {
    extension = {
      "avsc" = "json";
      "rasi" = "scss";
      "ignore" = "gitignore";
    };

    pattern = {
      ".*/hypr/.*%.conf" = "hyprlang";
      "flake.lock" = "json";
    };
  };
}
