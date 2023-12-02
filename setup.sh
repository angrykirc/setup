#!/bin/bash
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Single file installation script for Ubuntu based Linux  #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
function echoc {
	echo -e "\e[$1m$2\e[0m"
}

failure=0
function serr {
	failure=$((failure + $?))
}

function cerr {
	failure=0
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
apt-get update -yqq
# Install common utilities
if ! [ -z $INSTALL_common ]; then
	echoc 33 "[~] Installing common"
	if [ `dpkg -s git terminator neovim curl 2>/dev/null | grep Status | wc -l` -ge "4" ] && [ -z $INSTALL_reinstall ]; then
		echoc 33 "[~] common is already installed, skipping."
	else
		cerr
		serr `apt-get install -yq git terminator neovim curl`
		serr `apt-get install -yq wireguard`
		serr `apt-get install -yq python3-pip`
		# Install c++ compiler and stuff
		serr `apt-get install -yq cmake gcc`
		if [ -z $failure ]; then
			echoc 31 "[!] One or more commands failed, unable to install: common"
		else
			echoc 32 "[.] Successfully installed: common"
		fi
	fi
else
	echoc 33 "[~] Skipping common, not selected for installation"
fi

# Install openJDK 19
if ! [ -z $INSTALL_java ]; then
	echoc 33 "[~] Installing java"
	if `dpkg -s openjdk-19-jdk 2>/dev/null | grep -q Status` && [ -z $INSTALL_reinstall ]; then
		echoc 33 "[~] OpenJDK 19 is already installed, skipping."
	else
		cerr
		serr `apt-get purge -yq openjdk*`
		serr `apt-get install -yq openjdk-19-jdk`
		if [ -z $failure ]; then
			echoc 31 "[!] One or more commands failed, unable to install: java"
		else
			echoc 32 "[.] Successfully installed: java"
		fi
	fi
else
	echoc 33 "[~] Skipping java, not selected for installation"
fi

# Install golang
if ! [ -z $INSTALL_golang ]; then
	echoc 33 "[~] Installing golang"
	GOLANG_PATH="/usr/local"
	GOLANG_EXPORT="export PATH=$PATH:$GOLANG_PATH/go/bin"
	GOLANG_LATEST_VER=$(curl -sL https://go.dev/VERSION?m=text | head -n 1 | cut -c 3-)
	GOLANG_CURRENT_VER=$($GOLANG_PATH/go/bin/go version 2>/dev/null | awk '{print $3}' | cut -c 3-)
	GOLANG_TAR="go${GOLANG_LATEST_VER}.linux-amd64.tar.gz"
	if [ "$GOLANG_CURRENT_VER" = "$GOLANG_LATEST_VER" ] && [ -z $INSTALL_reinstall ]; then
		echoc 33 "[~] Latest golang version $GOLANG_CURRENT_VER is already installed, skipping."
	else
		cerr
		serr `curl -sL "https://go.dev/dl/${GOLANG_TAR}" -O`
		serr `rm -rf $GOLANG_PATH/go`
		serr `tar -C $GOLANG_PATH -xzf $GOLANG_TAR`
		serr `rm "${GOLANG_TAR}"`
		serr `chmod -R a+r ${GOLANG_PATH}`
		
		if [ -z $failure ]; then
			echoc 31 "[!] Golang installation failed, please check the log for details."
		else
			# FIXME? Make symlink from $HOME to /usr/local/go
			# Add symlink to .bashrc
			if ! grep -Fxq "$GOLANG_EXPORT" ~/.bashrc; then
				echo $GOLANG_EXPORT > ~/.bashrc
			fi
			echoc 32 "[.] Successfully installed golang v$GOLANG_LATEST_VER to $GOLANG_PATH"
		fi
	fi
else
	echoc 33 "[~] Skipping golang, not selected for installation"
fi

if ! [ -z $INSTALL_docker ]; then
	echoc 33 "[~] Installing docker"
	if `dpkg -s docker-ce 2>/dev/null | grep -q Status` && [ -z $INSTALL_reinstall ]; then
		echoc 33 "[~] docker is already installed, skipping."
	else
		cerr
		serr `apt-get install -yq ca-certificates curl gnupg`
		serr `install -m 0755 -d /etc/apt/keyrings`
		serr `curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg`
		serr `chmod a+r /etc/apt/keyrings/docker.gpg`
		echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$UBUNTU_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
		apt-get update -yq
		serr `apt-get install -yq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin`
		if [ -z $failure ]; then
			echoc 31 "[!] Docker installation failed, please check the log for details."
		else
			echoc 32 "[.] Successfully installed: docker"
		fi
	fi
else
	echoc 33 "[~] Skipping docker, not selected for installation"
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

