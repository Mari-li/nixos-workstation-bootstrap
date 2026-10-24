# Syncthing: keeps ~/Passwords (the KeePassXC database) in sync with the
# Fedora laptop, directly between the two devices (no cloud storage).
# Web UI: http://127.0.0.1:8384
#
# Devices and folders are declared here; changes made in the web UI are
# overwritten on the next nixos-rebuild.
{ ... }:

{
  services.syncthing = {
    enable = true;
    user = "marija";
    group = "users";
    dataDir = "/home/marija";
    configDir = "/home/marija/.config/syncthing";
    openDefaultPorts = true; # 22000/tcp+udp, 21027/udp (LAN discovery)

    overrideDevices = true;
    overrideFolders = true;

    settings = {
      devices = {
        fedora.id = "X3FMLD5-Y66WT6A-OMCKYP2-YXZCQFR-Z3LI7IB-4SGHUMS-MMF4MHS-NSN7PQ7";
      };

      folders = {
        passwords = {
          label = "Passwords";
          path = "/home/marija/Passwords";
          devices = [ "fedora" ];
          # Keep the last 10 versions of each file in .stversions
          versioning = {
            type = "simple";
            params.keep = "10";
          };
        };
      };

      options.urAccepted = -1; # no usage reporting
    };
  };
}
