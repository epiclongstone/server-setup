#!/bin/bash

set -e

FULLLOG=/tmp/serversetup.log

echo "Full logfile: /tmp/serversetup.log"

echo " - Installing required components" | tee -a  ${FULLLOG}

sudo apt-get update >> ${FULLLOG}
sudo apt-get -y install         \
    software-properties-common  \
    wget                        \
    git	 >> ${FULLLOG}

echo " - Installing Ansible" | tee -a ${FULLLOG}

sudo apt-add-repository ppa:ansible/ansible -y >> ${FULLLOG} 2>&1
sudo apt-get update >> ${FULLLOG} 2>&1
sudo apt-get install -y ansible >> ${FULLLOG} 2>&1

echo " - Install Terraform" | tee -a ${FULLLOG}

cd /tmp
wget -O terraform.zip https://releases.hashicorp.com/terraform/0.11.8/terraform_0.11.8_linux_amd64.zip >> ${FULLLOG} 2>&1
unzip terraform.zip >> ${FULLLOG}
sudo mv terraform /usr/local/bin/terraform
rm terraform.zip

echo " - Cloning Server Setup repository" | tee -a ${FULLLOG} 2>&1

cd /tmp
git clone https://github.com/epiclongstone/server-setup >> ${FULLLOG}

echo " - Running Ansible" | tee -a ${FULLLOG}
cd /tmp/server-setup/ansible

VAULTFILE=${HOME}/.vault_pass

if ! [ -s ${VAULTFILE} ]; then
    echo "Ansible vault password not found in ~/.vault_pass" | tee -a ${FULLLOG}
    echo "Please enter Ansible Vault password to continue" | tee -a ${FULLLOG}
    read -s VAULTPASSWD
    echo "Storing Ansible Vault password in to ${VAULTFILE}" | tee -a ${FULLLOG}
    echo ${VAULTPASSWD} > ${VAULTFILE}
fi

echo " - Decrypting inventory file" | tee -a ${FULLLOG}
ansible-vault decrypt inventory/longstone.yml --vault-password-file ${VAULTFILE}

echo "Enter IP Address for longstone Server"
read LONGSTONE_IP
echo "Setting Longstone server IP to ${LONGSTONE_IP} in Ansible inventory" | tee -a ${FULLLOG}
sed -i "s/{{ longstone_IP }}/${LONGSTONE_IP}/" inventory/longstone.yml

echo " - Running Playbook" | tee -a ${FULLLOG}

ansible-playbook -i inventory/longstone.yml ./all.yml --vault-password-file ~/.vault_pass | tee -a ${FULLLOG}

ansible-playbook -i inventory/longstone.yml ./rancher-server.yml --vault-password-file ~/.vault_pass | tee -a ${FULLLOG}


