_: (_self: super: {
  vulkan-utility-libraries = super.vulkan-utility-libraries.overrideAttrs (_old: {
    pname = "vulkan-utility-libraries";
    version = "1.3.268.0";

    src = super.fetchFromGitHub {
      owner = "KhronosGroup";
      repo = "Vulkan-Utility-Libraries";
      rev = "vulkan-sdk-1.3.268.0";
      hash = "sha256-O1agpzZpXiQZFYx1jPosIhxJovZtfZSLBNFj1LVB1VI=";
    };
  });
})
