SUMMARY = "Custom APT sources configuration for Astute Systems"
DESCRIPTION = "Adds custom APT sources.list entries for Astute Systems repositories and configures package management"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://astute.list \
           file://astute.gpg \
           file://apt.conf"

S = "${WORKDIR}"

# Inherit features for package management
inherit allarch

do_install() {
    # Create APT configuration directories
    install -d ${D}${sysconfdir}/apt/sources.list.d
    install -d ${D}${sysconfdir}/apt/trusted.gpg.d
    install -d ${D}${sysconfdir}/apt/apt.conf.d
    
    # Install APT sources and GPG key
    install -m 644 ${WORKDIR}/astute.list ${D}${sysconfdir}/apt/sources.list.d/
    install -m 644 ${WORKDIR}/astute.gpg ${D}${sysconfdir}/apt/trusted.gpg.d/
    
    # Install APT configuration if present
    if [ -f ${WORKDIR}/apt.conf ]; then
        install -m 644 ${WORKDIR}/apt.conf ${D}${sysconfdir}/apt/apt.conf.d/99-astute.conf
    fi
}

FILES:${PN} = "${sysconfdir}/apt/sources.list.d/* \
               ${sysconfdir}/apt/trusted.gpg.d/* \
               ${sysconfdir}/apt/apt.conf.d/*"

# Only depend on APT when package management is enabled
RDEPENDS:${PN} = "${@bb.utils.contains('DISTRO_FEATURES', 'package-management', 'apt ca-certificates', '', d)}"

# Ensure this is architecture independent
PACKAGE_ARCH = "all"
