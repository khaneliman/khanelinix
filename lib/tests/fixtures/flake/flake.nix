{
  outputs = inputs: {
    inherit (inputs) marker;
    followedMarker = inputs.nixpkgs.marker or null;
  };
}
