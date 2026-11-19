localExtraSocket: remote:
let
  remoteSocketDirectory =
    if remote.system == "darwin" then
      "/Users/${remote.username}/.gnupg"
    else
      "/run/user/${toString (remote.uid or 1000)}/gnupg";
in
# ForwardAgent already carries SSH authentication. Only GPG needs a separate socket.
if localExtraSocket != null && (remote.gpgAgent or false) then
  [ "${builtins.toJSON "${remoteSocketDirectory}/S.gpg-agent"} ${builtins.toJSON localExtraSocket}" ]
else
  [ ]
