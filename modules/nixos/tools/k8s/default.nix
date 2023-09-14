{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.tools.k8s;
in
{
  options.khanelinix.tools.k8s = {
    enable =
      mkBoolOpt false "Whether or not to enable common Kubernetes utilities.";
  };

  config = mkIf cfg.enable {
    programs.zsh.shellAliases = {
      k = "kubecolor";
      kubectl = "kubecolor";
      kc = "kubectx";
      kn = "kubens";
      ks = "kubeseal";
    };

    environment.systemPackages = with pkgs; [
      kubectl
      kubectx
      kubeseal
      kubecolor
      kubernetes-helm
      helmfile
    ];
  };
}
