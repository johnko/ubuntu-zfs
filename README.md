Based on https://github.com/zfsonlinux/zfs/wiki/Ubuntu-16.04-Root-on-ZFS

## ON UBUNTU-DESKTOP LIVECD

as root:

```
apt-get update ; apt-get install --yes git ; git clone https://github.com/johnko/ubuntu-zfs ; cd ubuntu-zfs
# edit env.sh
vi env.sh
./install.sh
```

Then on first login:

```
_firstlogin.sh
```
