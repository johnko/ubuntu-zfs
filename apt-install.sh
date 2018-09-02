#!/usr/bin/env bash
set -e
set -x

if [ -z "${UBUNTU_CODENAME}" ]; then
  echo "ERROR: missing env UBUNTU_CODENAME" >&2
  exit 1
fi

# Wait for network
while ! ping -c 1 archive.ubuntu.com; do
  sleep 1
done

# DOC-4.3
OUTFILE="/etc/apt/sources.list"
if [ -f "${OUTFILE}" ] && [ ! -f "${OUTFILE}.original" ]; then
  cp -a "${OUTFILE}" "${OUTFILE}.original"
fi
cat >"${OUTFILE}" <<EOF
deb http://archive.ubuntu.com/ubuntu ${UBUNTU_CODENAME} main universe
deb http://archive.ubuntu.com/ubuntu ${UBUNTU_CODENAME}-updates main universe
deb http://security.ubuntu.com/ubuntu ${UBUNTU_CODENAME}-security main universe
deb-src http://archive.ubuntu.com/ubuntu ${UBUNTU_CODENAME} main universe
deb-src http://archive.ubuntu.com/ubuntu ${UBUNTU_CODENAME}-updates main universe
deb-src http://security.ubuntu.com/ubuntu ${UBUNTU_CODENAME}-security main universe
EOF

# We need gnupg2 for apt-key add
if [ -z "${RSYNC_CACHE_SERVER}" ]; then
  apt-get update
fi
apt-get install --yes gnupg2

cat >/etc/apt/sources.list.d/virtualbox.list <<EOF
deb http://download.virtualbox.org/virtualbox/debian ${UBUNTU_CODENAME} contrib
EOF
#wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | apt-key add -
apt-key add - <<EOF
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1.4.12 (GNU/Linux)

mQINBFcZ9OEBEACSvycoAEIKJnyyIpZ9cZLCWa+rHjXJzPymndnPOwZr9lksZVYs
12YnsEy7Uj48rTB6mipbIuDDH9VBybJzpu3YjY7PFTkYAeW6WAPeJ8RcSGXsDvc0
fQ8c+7/2V1bpNofc9vDSdvcM/U8ULQcNeEa6DI4/wgy2sWLXpi1DYhuUOSU10I97
KHPwmpWQPsLtLHEeodeOTvnmSvLX1RRl32TPFLpLdjTpkEGS7XrOEXelqzMBQXau
VUwanUzQ2VkzKnh4WecmKFT7iekOFVHiW0355ErL2RZvEDfjMjeIOOa/lPmW7y4F
fHMU3a3sT3EzpD9ST/JGhrmaZ+r5yQD4s4hn1FheYFUtUN0dqHe9KgPDecUGgh4w
rGnm0nUQsmQLKGSFXskqt26IiERdRt1eXpR9C5yufCVZfYpSsoG/mIHAt9opXFqi
ryJqzx5pfQkOLTz9WErThHK1399jyXJwYGKLyddHFQEdy3u3ELM8Kfp7SZD/ERVq
t2oA8jsr24IOyL16cydzfSP2kAV1r30bsF/1Q4qq6ii/KfDLaI0KEliBLQuB9jrA
6XQ69VLtkNPgiWzVMclg+qW1pA8ptXqXLMxi4h5EmE5GOhsihuwkwhhBmFqGT1RJ
EGlc/uiHWQskOW3nhQ3Epd6xhCUImy8Eu83YRxS6QriH6K8z5LgRSdg9nwARAQAB
tElPcmFjbGUgQ29ycG9yYXRpb24gKFZpcnR1YWxCb3ggYXJjaGl2ZSBzaWduaW5n
IGtleSkgPGluZm9AdmlydHVhbGJveC5vcmc+iQI3BBMBCgAhBQJXGfThAhsDBQsJ
CAcDBRUKCQgLBRYDAgEAAh4BAheAAAoJEKL2g8UpgK7P49QP/39dH+lFqlD9ruCV
apBKVPmWTiwWbqmjxAV35PzG9reO7zHeZHil7vQ6UCb6FGMgZaYzcj4Sl9xVxfbH
Zk7lMgyLDuNMTTG4c6WUxQV9UH4i75E1IBm9lOJw64bpbpfEezUF/60PAFIiFBvD
34qUAoVKe49PbvuTy98er5Kw6Kea880emWxU6I1Q1ZA80+o2dFEEtQc+KCgfWFgd
O757WrqbTj6gjQjBAD5B4z5SwBYMg1/TiAYF0oa+a32LNhQIza/5H3Y+ufMfO3tY
B/z1jLj8ee5lhjrv0jWvvfUUeIlq5pNoOmtNYFS+TdkO0rsqEC6AD0JRTKsRHOBu
eSj7SLt8gmqy7eEzRCMlYIvoQEzt0/JuTQNJjHCuxH1scV13Q3bK6SmxqlY46tf5
Ljni9Z4lLJ7MB1BF2MkHuwQ7OcaEgUQBZSudzPkpRnY0AktiQYYP4Q1uDp+vfvFp
GTkY1pqz3z2XD66fLz0ea5WIBBb3X/uq9zdHu8BTwDCiZlWLaDR5eQoZWWe+u+5J
NUx1wcBpC1Hr2AnmuXBCRq+bzd8iaB8qxWfpCAFZBksSIW2aGhigSeYdx1jpjOob
xog4qbuo5w1IUh8YLHwQ6uM12CqwC1nZadLxG0Fj4KoYbvp0T5ryBM3XD+TVGjKB
m/QHLqabxZBbuJT0Cw2dRtW/ty5ZuQINBFcZ9OEBEADEY+YveerQjzzy5nA1FjQG
XSaPcjy4JlloRxrUyqlATA0AIuK7cwc7PVrpstV8mR9qb38fdeIoY1z1dD3wnQzJ
lbDfZhS5nGMzk9AANd6eJ2KcWI3qLeB//4fr2pPS0piOG4qyW4IhY4KeuCwusE6d
IyDBg2XEdpG1IesSDaqNsvLZjPFEBNiCIkqrC7XSmoPNwHkKGj5LeD1wAE914cn2
a04IlbXiT46V9jjJFnNem/Co0u+2e2J3oReNmHvbb62OC57rqeBxqBplXg9tvJk/
w0A3bXxUrfz83tY6vDYoFdwJDudaJJWQjvqpYnySXMJYT6KoE4Xgl5fNcbNIVUpU
k74BcWD9PZVadSMN7FWZzMfVsbTMmUA22tuDKD6hrF6ysCelex4YO44kSH7dhXu5
ANtZ2BFfRZvdjTQoblOI8C9cy/iX74vvG8OZarFG+u/kon3+xcAgY5KceUVbostO
0n3V8iK0gMQWH8sR8vXH+oV4GqHUEQURax2XM2Tt7Ra5XGcQaYDIkNPKSVVVtTk5
3OU/bNoBofAbwd4eOZOf9ag5ZVIIaoubMOEiveGYde4AEVE7krSNcYh/C48iCVKr
eOyS26AVA15dAvnKTAqxJqICUSQ9zjGfTp1obhXCkMAy0m+AxNVEfSzFznQLHtWK
zEGr+zCsvj1R8/qlMpHBXQARAQABiQIfBBgBCgAJBQJXGfThAhsMAAoJEKL2g8Up
gK7PKpQP+wY9zLgnJeqrvNowmd70afd8SVge9BvhLh60cdG+piM5ZuEV5ZmfTFoX
XPHzOo2dgt6VYTE9JO72Jv7MyzJj3zw3G/IcJQ6VuQwzfKkFTD+IeOiXX2I2lX1y
nFv24rs1MTZ4Px1NJai7fdyXLiCl3ToYBmLafFpfbsVEwJ8U9bCDrHE4KTVc9IXO
KQ5/86JaIPN+JJLHJoO2EBQC08Cw3oxTDFVcWZ/IWvEFeqyqRSyoFMoDkjLYsqHS
we1kEoMmM2qN20otpKYq8R+bIEI5KKuJvAts/1xKE2cHeRvwl5kcFw/S3QQjKj+b
LCVTSRZ6EgcDDmsAPKt7o01wmu+P3IjDoiyMZJQZpZIA2pYDxruY+OLXpcmw78Gq
lTXb4Q9Vf47sAE8HmHfkh/wrdDeEiY9TQErzCBCufYbQj7sgttGoxAt12N+pUepM
MBceAsnqkF6aEa4n8dUTdS2/nijnyUZ2rDVzikmKc0JlrZEKaw8orDzg8fXzfHIc
pTrXCmFLX5BzNQ4ezAlw0NZG/qvhSBCuAkFiibfQUal8KLYwswvGJFghuQHsVTkf
gF8Op7Br7loTNnp3yiI0jo2D+7DBFqtiSHCq1fIgktmKQoVLCfd3wlBJ/o9cguT4
Y3B83Y34PxuSIq2kokIGo8JhqfqPB/ohtTLHg/o9RhP8xmfvALRD
=Rv7/
-----END PGP PUBLIC KEY BLOCK-----
EOF
#wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | apt-key add -
apt-key add - <<EOF
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1.4.9 (GNU/Linux)

mQGiBEvy0LARBACPBH1AUv6krDseyvbL63CWS9fw43iReZ+NmgmDp4/sPsYHLduQ
rxKSqiK7fgFFE+fas/7DCaZXIQW6hnqeD3CgnX0w1+gYiyqEuPY1LQH9okBR5o92
/s2FLm7oUN4RNGv6vWoNSH1ZiRHknL5D0pKSGTKU+pG6cBYWJytAuJZHfwCguS55
aPZuXfhjaWsXG8TF6GH0K8ED/RY3KbirJ7rueK/7KL7ziwqn4CdhQSLOhbZ/R2E0
bknJQDo+vWJciRRRpTe+AG59ctgDF7lEXpjvCms0atyKtE8hObNaMJ5p48l/sgFL
LEujqiq4tByAn2hDOf0s7YrfruIY+HHkBSI9XbwH9nPlsQq8WNsTWTzPrw+ZlQ7v
AEuuA/9cJ/4qYUOq1pg3i/GqH+2dbRHOFH6idXr5YrdB3cYW8jORagOcwdQHeV/0
CaTZVMyMhTVjtIiUt+UR/96CHKxedg0giHwD61GidpUVBUYSaDhjOKE3jwf6/jo5
714e4+ZfL3y1Q2N4HzfK/gEkvPZby/o8WX2N7vUcxfztQ8yq6bRJT3JhY2xlIENv
cnBvcmF0aW9uIChWaXJ0dWFsQm94IGFyY2hpdmUgc2lnbmluZyBrZXkpIDxpbmZv
QHZpcnR1YWxib3gub3JnPohgBBMRAgAgBQJL8tCwAhsDBgsJCAcDAgQVAggDBBYC
AwECHgECF4AACgkQVEIqS5irUTmlvwCeIjsPZ0I9HhLmlS9dLjk397Y5rncAn3kB
XUPRIWb83FMxRwqS85rTCZyouQINBEvy0LAQCAC/pkqDW6H99qQdyW8zvQL5xj6C
UcvlTpL5VkaIRDVwRNbiFoWsVMv2jdhmlJEoh5N+aXYcAzLv0HaiZBSDmTO6fqMM
uPRHyIioQQUFNW4hRI7sdMkYvd2oZcxnzRCLdzG+s42EmzxE4F29eT/FA7o/QBj2
nDbomVqM9jCXKB5/jSJ0W3Uf7I8b7go0AawJT9vVARRMFjz4A7h6QfjeSO9sPHSC
1Dx5Fmd3u4y08W+o6w2kxXRYT9wfMFuGl4MWVJ+f6KPyRhqRCEaa/mz7lXhQdfeG
qW8psDHKmoNnpPEq5Rl4aDIJOppwYJhnDELv+k8JJ6R1JM9hJUWTG8zv9sLzAAMF
CAC6pagGYEK8Dh+3SV6dXjBLNghmj5qnx6GoCXwCDTEFXeWUnszZrqM7PTKLyrfK
ZjOhluydpQSGY7TqDBJJ6emLyNNJV92IQ21eN/h9i0wB97pu8jwvi7RjD0vSkDHh
OpSr9vJm9EeESU1Z+mEKOjz2AONjRLplbBNt9kbXmSWpIP8XMFkU+1KTuNbfi+h4
muOJWKkAGcT7bMUlqbZQjZ2O0RtwDjThxHvw8NhRkxPDYHVxE4uRRobhPquq4NsC
QkMc7LlRilXZCS5mrabHw5+edullNWaQtGuKGlQXGfM4kEhGt7b/XIiyhI5bsh60
o8Mz0KuFpClp9B7c78+QBzTbiEkEGBECAAkFAkvy0LACGwwACgkQVEIqS5irUTnq
qACgtXuTbe2b72sgKdc6gGRKPhLDoEMAmgLwGVN3a4CqewQL+03bqfcKczNH
=19g1
-----END PGP PUBLIC KEY BLOCK-----
EOF
if [ -z "${RSYNC_CACHE_SERVER}" ]; then
  apt-get update
fi

# DOC-8.1
apt-get dist-upgrade --yes

# DOC-8.2a
PACKAGES="
ubuntu-minimal
linux-image-generic
debootstrap gdisk zfs-initramfs mdadm
grub-pc
network-manager
openssh-server
openntpd
ntpdate
net-tools
software-properties-common
rsync
git
curl
wget
vim
ubuntu-standard
nullmailer
docker.io
iftop
pv
tmux
build-essential
ucarp
w3m
zsync
fail2ban
shellcheck
python-pygments
vagrant
linux-headers-generic
virtualbox-5.2
"
#mailutils

for i in ${PACKAGES}; do
  case "${i}" in
  linux-image-generic)
    apt-get install --yes --no-install-recommends "${i}"
    ;;
  *)
    apt-get install --yes "${i}"
    ;;
  esac
done

# build wifi driver for next kernel
./rtl8812au.sh $(ls -d /usr/src/linux-headers*generic | tail -n 1 | sed 's;/usr/src/linux-headers-;;')

# DOC-8.2b
if [ "${INSTALL_TYPE}" = "desktop" ] && [ ! -f /etc/system-setup ]; then
  if [ -z "${RSYNC_CACHE_SERVER}" ]; then
    apt-get update
  fi
  PACKAGES="
dbus
xubuntu-desktop
xsel
gimp
inkscape
audacity
filezilla
chromium-browser
"
  #network-manager-openconnect-gnome
  #spotify-client
  #hipchat4
  #libxcb-xtest0
  for i in ${PACKAGES}; do
    case "${i}" in
    *)
      apt-get install --yes "${i}"
      ;;
    esac
  done

  if dmesg | grep -q -i "macbookpro10,1"; then
    # Enable wifi
    # source https://askubuntu.com/questions/470153/no-wireless-when-install-14-04-on-macbook-pro
    if lspci -nn | grep -q -i "802.11"; then
      apt-add-repository multiverse || true
      apt-get update
      apt-get install --yes firmware-b43-installer
    fi
  fi

fi
