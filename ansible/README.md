# WVU Server Setup

This repository contains Ansible playbooks to automate the setup of the WVU server.

---

## Prerequisites

1. Place required files in the `ansible/files/` directory:

   - SSL certificate: `hykudev_lib_wvu_edu_2025_complete.cer`
   - SSL private key: `hykudev.lib.wvu.edu.2025.key`
   - Nginx config: `nginx-default`
   - Deploy SSH key for GitHub access: `id_rsa`

2. Ensure you have Ansible installed on your local machine or control node.

---

## Installation

1. Install required Ansible roles:

   ```bash
   ansible-galaxy install -r ansible/requirements.yml
   ```

2. Update the inventory file:

   Edit `ansible/inventory.ini` to match your environment:

   - Add server IP or hostname if needed.
   - Define users to create if applicable.

---

## Managing the GHCR Token

You will need a **GitHub Container Registry (GHCR) Personal Access Token (PAT)** with at least `read:packages` scope.

For security, store it in an **Ansible Vault**-encrypted file:

1️⃣ Create a file in `ansible/` called `ghcr-token.yml`:

   ```yaml
   ghcr_token: YOUR_GHCR_PAT_HERE
   ```

2️⃣ Encrypt it with Ansible Vault (recommended to output to a committed vault file):

   ```bash
   ansible-vault encrypt ansible/ghcr-token.yml --output ansible/ghcr-token.vault.yml
   ```

✅ This ensures your token is stored securely and not in plaintext.

3️⃣ Do not commit the **unencrypted** `ghcr-token.yml` to your repository:

   Add this to your `.gitignore`:

   ```
   ansible/ghcr-token.yml
   ```

✅ You *can* commit the **encrypted** vault file:

   ```
   ansible/ghcr-token.vault.yml
   ```

---

## Running the Playbook

Run the playbook with:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml --ask-vault-pass -e @ansible/ghcr-token.vault.yml
```

✅ `--ask-vault-pass` prompts for the vault password to decrypt the token.
✅ `-e @ansible/ghcr-token.vault.yml` loads the GHCR token securely as a variable.

---

## What Gets Installed

The playbook will:

- Install Docker, Nginx, and other required packages
- Configure SSL certificates
- Set up Nginx with Bad Bot Blocker
- Optionally create user accounts with specified groups
- Configure Docker registry login with GHCR
- Optionally install deploy SSH key for server-side GitHub repo access

---

## Example Inventory

Your `ansible/inventory.ini` might look like:

```ini
[all]
localhost ansible_connection=local

[all:vars]
ssh_users=[
  {"name":"ansible"},
  {"name":"ar00116"},
  {"name":"tam0013"},
  {"name":"sfgiessler"}
]
manage_local_users=false
install_deploy_key=false
```

✅ `manage_local_users=false` means no local user accounts will be created (useful if accounts are managed centrally via LDAP/SSO).
✅ `install_deploy_key=false` means the deploy SSH key will not be copied to root (avoiding overwriting existing keys).

---

## User Account Management

- If `manage_local_users=true`, Ansible will create the users in `ssh_users` with `/home/<username>` and add them to:

  ```
  adm,sudo,docker
  ```

- If you don't want to manage users with Ansible, set:

  ```
  manage_local_users=false
  ```

---

## Managing the Deploy SSH Key

- The deploy key (`id_rsa`) is used by the server itself to **clone private GitHub repos over SSH**.
- Typically added to your GitHub repo as a **Deploy Key** with **read-only** access.
- Control installation with:

  ```
  install_deploy_key=true
  ```

---

## Notes

- Ensure your Ansible user has sudo permissions on the target server.
- Rotate your GHCR PAT regularly and update the vault-encrypted `ghcr-token.vault.yml` as needed:

  ```bash
  ansible-vault edit ansible/ghcr-token.vault.yml
  ```

- Avoid committing unencrypted secrets.

---

## TL;DR

✅ Place all required files in `ansible/files/`
✅ Create and encrypt your GHCR token:

```bash
ansible-vault encrypt ansible/ghcr-token.yml --output ansible/ghcr-token.vault.yml
```

✅ Run the playbook:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml --ask-vault-pass -e @ansible/ghcr-token.vault.yml
```

---

## Best Practice

✅ Use Ansible Vault for all secrets in this repo.
✅ Commit only **encrypted** vault files, never raw secrets.
✅ Rotate keys and tokens regularly.
