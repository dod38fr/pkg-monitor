# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.box = "debian/jessie64"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  config.vm.network "forwarded_port", guest: 8080, host: 8084
  # config.vm.network "forwarded_port", guest: 22, host: 2222

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "pkg-monitor", "/vagrant_data"

  # a shared folder is setup by default with Debian image. This causes
  # problem on Windows
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
  # such as FTP and Heroku are also available. See the documentation at
  # https://docs.vagrantup.com/v2/push/atlas.html for more information.
  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  config.vm.provision "shell", inline: <<-SHELL
     echo "apt setup: Debian stable with a pinch of unstable"
     echo "deb http://ftp2.fr.debian.org/debian/ unstable main" > /etc/apt/sources.list.d/pkgmonit.list
     echo "Package: *\nPin: release a=stable\nPin-Priority: 900" > /etc/apt/preferences.d/pkgmonit
     echo "\nPackage: *\nPin: release a=unstable\nPin-Priority: 800" >> /etc/apt/preferences.d/pkgmonit

     if [ $(ip addr show |grep -c 192.168.0) -gt 0 ]
     then
         echo "apt proxy setup for my home"
         echo 'Acquire::http { Proxy "http://192.168.0.14:3142"; };' > /etc/apt/apt.conf
     fi

     apt-get update
     echo "installing required packages"
     apt-get install -y rsync git zile libmojolicious-perl/unstable libio-async-perl/unstable libio-async-loop-mojo-perl/unstable

     export HOME=/home/vagrant/
     export PKGMONIT=$HOME/pkg-monit
     export REPO=https://github.com/dod38fr/pkg-monitor.git

     echo "installing web server"
     if [ -d $PKGMONIT ]
     then
         cd $PKGMONIT
         git pull
         cd $HOME
     else
         git clone $REPO pkg-monit
     fi
         
     #mkdir -p $PKGMONIT
     #rsync -av /vagrant_data/ $PKGMONIT/

     echo "setting up systemd for webserver"
     cp $PKGMONIT/systemd/*.service /etc/systemd/system/
     systemctl daemon-reload
     systemctl enable pkg-monit
     systemctl start pkg-monit

     echo "setting up logrotate to restart server when dpkg.log is rotated"
     grep -q monit /etc/logrotate.d/dpkg || perl -n -i -E 'print ; print "\tpostrotate\n\t\tsystemctl restart pkg-monit\n\tendscript\n" if /dpkg.log/;' /etc/logrotate.d/dpkg

     echo "open the pakcage monitor at this URL: http://127.0.0.1:8084/"
  SHELL
end
