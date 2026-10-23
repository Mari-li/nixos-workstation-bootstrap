# Vagrant for the GoGetSSL dev environments (legacy-development-environment-*).
# On Linux the nixpkgs vagrant ships with the vagrant-libvirt plugin, so with
# tools/kvm.nix those Vagrantfiles need a `config.vm.provider "libvirt"` block.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    vagrant
  ];

  # Default vagrant-libvirt synced folders use NFS.
  services.nfs.server.enable = true;
  networking.firewall.extraCommands = ''
    iptables -I INPUT -i virbr+ -p tcp --dport 2049 -j ACCEPT
    iptables -I INPUT -i virbr+ -p udp --dport 2049 -j ACCEPT
  '';
}
