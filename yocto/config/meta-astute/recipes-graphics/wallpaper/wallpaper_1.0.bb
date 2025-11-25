SUMMARY = "BushNET Desktop Wallpaper"
DESCRIPTION = "Installs the BushNET wallpaper for desktop environments"
LICENSE = "CLOSED"

SRC_URI = "file://Wallpaper.png"

S = "${WORKDIR}"

do_install() {
    # Install to standard pixmaps directory
    install -d ${D}${datadir}/pixmaps
    install -m 0644 ${WORKDIR}/Wallpaper.png ${D}${datadir}/pixmaps/bushnet-wallpaper.png
    
    # Also install to backgrounds directory for various desktop environments
    install -d ${D}${datadir}/backgrounds
    install -m 0644 ${WORKDIR}/Wallpaper.png ${D}${datadir}/backgrounds/bushnet-wallpaper.png
    
    # Create weston.ini configuration if weston is being used
    if ${@bb.utils.contains('DISTRO_FEATURES', 'wayland', 'true', 'false', d)}; then
        install -d ${D}${sysconfdir}/xdg/weston
        cat > ${D}${sysconfdir}/xdg/weston/weston.ini << EOF
[shell]
background-image=${datadir}/backgrounds/bushnet-wallpaper.png
background-type=scale-crop
background-color=0xff002244
EOF
    fi
}

FILES:${PN} = " \
    ${datadir}/pixmaps/bushnet-wallpaper.png \
    ${datadir}/backgrounds/bushnet-wallpaper.png \
    ${sysconfdir}/xdg/weston/weston.ini \
"

RDEPENDS:${PN} = ""
