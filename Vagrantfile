# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"
  config.vm.network "forwarded_port", guest: 80, host: 8000
  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
    vb.gui = false
     # Customize the amount of memory on the VM:
    vb.memory = "1024"
  end
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "bluegreendeployment.yaml"
    # Verbosity for our playbook deployment
    ansible.verbose = "-vv"
    # As Ubuntu version comes with python 3 installed, we will use it for Ansible
    ansible.extra_vars = { ansible_python_interpreter:"/usr/bin/python3" }
  end
end
