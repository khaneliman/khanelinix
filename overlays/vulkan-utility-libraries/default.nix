_: (_self: super: {
  vulkan-utility-libraries = super.vulkan-utility-libraries.overrideAttrs (_old: {
    pname = "vulkan-utility-libraries";
    version = "1.3.268.0";

    src = super.fetchFromGitHub {
      owner = "KhronosGroup";
      repo = "Vulkan-Utility-Libraries";
      rev = "v1.3.268.0";
      hash = "sha256-l6PiHCre/JQg8PSs1k/0Zzfwwv55AqVdZtBbjeKLS6E=";
    };
  });
})
