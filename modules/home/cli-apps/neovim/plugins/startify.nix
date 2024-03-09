_: {
  programs.nixvim.plugins.startify = {
    enable = true;

    bookmarks = [
      "~/khanelinix/flake.nix"
    ];

    customHeader = [
      "   ██╗  ██╗██╗  ██╗ █████╗ ███╗   ██╗███████╗██╗     ██╗███╗   ██╗██╗██╗  ██╗"
      "   ██║ ██╔╝██║  ██║██╔══██╗████╗  ██║██╔════╝██║     ██║████╗  ██║██║╚██╗██╔╝"
      "   █████╔╝ ███████║███████║██╔██╗ ██║█████╗  ██║     ██║██╔██╗ ██║██║ ╚███╔╝"
      "   ██╔═██╗ ██╔══██║██╔══██║██║╚██╗██║██╔══╝  ██║     ██║██║╚██╗██║██║ ██╔██╗"
      "   ██║  ██╗██║  ██║██║  ██║██║ ╚████║███████╗███████╗██║██║ ╚████║██║██╔╝ ██╗"
      "   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝╚═╝╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝"
    ];

    # When opening a file or bookmark, change to its directory.
    changeToDir = true;

    # When opening a file or bookmark, change to the root directory of the VCS
    changeToVcsRoot = true;

    relativePath = true;

    # By default, the fortune header uses ASCII characters, because they work for everyone.
    # If you set this option to 1 and your 'encoding' is "utf-8", Unicode box-drawing characters will
    # be used instead.
    useUnicode = true;
  };
}
