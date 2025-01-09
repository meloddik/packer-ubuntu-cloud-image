#!/bin/bash -eux

echo "==> waiting for cloud-init to finish"
while [ ! -f /var/lib/cloud/instance/boot-finished ]; do
    echo 'Waiting for Cloud-Init...'
    sleep 1
done

echo "==> Configuring puppet repository"
source /etc/lsb-release
sudo -E wget -P /root https://apt.puppet.com/puppet8-release-${DISTRIB_CODENAME}.deb
sudo -E dpkg -i /root/puppet8-release-${DISTRIB_CODENAME}.deb

echo "==> updating apt cache"
sudo apt-get update -qq

echo "==> installing qemu-guest-agent"
sudo apt-get install -y -qq qemu-guest-agent

echo "==> Installing build-essential package"
sudo apt-get install -y build-essential 

echo "==> Installing git"
sudo apt-get install -y git 

echo "==> Installing puppet"
sudo apt-get install -y puppet-agent 

echo "==> Upgrading apt packages"
sudo apt-get upgrade -y -qq

echo "==> Removing sample puppet production environment"
sudo rm -rf /etc/puppetlabs/code/environments/production


echo "==> Configuring puppet-infra git repo"
sudo install -m 744 -o ubuntu -g ubuntu -d /etc/puppetlabs/code/environments/production
sudo -u ubuntu git clone -b develop https://github.com/meloddik/puppet-infra.git /etc/puppetlabs/code/environments/production

echo "==> Installing ruby gems within puppet context"
sudo /opt/puppetlabs/puppet/bin/gem install gpgme --no-document
sudo /opt/puppetlabs/puppet/bin/gem install hiera-eyaml-gpg --no-document
sudo /opt/puppetlabs/puppet/bin/gem install r10k --no-document

echo "==> Installing third-party puppet modules"
cd /etc/puppetlabs/code/environments/production
sudo /opt/puppetlabs/puppet/bin/r10k puppetfile install --verbose

echo "==> Applying puppet modules"
sudo /opt/puppetlabs/puppet/bin/puppet apply --environment=production /etc/puppetlabs/code/environments/production/manifests

# echo "==> installing docker-ce"

# sudo apt-get install -y \
#     ca-certificates \
#     curl \
#     gnupg \
#     lsb-release

# sudo mkdir -p /etc/apt/keyrings

# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# echo \
#     "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
#     $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# sudo apt-get update -qq

# sudo apt-get install -y \
#     docker-ce \
#     docker-ce-cli \
#     containerd.io \
#     docker-compose-plugin
