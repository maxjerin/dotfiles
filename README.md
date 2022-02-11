# Dotfiles managed with Ansible

# Install Ansible on Ubuntu

```
sudo apt update \
sudo apt install software-properties-common \
sudo add-apt-repository --yes --update ppa:ansible/ansible \
sudo apt install ansible
```

# Files

## Poetry 
Used to run `yamllint` and `ansible-lint` locally to fix issues in GHA ci

# Requirements.yml
* Used to download ansible roles that install common tools like chrome, docker, golang
* To add more roles, use command `ansible-galaxy install <role-name>`
* `ansible.cfg` is used to specify target ansible directory

# TODO

add macos integration test using this pattern https://github.com/geerlingguy/mac-dev-playbook/blob/master/.github/workflows/ci.yml
