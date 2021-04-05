# -*- mode: ruby -*-
# vi: set ft=ruby :

livecd = "./ubuntu-20.04.2.0-desktop-amd64.iso"
disk1 = "./.vagrant/disk1.vdi"
disk2 = "./.vagrant/disk2.vdi"

Vagrant.configure("2") do |config|

  config.vm.box = "ubuntu/focal64"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  config.vm.box_check_update = false

  config.vm.box_download_insecure = false
  config.vm.guest = "linux"
  config.vm.communicator = "ssh"
  config.ssh.username = "admin"
  config.ssh.password = "admin"
  config.ssh.insert_key = true

  # Seconds that Vagrant will wait for the machine to boot and be accessible
  # 900 because we boot from LiveCD
  config.vm.boot_timeout = 900

  # Disable default vagrant shared folder to the guest VM.
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  config.vm.provider "virtualbox" do |vb|
    vb.name = "ubuntuzfs"
    vb.check_guest_additions = false
    vb.gui = true
    vb.cpus = 1
    vb.memory = 4096

    # Attach ISO
    if File.exists?(livecd)
      vb.customize ["storageattach", :id, "--storagectl", "IDE", "--port", 0, "--device", 0, "--type", "dvddrive", "--medium", "emptydrive"]
    end

    # Replace box disks with empty ones to simulate install
    disk_size_gb = 10
    if not File.exists?(disk1)
      vb.customize ["createhd", "--filename", disk1, "--variant", "Fixed", "--size", disk_size_gb * 1024]
      vb.customize ["storageattach", :id, "--storagectl", "SCSI", "--port", 0, "--device", 0, "--type", "hdd", "--medium", disk1]
    end
    if not File.exists?(disk2)
      vb.customize ["createhd", "--filename", disk2, "--variant", "Fixed", "--size", disk_size_gb * 1024]
      vb.customize ["storageattach", :id, "--storagectl", "SCSI", "--port", 1, "--device", 0, "--type", "hdd", "--medium", disk2]
    end

    # Limit to 50% of host CPU
    vb.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]

    # Set Graphics RAM to 64MB
    vb.customize ["modifyvm", :id, "--vram", "64"]
  end

  # Setup test folder instead
  config.vm.synced_folder ".", "/home/ubuntu/ubuntu-zfs", create: true

  # Run Ansible from the Vagrant VM
  # See also https://www.vagrantup.com/docs/provisioning/ansible_local#default
  config.vm.provision "ansible_local" do |ansible|
    ansible.install = false
    ansible.playbook = "playbook.yml"
    ansible.provisioning_path = "/home/ubuntu/ubuntu-zfs"
    # ansible.tmp_path = "/tmp/vagrant-ansible"
  end
end
