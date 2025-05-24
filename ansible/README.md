# WVU Server Setup

This repository contains Ansible playbooks to automate the setup of the WVU server.

## Prerequisites

1. Place required files in the `files/` directory:
   - SSL certificate: `hykudev_lib_wvu_edu_2025_complete.cer`
   - SSL private key: `hykudev.lib.wvu.edu.2025.key`
   - Nginx config: `nginx-default`
   - Deploy key: `id_rsa`

## Installation

1. Install Ansible dependencies:
```bash
ansible-galaxy install -r requirements.yml
```

2. Update the inventory file with your server's IP address if needed

3. Run the playbook:
```bash
ansible-playbook -i ./ansible/inventory.ini ./ansible/playbook.yml
```

## What Gets Installed

The playbook will:
- Install Docker, Nginx, and other required packages
- Configure SSL certificates
- Set up Nginx with bad bot blocker
- Create user accounts with SSH access
- Configure Docker registry access
- Set up deployment keys

## Post-Installation

For working with Docker Compose, use:
```bash
alias dc='dotenv -e .env.production docker-compose -f docker-compose.production.yml'
```