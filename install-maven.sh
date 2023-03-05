#!/usr/bin/bash

link_to_tar='https://dlcdn.apache.org/maven/maven-3/3.9.0/binaries/apache-maven-3.9.0-bin.tar.gz'

function print_error() {
	echo -e "\e[31;1m$1\e[0m"
}

if command -v mvn &> /dev/null
then
	print_error "Installation cancelled: Found an already installed maven!"
	mvn --version
	exit 1
fi

archive_name="${link_to_tar##*/}"

echo -e "\e[37;1mMaven installation\e[0m"
[[ $archive_name =~ [[:digit:].]+ ]]
if [ $? -ne 0 ]; then
	print_error "Warning: Version number is not found."
else
	archive_ver=${BASH_REMATCH[0]}
	echo "Version: $archive_ver"
fi
echo -e "\nURL to archive:\t$link_to_tar"
echo -e "Archive filename:\t$archive_name"

echo -e "\nStep 1: Downloading."
cd ~
wget "$link_to_tar"

if [ $? -ne 0 ]; then
	print_error "Error: Unable to download the maven archive."
	exit 1
fi

echo -e "\nStep 2: Extracting."
mvn_dir_name=$(tar tf "$archive_name" | head -1 | cut -d '/' -f1 | sort | uniq)
echo "Target path: /opt/$mvn_dir_name"

sudo tar -xzvf "$archive_name" -C /opt/

if [[ $? -ne 0 || ! -d "/opt/$mvn_dir_name" ]]; then
	print_error "Error: An issue occurred during archive extraction."
	exit 1
fi

echo -e "\Step 3: Creation of symlink to maven -- /opt/maven"
sudo ln -s "/opt/$mvn_dir_name" /opt/maven
ls -ld /opt/maven

echo -e "\nStep 4: Preparing shell script to update maven-related environment variables (/etc/profile.d/maven.sh)."
echo -e "export M2_HOME=/opt/maven\n\
export MAVEN_HOME=/opt/maven\n\
export PATH=\${M2_HOME}/bin:\${PATH}" | sudo tee /etc/profile.d/maven.sh

echo "Loading of the environment variables..."
source /etc/profile.d/maven.sh

if command -v mvn &> /dev/null
then
        echo -e "\Step 6: Removing of downloaded archive to clean up space."
        rm -f ~/"$archive_name"
	mvn --version
        echo -e "\n\e[37;1mMaven $archive_ver successfully installed"'!'"\e[0m"
fi
