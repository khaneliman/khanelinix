{
  token,
  inputs,
  callerValue,
  ...
}:
{
  imports = [ ./nested.nix ];
  boundValues = [
    token
    inputs.marker
    callerValue
  ];
}
