#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-3.0
#
# RootFS Helper Functions
# Utility functions for rootfs package management

# gen_md5 <output_file> <source_path>
# Generate MD5 checksums for all files in a directory (excluding DEBIAN/)
gen_md5(){
    local md5_file=$1
    local source_path=$2
    
    pushd "${source_path}" > /dev/null
    find . -type f ! -path './DEBIAN/*' -printf '%P\0' | xargs -r0 md5sum > "${md5_file}"
    popd > /dev/null
}

# install_kernel_packages <packages_dir>
# Install kernel packages into rootfs
install_kernel_packages(){
    local pkg_dir=$1
    
    if [ ! -d "${pkg_dir}" ]; then
        echo "WARNING: Kernel packages directory not found: ${pkg_dir}"
        return 1
    fi
    
    echo "Installing kernel packages..."
    for deb in ${pkg_dir}/*.deb; do
        if [ -f "${deb}" ]; then
            echo "  Installing: $(basename ${deb})"
            cp "${deb}" ${ROOTFS}/tmp/
            chroot ${ROOTFS} dpkg -i /tmp/$(basename ${deb})
            rm ${ROOTFS}/tmp/$(basename ${deb})
        fi
    done
    
    echo "Kernel packages installed"
}

# create_user <username> <password>
# Create a user with sudo privileges
create_user(){
    local username=$1
    local password=$2
    
    echo "Creating user: ${username}"
    
    chroot ${ROOTFS} useradd -m -s /bin/bash ${username}
    echo "${username}:${password}" | chroot ${ROOTFS} chpasswd
    chroot ${ROOTFS} usermod -aG sudo ${username}
    
    echo "User ${username} created"
}

# set_root_password <password>
# Set root password
set_root_password(){
    local password=$1
    
    echo "Setting root password..."
    echo "root:${password}" | chroot ${ROOTFS} chpasswd
}

# enable_service <service_name>
# Enable a systemd service
enable_service(){
    local service=$1
    
    echo "Enabling service: ${service}"
    chroot ${ROOTFS} systemctl enable ${service}
}

# disable_service <service_name>
# Disable a systemd service
disable_service(){
    local service=$1
    
    echo "Disabling service: ${service}"
    chroot ${ROOTFS} systemctl disable ${service}
}

# install_packages <package_list>
# Install additional packages in chroot
install_packages(){
    local packages=$@
    
    echo "Installing additional packages: ${packages}"
    chroot ${ROOTFS} apt-get update
    chroot ${ROOTFS} apt-get install -y ${packages}
}

# cleanup_apt
# Clean APT cache
cleanup_apt(){
    echo "Cleaning APT cache..."
    chroot ${ROOTFS} apt-get clean
    chroot ${ROOTFS} apt-get autoclean
    rm -rf ${ROOTFS}/var/lib/apt/lists/*
}

# set_timezone <timezone>
# Set system timezone
set_timezone(){
    local timezone=$1
    
    echo "Setting timezone: ${timezone}"
    chroot ${ROOTFS} ln -sf /usr/share/zoneinfo/${timezone} /etc/localtime
}

# set_locale <locale>
# Set system locale
set_locale(){
    local locale=$1
    
    echo "Setting locale: ${locale}"
    chroot ${ROOTFS} locale-gen ${locale}
    chroot ${ROOTFS} update-locale LANG=${locale}
}

