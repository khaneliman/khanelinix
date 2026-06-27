{
  callPackage,
  mkShell,
  clang-tools,
  gnumake,
  cmake,
  bear,
  libcxx,
  cppcheck,
  llvmPackages,
  gdb,
  glm,
  SDL2,
  SDL2_gfx,
}:
let
  mainPkg = callPackage ./default.nix { };
in
mkShell {
  inputsFrom = [ mainPkg ];

  packages = [
    clang-tools # fix headers not found
    gnumake # builder
    cmake # another builder
    bear # bear.
    libcxx # stdlib for cpp
    cppcheck # static analysis
    llvmPackages.lldb # debugger
    gdb # another debugger
    llvmPackages.libstdcxxClang # LSP and compiler
    llvmPackages.libcxx # stdlib for C++
    # libs
    glm
    SDL2
    SDL2_gfx
  ];
}
