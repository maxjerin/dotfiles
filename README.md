# Dotfiles managed with Ansible

## Encrypt/Decrypt Files
Sensitive files are encrypted. Replace them with your own

## Setting up script on MacOs

1. Install git
2. Download this repo
3. Run bootstrap.sh
4.  Update .zshrc file with
```
echo 'eval "$(pyenv init --path)"' >> ~/.zprofile

echo 'eval "$(pyenv init -)"' >> ~/.zshrc
```
5. Install python 3.9.8 `pyenv install 3.9.8`
6. Set python 3.9.8 as default `pyenv global 3.9.8`
7. Install poetry `pip install poetry`
8. Init poetry `poetry install`


## Executing Dotfiles

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


## Setting up script on Ubuntu

```
sudo apt update \
sudo apt install software-properties-common \
sudo add-apt-repository --yes --update ppa:ansible/ansible \
sudo apt install ansible
```

# Files

## Poetry
Used to run `yamllint` and `ansible-lint` locally to fix issues in GHA ci

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
