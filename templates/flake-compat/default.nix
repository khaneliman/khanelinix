(import (fetchTarball "https://github.com/edolstra/flake-compat/archive/master.tar.gz") {
  src = fetchGit ./.;
}).defaultNix
