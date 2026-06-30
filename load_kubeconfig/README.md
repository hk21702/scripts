# load_kubeconfig

This script loads a kubeconfig file and sets the KUBECONFIG environment variable to point to it. This allows you to use kubectl and other Kubernetes tools with the specified kubeconfig file.

## Usage

To run the script, use the following command:

```bash
source load_kubeconfig.sh
```

Configs should be stored as `<namespace>.yaml` in `~/.kube/configs/` directory. For example, if you have a kubeconfig file for the `dev` namespace, it should be stored as `~/.kube/configs/dev.yaml`.

### Alias

It is highly recommended to create an alias for this script in your shell configuration file (e.g., .bashrc, .zshrc). For example:

```bash
alias load_kubeconfig='source /path/to/load_kubeconfig.sh'
```
