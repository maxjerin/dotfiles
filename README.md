# Dotfiles managed with Ansible

## Encrypt/Decrypt Files
Sensitive files are encrypted. Replace them with your own

## Setting up script on MacOs

1. Install git
2. Download this repo
3. Run `./bootstrap.sh` (or `./bootstrap-macos.sh` directly)

The bootstrap script will:
- Install Homebrew (if not present)
- Install Stow
- Install pipx and project dependencies (ansible, ansible-lint, yamllint)
- Set up dotfiles using Stow


## Executing Dotfiles

```

ansible-playbook -i hosts dotfiles.yml --tags "macos"

```


### Other Commands

```
# Run entire playbook
ansible-playbook -i hosts dotfiles.yml

# Run individual tags
ansible-playbook -i hosts dotfiles.yml --tags "<tag>"

# Run playbook with specific user
ansible-playbook -i hosts -u <username> --ask-become-pass dotfiles.yml
```

### MacOs

```
ansible-playbook dotfiles.yml \
-i hosts \
--tags macos \
--extra-vars="ansible_python_interpreter=$(which python)"
```


## Setting up script on Linux

1. Install git
2. Download this repo
3. Run `./bootstrap.sh` (or `./bootstrap-linux.sh` directly)

The bootstrap script will:
- Install build essentials
- Install Linuxbrew (if not present)
- Install Stow
- Install pipx and project dependencies (ansible, ansible-lint, yamllint)
- Set up dotfiles using Stow

# Files

## pipx
Used to install and manage CLI tools (`ansible`, `ansible-lint`, `yamllint`) in isolated environments. This ensures clean installations without conflicts and makes it easy to update tools with `pipx upgrade-all`.

# Ad-Hoc Commands
Get Mac Os values of settings
```
ansible localhost -i hosts -m community.general.osx_defaults -a "domain=NSGlobalDomain key=KeyRepeat state=list value=1" --extra-vars="ansible_python_interpreter=$(which python)"
```

# Requirements.yml
* Used to download ansible roles that install common tools like chrome, docker, golang
* To add more roles, use command `ansible-galaxy install <role-name>`
* `ansible.cfg` is used to specify target ansible directory


# Inspirations

* https://github.com/bradleyfrank/ansible

* https://dev.to/smashse/devops-environment-on-macos-4gc7
* https://github.com/geerlingguy/mac-dev-playbook
* https://towardsthecloud.com/automatically-setup-macbook-development
