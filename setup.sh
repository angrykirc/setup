#!/bin/bash
function echoc {
	echo -e "\e[$1m$2\e[0m"
}

if (( $EUID != 0 )); then
    echoc 31 "[!] Please run as root"
    # 31 is dark red, 32 is dark green
    exit
fi

# Parse arguments
# Valid arguments are: all, common, golang, docker, sshkey
# Note that for bash, 0 is true, <0> is false
for arg in "$@"
do
    declare INSTALL_$arg=y
done

# Expand 'all' to all options
if ! [ -z $INSTALL_all ]; then
	INSTALL_java=y
	INSTALL_common=y
	INSTALL_golang=y
	INSTALL_docker=y
	INSTALL_sshkey=y
fi

# Assuming that apt is already installed and user has sufficient privileges to run it
apt update -yq
# Install common utilities
if ! [ -z $INSTALL_common ]; then
	echoc 33 "[~] Installing common"
	apt install -yq git terminator neovim curl
	apt install -yq wireguard
	apt install -yq python3-pip
	# Install c++ compiler and stuff
	apt install -yq cmake gcc
else
	echoc 33 "[~] Skipping common, not selected for installation"
fi

# Install openJDK 19
if ! [ -z $INSTALL_java ]; then
	echoc 33 "[~] Installing java"
	apt purge -yq opendjdk*
	apt install -yq openjdk-19-jdk
else
	echoc 33 "[~] Skipping java, not selected for installation"
fi

# Install golang
if ! [ -z $INSTALL_golang ]; then
	echoc 33 "[~] Installing golang"
	GOLANG_PATH="/usr/local"
	GOLANG_TAR="go${GOLANG_LATEST_VER}.linux-amd64.tar.gz"
	GOLANG_EXPORT="export PATH=$PATH:${GOLANG_PATH}/go/bin"
	GOLANG_LATEST_VER=$(curl -L https://go.dev/VERSION?m=text | head -n 1 | cut -c 3-)
	GOLANG_CURRENT_VER=$(${GOLANG_PATH}/go/bin/go version | awk '{print $3}' | cut -c 3-)
	if [ "$GOLANG_CURRENT_VER" = "$GOLANG_LATEST_VER" ]; then
		echoc 33 "[~] Latest golang version ${GOLANG_CURRENT_VER} is already installed, skipping."
	else
		curl -L "https://go.dev/dl/${GOLANG_TAR}" -O
		rm -rf ${GOLANG_PATH}/go
		if tar -C ${GOLANG_PATH} -xzf ${GOLANG_TAR}; then	
			rm "${GOLANG_TAR}"
			chmod -R a+r ${GOLANG_PATH}
			echoc 32 "[.] Successfully installed golang v${GOLANG_LATEST_VER} to ${GOLANG_PATH}"
			# FIXME? Make symlink from $HOME to /usr/local/go
			# Add symlink to .bashrc
			if ! grep -Fxq "${GOLANG_EXPORT}" ~/.bashrc; then
				echo ${GOLANG_EXPORT} > ~/.bashrc
			fi
		else
			echoc 31 "[!] Golang installation failed, please check the log for details."
		fi
	fi
else
	echoc 33 "[~] Skipping golang, not selected for installation"
fi

# Generate SSH key if not exists
if ! [ -z $INSTALL_sshkey ]; then
	echoc 33 "[~] Generating ssh key"
	SSH_ED25519="~/.ssh/id_ed25519.pub"
	SSH_RSA="~/.ssh/id_rsa.pub"
	if ! [[ -f "${SSH_ED25519}" ]] && [[ -f "${SSH_RSA}" ]]; then
		ssh-keygen -t ed25519 -q -P ""
		echoc 32 "[.] The generated SSH key for this machine is:"
		cat ${SSH_ED25519}
		if which xclip > /dev/null; then
			cat ${SSH_ED25519} | xclip -selection clipboard
		fi
	else
		echoc 33 "[~] This machine already has an SSH key generated."
	fi
else
	echoc 33 "[~] Skipping sshkey, not selected for installation"
fi

