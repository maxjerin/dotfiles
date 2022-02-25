# Dotfiles managed with Ansible
## Installing Ansible on Ubuntu

```
sudo apt update \
sudo apt install software-properties-common \
sudo add-apt-repository --yes --update ppa:ansible/ansible \
sudo apt install ansible
```

## Executing Dotfiles

```
# Run entire playbook
ansible-playbook -i hosts dotfiles.yml

# Run individual tags
ansible-playbook -i hosts dotfiles.yml --tags "<tag>"

# Run playbook with specific user
ansible-playbook -i hosts -u <username> --ask-become-pass dotfiles.yml
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

# Inspirations

* https://dev.to/smashse/devops-environment-on-macos-4gc7
* https://github.com/geerlingguy/mac-dev-playbook
* https://towardsthecloud.com/automatically-setup-macbook-development
