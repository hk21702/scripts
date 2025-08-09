#!/usr/bin/env bash
set -euo pipefail

# ---- Configurable defaults ----
DEFAULT_PACKAGES="build-essential clangd cmake git"
CHROOT_BASE="/srv/chroot"
UBUNTU_MIRROR="http://archive.ubuntu.com/ubuntu"

RELEASE=""
CHROOT_NAME=""
BUILDDEP_PKG=""
EXTRA_PACKAGES=""

usage() {
    echo "Usage: $0 [-r release] [-n name] [-b builddep-package] [-p extra-packages]"
    echo "  -r release         Ubuntu codename (default: autodetect)"
    echo "  -n name            Override chroot name"
    echo "  -b builddep-pkg    Install build dependencies for package"
    echo "  -p extra-packages  Comma-separated list of extra packages"
    exit 1
}

while getopts ":r:n:b:p:h" opt; do
    case $opt in
        r) RELEASE="$OPTARG" ;;
        n) CHROOT_NAME="$OPTARG" ;;
        b) BUILDDEP_PKG="$OPTARG" ;;
        p) EXTRA_PACKAGES="$OPTARG" ;;
        h) usage ;;
        \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
        :) echo "Option -$OPTARG requires an argument." >&2; usage ;;
    esac
done

# ---- Detect codename if not given ----
if [[ -z "$RELEASE" ]]; then
    RELEASE="$(lsb_release -sc)"
fi

if [[ -z "$CHROOT_NAME" ]]; then
    CHROOT_NAME="${RELEASE}-dev"
fi

CHROOT_DIR="${CHROOT_BASE}/${CHROOT_NAME}"
if [[ -d "$CHROOT_DIR" ]]; then
    echo "[!] Chroot directory $CHROOT_DIR already exists. Remove it first or use -n to specify a different name."
    exit 2
fi

echo "[*] Creating Ubuntu ${RELEASE} dev chroot at ${CHROOT_DIR}..."

# ---- Make sure needed tools are installed ----
sudo apt-get update
sudo apt-get install -y debootstrap schroot

# ---- Combine default and extra packages ----
ALL_PACKAGES="$DEFAULT_PACKAGES"
if [[ -n "$EXTRA_PACKAGES" ]]; then
    ALL_PACKAGES="${ALL_PACKAGES},${EXTRA_PACKAGES}"
fi

# ---- Create chroot ----
sudo debootstrap \
    "$RELEASE" "$CHROOT_DIR" "$UBUNTU_MIRROR"

# ---- Remove or empty existing sources.list ----
sudo truncate -s 0 "${CHROOT_DIR}/etc/apt/sources.list"

# ---- Install sources.list template ----
sudo tee "${CHROOT_DIR}/etc/apt/sources.list.d/ubuntu.sources" > /dev/null <<EOF
Types: deb deb-src
URIs: ${UBUNTU_MIRROR}
Suites: ${RELEASE} ${RELEASE}-updates ${RELEASE}-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb deb-src
URIs: http://security.ubuntu.com/ubuntu/
Suites: ${RELEASE}-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF


# ---- Register with schroot ----
sudo tee /etc/schroot/chroot.d/${CHROOT_NAME} > /dev/null <<EOF
[${CHROOT_NAME}]
description=Ubuntu ${RELEASE} development chroot
directory=${CHROOT_DIR}
groups=sbuild,root
root-groups=sbuild,root
type=directory
personality=linux
preserve-environment=true
EOF

# ---- Generate locale inside chroot ----
echo "[*] Generating locale en_US.UTF-8 in chroot..."
sudo schroot -c "${CHROOT_NAME}" -- apt-get update
sudo schroot -c "${CHROOT_NAME}" -- bash -c "apt-get install -y locales && locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8"

sudo schroot -c "${CHROOT_NAME}" -- bash -c "sed -i '/_chrony/d' /var/lib/dpkg/statoverride"

# ---- Install packages ---- Don't use --include as it doesn't always work with devel releases
echo "[*] Installing packages: $ALL_PACKAGES"
sudo schroot -c "${CHROOT_NAME}" -u root -- apt-get install -y $ALL_PACKAGES

# ---- Optionally install build-deps for a package ----
if [[ -n "$BUILDDEP_PKG" ]]; then
    echo "[*] Installing build dependencies for package: $BUILDDEP_PKG"
    sudo schroot -c "${CHROOT_NAME}" -- apt-get build-dep -y $BUILDDEP_PKG
fi

echo "[+] Chroot ${CHROOT_NAME} created and registered."
echo "    Enter it with: schroot -c ${CHROOT_NAME}"
