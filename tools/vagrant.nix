# Vagrant for the GoGetSSL dev environments (legacy-development-environment-*).
# On Linux the nixpkgs vagrant ships with the vagrant-libvirt plugin, so with
# tools/kvm.nix those Vagrantfiles need a `config.vm.provider "libvirt"` block
# and are started with `vagrant up --provider=libvirt`.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    vagrant
  ];

  # vagrant-libvirt synced folders use NFS (v4, TCP 2049 only).
  services.nfs.server.enable = true;

  # Vagrant appends its exports to /etc/exports on `vagrant up`. NixOS links
  # that file read-only into the store, so make it a real file instead.
  # nixos-rebuild resets it to empty; the next `vagrant up` adds them again.
  environment.etc.exports.mode = "0644";

  # Every libvirt network (virbr0 default, virbr1+ for the vagrant-libvirt
  # management and private networks): DHCP/DNS from libvirt's dnsmasq and
  # NFS from the guests.
  networking.firewall.trustedInterfaces = [ "virbr+" ];
}
