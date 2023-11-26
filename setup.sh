#!/bin/bash
# Colorize output
RC="\e[31m"
GC="\e[32m"
CC="\e[0m"
# Parse arguments
# Valid arguments are: all, common, golang, docker
# TODO

# Assuming that apt is already installed and user has sufficient privileges to run it
apt -y update
# Install common utilities
apt -y install terminator neovim curl
# TODO Install python 3.11 

# Install openJDK 19
apt -y remove openjdk*
apt -y purge opendjdk*
apt -y install openjdk-19-jdk

# Install golang 
GOLANG_VER="1.21.4"
GOLANG_PATH="/usr/local"
GOLANG_TAR="go${GOLANG_VER}.linux-amd64.tar.gz"
GOLANG_EXPORT="export PATH=$PATH:${GOLANG_PATH}/go/bin"
curl -L "https://go.dev/dl/${GOLANG_TAR}" -O
rm -rf ${GOLANG_PATH}/go
if tar -C ${GOLANG_PATH} -xzf "${GOLANG_TAR}"
then	
	rm "${GOLANG_TAR}"
	echo -e "${GC}Successfully installed golang v${GOLANG_VER} to ${GOLANG_PATH}${CC}"
	# FIXME? Make symlink from $HOME to /usr/local/go
	# Add symlink to .bashrc
	if ! grep -Fxq "${GOLANG_EXPORT}" ~/.bashrc
	then
		echo ${GOLANG_EXPORT} > ~/.bashrc
	fi
else
	echo -e "${RC}Golang installation failed, please check the log for details:${CC}"
fi

# Generate SSH key if not exists
SSH_ED25519="~/.ssh/id_ed25519.pub"
SSH_RSA="~/.ssh/id_rsa.pub"
if ! [[ -f "${SSH_ED25519}" ]] && [[ -f "${SSH_RSA}" ]]; then
	ssh-keygen -t ed25519 -q -P ""
	echo -e "${GC}The generated SSH key for this machine is:${CC}"
	cat ${SSH_ED25519}
else
	echo -e "${RC}This machine already has an SSH key generated${CC}"
fi
