# Kubeconfig helpers

These scripts fetch kubeconfigs from Vault and load a selected kubeconfig into the current shell.

## Fetch from Vault

The Vault secret must contain a base64-encoded kubeconfig in the `kubeconfig_b64` field. The script uses the standard Vault CLI environment variables, so the server address can be configured in `~/.bashrc`:

```bash
export VAULT_ADDR="https://vault.example.com"
```

Optional Vault settings can be configured there as well:

```bash
export VAULT_NAMESPACE="your-namespace"
export VAULT_CACERT="$HOME/.config/vault/ca.pem"
```

Run `source ~/.bashrc` to apply changes to the current shell. The fetcher checks the current Vault token and automatically runs `vault login` when it is missing or expired. The Vault CLI securely prompts for the token in the terminal, so this flow works over SSH without a browser callback. To authenticate in advance, run `vault login` manually. Avoid storing `VAULT_TOKEN` directly in `~/.bashrc`.

For a one-off server override, set the address for only that invocation:

```bash
VAULT_ADDR="https://other-vault.example.com" ./fetch_kubeconfig services/example/kubeconfig
```

Once the Vault CLI is configured, fetch a kubeconfig with:

```bash
./fetch_kubeconfig secret/services/k8s-prod-documentation-ps7-ubuntu-wiki/kubeconfig
```

The config is written to `~/.kube/configs/k8s-prod-documentation-ps7-ubuntu-wiki.yaml`. To choose a different filename, such as one matching the Kubernetes namespace, pass a name:

```bash
./fetch_kubeconfig secret/services/k8s-prod-documentation-ps7-ubuntu-wiki/kubeconfig prod-documentation
```

Existing files are not overwritten unless `--force` is passed. The destination directory and config files are restricted to the current user.

## Load a kubeconfig

To run the script, use the following command:

```bash
source ./load_kubeconfig
```

Configs should be stored as `<namespace>.yaml` in `~/.kube/configs/` directory. For example, if you have a kubeconfig file for the `dev` namespace, it should be stored as `~/.kube/configs/dev.yaml`.

### Alias

It is highly recommended to create an alias for this script in your shell configuration file (e.g., .bashrc, .zshrc). For example:

```bash
alias load_kubeconfig='source /path/to/load_kubeconfig'
```
