# Centreon Vagrant

This Vagrant configuration set will provide you with a ready-made environment for you to try Centreon version 19.10.
The scripts contained here will install Centreon on an available CentOS 7 image and will prepare it all to preconfigure Centreon,
making it ready for use with the access settings.

Just get on (`vagrant up`) and use it in the web interface.

[![asciicast](https://asciinema.org/a/264694.svg)](https://asciinema.org/a/264694)

### What will you need

- Vagrant
- VirtualBox or KVM/Qemu/Libvirt

#### Vagrant

  https://www.vagrantup.com/intro/index.html

#### Virtualbox

  https://www.virtualbox.org/

#### KVM/Qemu - Libvirt

  - https://www.qemu.org/
  - https://help.ubuntu.com/community/Installation/QemuEmulator
  - https://github.com/vagrant-libvirt/vagrant-libvirt

### Usage

Pull this repository:
```
git pull https://github.com/centreon-lab/vagrant
cd vagrant
```

For up the image, you will only need to run the box building automation script:
```
vagrant up
```

If you want to use KVM/Qemu:
```
vagrant up --provider=libvirt
```

To access the environment:

ssh:
```
vagrant ssh
```

web:
 - http://localhost:8081

### Additional information

Default credentials to webgui interface:
```
Username: admin
Password: change123
```

You can change the parameters by editing the file `provision.sh` from the beginning.

You need mapped a port to access the webgui, for this, add these line in `Vagrantfile`
```
config.vm.network "forwarded_port", guest: 80, host: 8081
```
reload config using command `vagrant reload` and access in your browser the address: http://localhost:8081

If you want to add your ssh key in the box, add the following lines in the file `Vagrantfile`:
```
config.vm.provision "shell" do |s|
    ssh_pub_key = File.readlines("#{Dir.home}/.ssh/id_rsa.pub").first.strip
    s.inline = <<-SHELL
      echo #{ssh_pub_key} >> /home/vagrant/.ssh/authorized_keys
    SHELL
end
```
