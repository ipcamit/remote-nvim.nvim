#!/usr/bin/env bash

# If anything fails, exit
set -eoE pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Source core helpers for logging (info, warn, error)
# shellcheck source=SCRIPTDIR/utils/core.sh
if [ -f "${SCRIPTS_DIR}/utils/core.sh" ]; then
    source "${SCRIPTS_DIR}/utils/core.sh"
else
    # Fallbacks in case script is run independently
    info() { echo -e "[INFO] $*"; }
    warn() { echo -e "[WARN] $*"; }
    error() { echo -e "[ERROR] $*"; }
fi

apt_packages=""
conda_packages=""
pip_packages=""

# Function to display usage information
function display_help() {
	cat <<EOM
Usage: $0 [options]
Options:
  -a       APT packages to install (quoted string, space separated).
  -c       CONDA packages to install (quoted string, space separated).
  -p       PIP packages to install (quoted string, space separated).
  -h       Display this help message and exit.
EOM
}

# Parse command-line options
while getopts "a:c:p:h" opt; do
	case $opt in
	a)
		apt_packages="$OPTARG"
		;;
	c)
		conda_packages="$OPTARG"
		;;
	p)
		pip_packages="$OPTARG"
		;;
	h)
		display_help
		exit 0
		;;
	\?)
		display_help
		exit 1
		;;
	:)
		echo "Option -$OPTARG requires an argument." >&2
		display_help
		exit 1
		;;
	esac
done

if [[ -n "$apt_packages" ]]; then
    info "Setting up APT packages: $apt_packages"
    # shellcheck disable=SC2086
    if command -v apt-get &>/dev/null; then
        if sudo apt-get update && sudo apt-get install -y $apt_packages; then
            info "APT packages installed successfully."
        else
            warn "Failed to install some APT packages. Continuing..."
        fi
    else
        warn "apt-get not found. Skipping APT package installation."
    fi
fi

if [[ -n "$conda_packages" ]]; then
    info "Setting up CONDA packages: $conda_packages"
    if command -v conda &>/dev/null; then
        # shellcheck disable=SC2086
        if conda install -y $conda_packages; then
            info "CONDA packages installed successfully."
        else
            warn "Failed to install some CONDA packages. Continuing..."
        fi
    else
        warn "conda not found on PATH. Skipping CONDA package installation."
    fi
fi

if [[ -n "$pip_packages" ]]; then
    info "Setting up PIP packages: $pip_packages"
    
    pip_cmd=""
    if command -v pip3 &>/dev/null; then
        pip_cmd="pip3"
    elif command -v pip &>/dev/null; then
        pip_cmd="pip"
    else
        warn "pip/pip3 not found on PATH. Skipping PIP package installation."
    fi

    if [[ -n "$pip_cmd" ]]; then
        # shellcheck disable=SC2086
        if $pip_cmd install $pip_packages; then
            info "PIP packages installed successfully."
        else
            warn "Failed to install some PIP packages. Continuing..."
        fi
    fi
fi

info "Environment setup complete."
