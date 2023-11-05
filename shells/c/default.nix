{ mkShell
, pkgs
, ...
}:
let
  llvm = pkgs.llvmPackages_latest;

  # simple script which replaces the functionality of make
  # it works with <math.h> and includes debugging symbols by default
  # it will be updated as per needs

  # arguments: outfile
  # basic usage example: mk main [flags]
  mymake = pkgs.writeShellScriptBin "mk" ''
    if [ -f "$1.c" ]; then
      i="$1.c"
      c=$CC
    else
      i="$1.cpp"
      c=$CXX
    fi
    o=$1
    shift
    $c -ggdb $i -o $o -lm -Wall $@
  '';
in
mkShell {
  buildInputs = with pkgs; [
    # builder
    gnumake
    cmake
    bear
    meson
    ninja

    # debugger
    llvm.lldb
    gdb

    # fix headers not found
    clang-tools

    # LSP and compiler
    llvm.libstdcxxClang

    # other tools
    cppcheck
    llvm.libllvm
    valgrind
    mymake

    # stdlib for cpp
    llvm.libcxx

    # libs
    glm
    SDL2
    SDL2_gfx
  ];

  shellHook = ''

    echo 🔨 Cpp DevShell


  '';

}
