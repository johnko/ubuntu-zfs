# Ubuntu 18.04 Root on ZFS

Based on https://openzfs.github.io/openzfs-docs/Getting%20Started/Ubuntu/Ubuntu%2018.04%20Root%20on%20ZFS.html

# Warning: This will erase your hard drive

## Get Ubuntu Desktop LiveCD

https://ubuntu.com/tutorials/try-ubuntu-before-you-install#1-getting-started

See links on that page for `Create a bootable USB stick on Windows, Ubuntu or macOS`

## After booting to the Ubuntu Desktop LiveCD

Open the gnome-terminal or terminal app.

`sudo -i` to become the `root` user.

Now as `root` user:

```
apt-get update ; apt-get install --yes git ; git clone --depth=1 https://github.com/johnko/ubuntu-zfs ; cd ubuntu-zfs

# edit env.sh
vi env.sh

./install.sh
```
