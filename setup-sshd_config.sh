#!/usr/bin/env bash
set -e
set -x

OUTFILE="/etc/ssh/sshd_config"
if [ -f "${OUTFILE}" ] && [ ! -f "${OUTFILE}.original" ]; then
  cp -a "${OUTFILE}" "${OUTFILE}.original"
fi
sed -i 's;^HostKey /etc/ssh/ssh_host_dsa_key;#HostKey /etc/ssh/ssh_host_dsa_key;' "${OUTFILE}"
sed -i 's;^LogLevel;#LogLevel;' "${OUTFILE}"
sed -i 's;^Subsystem;#Subsystem;' "${OUTFILE}"
sed -i 's;^PermitRootLogin;#PermitRootLogin;' "${OUTFILE}"
sed -i 's;^UsePrivilegeSeparation;#UsePrivilegeSeparation;' "${OUTFILE}"
sed -i 's;^UsePAM;#UsePAM;' "${OUTFILE}"
sed -i 's;^UseDNS;#UseDNS;' "${OUTFILE}"
sed -i 's;^ClientAliveInterval;#ClientAliveInterval;' "${OUTFILE}"
sed -i 's;^KexAlgorithms;#KexAlgorithms;' "${OUTFILE}"
sed -i 's;^Ciphers;#Ciphers;' "${OUTFILE}"
sed -i 's;^MACs;#MACs;' "${OUTFILE}"
cat >>"${OUTFILE}" <<EOF

# DON'T CHANGE BELOW
# Don't use PAM for auth, don't allow LDAP users, only allow real users or those defined in this config
UsePAM no
# LogLevel VERBOSE logs user's key fingerprint on login. Needed to have a clear audit track of which key was using to log in.
LogLevel VERBOSE
# Log sftp level file access (read/write/etc.) that would not be easily logged otherwise.
Subsystem sftp /usr/lib/openssh/sftp-server -f AUTHPRIV -l INFO
# Root login is not allowed for auditing reasons. This is because it's difficult to track which process belongs to which root user:
# On Linux, user sessions are tracking using a kernel-side session id, however, this session id is not recorded by OpenSSH.
# Additionally, only tools such as systemd and auditd record the process session id.
# On other OSes, the user session id is not necessarily recorded at all kernel-side.
# Using regular users in combination with /bin/su or /usr/bin/sudo ensure a clear audit track.
PermitRootLogin No
# Use kernel sandbox mechanisms where possible in unprivilegied processes
# Systrace on OpenBSD, Seccomp on Linux, seatbelt on MacOSX/Darwin, rlimit elsewhere.
UsePrivilegeSeparation sandbox
# If this option is set to “no” (the default) then only addresses and not host names may be used in ~/.ssh/known_hosts from and sshd_config Match Host directives.
UseDNS no
# ets a timeout interval in seconds after which if no data has been received from the client, sshd(8) will send a message through the encrypted channel to request a response from the client.
ClientAliveInterval 5
KexAlgorithms curve25519-sha256@libssh.org,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com
# DON'T CHANGE ABOVE

# CAN CHANGE BELOW

# Uncomment to enable X11 Forwarding apps (clients can use ssh -Y IP virtualbox
#X11Forwarding yes

# Uncomment 2 lines below to disable password based logins - only public key based logins are allowed.
#PasswordAuthentication no
#AuthenticationMethods publickey
EOF

sshd -t -f "${OUTFILE}"

