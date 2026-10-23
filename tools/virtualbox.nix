# VirtualBox, as a fallback for VMs that cannot move to KVM.
#
# VirtualBox cannot use AMD-V while KVM holds it, and since kernel 6.12 KVM
# grabs it as soon as kvm-amd loads (hardware-configuration.nix always lists
# kvm-amd). enable_virt_at_load=0 makes KVM take it only while a KVM guest
# runs, so the two can be installed side by side but not run at once.
# Add "vboxusers" to the user's extraGroups when importing this.
{ ... }:

{
  virtualisation.virtualbox.host.enable = true;
  boot.kernelParams = [ "kvm.enable_virt_at_load=0" ];
}
