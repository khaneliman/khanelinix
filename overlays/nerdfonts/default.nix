{ channels, ... }: (_self: super: {
  inherit (channels.nixpkgs-master) nerdfonts;
})
