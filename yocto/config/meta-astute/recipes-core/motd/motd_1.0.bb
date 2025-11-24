SUMMARY = "Custom MOTD (Message of the Day) for BushNET systems"
DESCRIPTION = "Provides a custom MOTD with BushNET branding and system information"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://motd \
           file://update-motd.sh"

S = "${WORKDIR}"

inherit allarch

do_install() {
    # Install MOTD template and initial MOTD
    install -d ${D}${sysconfdir}
    install -m 644 ${WORKDIR}/motd ${D}${sysconfdir}/motd.template
    install -m 644 ${WORKDIR}/motd ${D}${sysconfdir}/motd
    
    # Install dynamic MOTD updater script
    install -d ${D}${sbindir}
    install -m 755 ${WORKDIR}/update-motd.sh ${D}${sbindir}/update-motd
    
    # Install systemd service for dynamic updates
    if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}; then
        install -d ${D}${systemd_unitdir}/system
        cat > ${D}${systemd_unitdir}/system/update-motd.service << EOF
[Unit]
Description=Update MOTD with current system information
After=network.target

[Service]
Type=oneshot
ExecStart=${sbindir}/update-motd
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
    fi
}

FILES:${PN} = "${sysconfdir}/motd \
               ${sysconfdir}/motd.template \
               ${sbindir}/update-motd \
               ${systemd_unitdir}/system/update-motd.service"

RDEPENDS:${PN} = "bash"

# Enable the service if systemd is available
SYSTEMD_SERVICE:${PN} = "${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'update-motd.service', '', d)}"
SYSTEMD_AUTO_ENABLE = "enable"

inherit ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'systemd', '', d)}

pkg_postinst:${PN}() {
    #!/bin/sh
    # Update MOTD with build-time information if running on target
    if [ -n "$D" ]; then
        # Installing to rootfs during build
        exit 0
    else
        # Running on target system
        if [ -x ${sbindir}/update-motd ]; then
            ${sbindir}/update-motd
        fi
    fi
}
