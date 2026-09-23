# Kubeconfig helpers

Use `fetch_kubeconfig` to save a kubeconfig from Vault, then source `load_kubeconfig` to select it in your current shell.

## Fetch from Vault

### Configuration

Requires the Vault CLI (`vault`). The Vault secret must contain a base64-encoded kubeconfig in its `kubeconfig_b64` field. Configure the Vault server address in your shell, for example in `~/.bashrc`:

```bash
export VAULT_ADDR="https://vault.example.com"
```

If needed, set other Vault CLI variables there too:

```bash
export VAULT_NAMESPACE="your-namespace"
export VAULT_CACERT="$HOME/.config/vault/ca.pem"
```

Run `source ~/.bashrc` to apply these settings to the current shell. If your Vault token is missing or expired, the fetcher runs `vault login`, which prompts for a token in the terminal (including over SSH). You can also run `vault login` beforehand. Do not store `VAULT_TOKEN` in your shell configuration.

To use a different Vault server for a single invocation:

```bash
VAULT_ADDR="https://other-vault.example.com" ./fetch_kubeconfig secret/services/example/kubeconfig
```

### Usage

From this directory, fetch a kubeconfig by its Vault path:

```bash
./fetch_kubeconfig secret/services/k8s-stg-desktop-managed-cluster-mediawiki/kubeconfig
```

By default, the filename comes from the directory immediately before `kubeconfig` in the Vault path. The example above saves `~/.kube/configs/k8s-stg-desktop-managed-cluster-mediawiki.yaml`. Pass a name to use a different filename, preferably one matching the Kubernetes namespace you want the loader to set:

```bash
./fetch_kubeconfig secret/services/k8s-stg-desktop-managed-cluster-mediawiki/kubeconfig stg-desktop
```

This saves `~/.kube/configs/stg-desktop.yaml`. Existing files are not overwritten unless you pass `--force` before the Vault path. The destination directory and config files are restricted to the current user.

## Load a kubeconfig

Source the loader from this directory so its `KUBECONFIG` change persists in your current shell:

```bash
source ./load_kubeconfig
```

The menu lists files in `~/.kube/configs/`. Selecting one exports `KUBECONFIG` to that file. If `kubectl` is installed, the loader also sets the selected config's current context to use the filename without its extension as the default namespace. For example, selecting `dev.yaml` sets the namespace to `dev`, so name files accordingly.

You can also unset `KUBECONFIG` to use the default `~/.kube/config`, or quit without changing your selection.

### Alias

For easier access, add an alias to your shell configuration (for example, `~/.bashrc`), replacing the path with the absolute path to this script:

```bash
alias load_kubeconfig='source /path/to/load_kubeconfig'
```
