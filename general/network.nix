# Enable NetworkManager for GUI setups

# `nmtui` can be used to manage network connections

# Include this file in /etc/nixos/configuration.nix imports section
# and run `nixos-rebuild switch --upgrade-all` to sync system state
{ config, pkgs, ... }:

let
  # strongSwan 6 builds without IKEv1 by default, but L2TP/IPsec is IKEv1
  # only: charon logs "IKE version 1 not supported" and the VPN fails.
  strongswan = pkgs.strongswan.overrideAttrs (old: {
    configureFlags = old.configureFlags ++ [ "--enable-ikev1" ];
  });
  # nm-l2tp has the strongswan path compiled in, so point it at that build.
  networkmanager-l2tp = pkgs.networkmanager-l2tp.override { inherit strongswan; };
in
{

  networking.firewall.enable = true;
  networking.networkmanager.enable = true;
  networking.networkmanager.plugins = [
        networkmanager-l2tp
    ];

  services.dbus.packages = [
    networkmanager-l2tp
  ];

  # The NetworkManager module points /etc/ipsec.secrets at
  # ipsec.d/ipsec.nm-l2tp.secrets but never creates the directory, so every
  # L2TP/IPsec connection fails with "Could not write
  # /etc/ipsec.d/ipsec.nm-l2tp.secrets". nm-l2tp writes the PSK there.
  systemd.tmpfiles.rules = [ "d /etc/ipsec.d 0700 root root -" ];

  # nm-l2tp starts strongSwan's charon, which aborts ("integrity test of
  # libstrongswan failed", exit 64) when /etc/strongswan.conf is missing.
  # An empty file means built-in defaults.
  environment.etc."strongswan.conf".text = "";

  environment.systemPackages = [
    networkmanager-l2tp
    strongswan
  ] ++ (with pkgs; [
    ppp
    xl2tpd
  ]);

  environment.etc.hosts.enable = false;
}
