# Remote "is it really dead?" access for the p15v freeze investigation
# (hosts/p15v/FREEZE-PLAN.md). Every freeze so far left pstore empty and the
# NMI/TCO watchdogs silent, which only proves the capture path saw nothing,
# not whether the kernel is still alive behind a dead display. The next
# freeze is therefore judged from another machine:
#
#   ping 192.168.88.83                 # p15v on the office LAN (DHCP, verify)
#   ssh eg@192.168.88.83  -> dmesg -T | tail -50; cat /proc/loadavg
#   on the frozen keyboard: Caps Lock LED, then Alt+SysRq+b (reboot)
#
# ping/ssh answer  -> GPU/display hang, the kernel is fine: collect dmesg
#                     (amdgpu ring timeout, NVRM Xid); `echo c >
#                     /proc/sysrq-trigger` forces a panic -> pstore dump.
# no answer at all -> platform-level hang confirmed (SoC/firmware), kernel
#                     debugging cannot see it; continue with FREEZE-PLAN item 4.
#
# sshd is key-only (the two keys from ~/.ssh on this box; copy the matching
# private key to the laptop/phone you will test from), root login off.
# Remove this import when the investigation is over.
{ ... }:

{
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      AllowUsers = [ "eg" ];
    };
  };

  users.users.eg.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDwQaydFToQFVw0q0JnO+xMKQV1educ1zad43/LeCUNHGOByqwwBDKVr2KJ9bnuBMGffK1gAMa95ZpESG+PYk44jL6gnmDdQo7AfM4oHcYMt5/ldTWJNSYRyYf7RaezXysijFfg1RhLUtd+yntr63vymSGWlM5s8B0rbj0SMLAXYF7ZSduyBiZANYUwTqztG7u8gWT9ZuRlGQmGpFO+7OUiP9gUxoQdSHH0ngE8nGPMLPqWfK758+Y83NKm93ol/AlWrW+CQquUVtUS63kOJzIjKfE4SaXxqWTCnRj+1sxE5HUIzbdJaG6HTVLK85iBxGinaOxF20kELjEdsR69jp861LdLu2y7DAP0ckvUmcDB9HijWK+Wvhhb5dnGakUh3C3YYeHQT2C71be9Uzl2M3MyixLOh+3SxhPhDrjpMDXNrxeZW9ikzEcceBZW5LEYNeDkuh+DYrmxysv9ilLXKl6xFuV7dtf0+qz2IF7FYFCSC1R17d2OHgqMMQglljfw00U= sk@TP-P15V"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7402c8lmWuxYrtMLz4Y+AgCaHQlQAiIb2Rrf9USj6f+oTlNN9UYf1mldRbUKQ5dRKd7NP7NFSHWXjIk5tmm4AeGx74MoOTemSo7NVovhCZGXeV0Mx0UDY7kprhr30i7yf/flg0h0NJ04C/Waa0eG7h17b2v7253VJQPYPc9vLs7UvtlUW99Yr5JMX40nQSWGj0VLotsIYo1kvy4+wmJyQcT6MFRu+oHkDv0ZP6qyafsjoRM4PDwZttWR6VcBRNpE4bvpH6USPP1bLzUXC+g8hQaJNF3mHnyu6U5Tx6/oyITuD3UCnAUPsQjnGe9Izgooj1oET0+aoQrtKWAwGQQlFIvus5LunphE3TCceCFEcqTXCJPTMYTGVmKfmV82RP3I9c9xbYpQ8JBmhauUWkcB12XEF1BhFLcWpJZ6inKjNEjJNHgvUpbsXhMups/nwWMTITZ2ipFmWBeVDz4WMLtVbnk/Y4bHUuJUw1YuJ0qx5ylsfizSyFFRzDT5NLiw7jfk= sk@tp"
  ];

  # All SysRq functions (default 16 = sync only): Alt+SysRq+b reboots a box
  # whose kernel still runs, Alt+SysRq+c forces the panic -> pstore path, and
  # `echo <key> > /proc/sysrq-trigger` does the same over ssh.
  boot.kernel.sysctl."kernel.sysrq" = 1;
}
