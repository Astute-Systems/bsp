# Debian cpack 
set(CPACK_GENERATOR "DEB")
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "Ross Newman")

# Combine the version and RC.
if (MEDIAX_SUFFIX)
  set(CPACK_PACKAGE_VERSION "${MEDIAX_MAJOR_VERSION}.${MEDIAX_MINOR_VERSION}.${MEDIAX_PATCH_VERSION}-${MEDIAX_SUFFIX}")
else()
  set(CPACK_PACKAGE_VERSION "${MEDIAX_MAJOR_VERSION}.${MEDIAX_MINOR_VERSION}.${MEDIAX_PATCH_VERSION}")
endif()

message(STATUS "CPACK_PACKAGE_VERSION: ${CPACK_PACKAGE_VERSION}")

execute_process(COMMAND lsb_release -rs 
                OUTPUT_VARIABLE UBUNTU_VERSION 
                OUTPUT_STRIP_TRAILING_WHITESPACE)
message(STATUS "System: ${CMAKE_SYSTEM_NAME}")
set(CPACK_DEBIAN_PACKAGE_DEPENDS_GSTREAMER "gstreamer1.0-plugins-good, gstreamer1.0-libav, gstreamer1.0-plugins-good, gstreamer1.0-plugins-bad, gstreamer1.0-vaapi")
if(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
    message(STATUS "Linux ${CMAKE_SYSTEM_VERSION} ${CMAKE_SYSTEM_NAME}")
    if(${UBUNTU_VERSION} MATCHES "20.04")
        message(STATUS "Ubuntu 20.04")
        set(CPACK_DEBIAN_PACKAGE_DEPENDS "qt5-qpa-plugins, qt5-webview-plugins, libxcb-xinerama0, libqt5core5, libqt5widgets5, libqt5gui5, libqt5dbus5, libsnmp-base, ${CPACK_DEBIAN_PACKAGE_DEPENDS_GSTREAMER}")
    endif()
    if(${UBUNTU_VERSION} MATCHES "22.04")
        message(STATUS "Ubuntu 22.04")
        set(CPACK_DEBIAN_PACKAGE_DEPENDS "qt6-qpa-plugins, qt6-webview-plugins, libxcb-xinerama0, libqt6core6, libqt6widgets6, libqt6gui6, libqt6dbus6, libsnmp-base, ${CPACK_DEBIAN_PACKAGE_DEPENDS_GSTREAMER}")
    endif()
    if(${UBUNTU_VERSION} MATCHES "23.10")
        message(STATUS "Ubuntu 23.10")
        set(CPACK_DEBIAN_PACKAGE_DEPENDS "qt6-qpa-plugins, qt6-webview-plugins, libxcb-xinerama0, libqt6core6, libqt6widgets6, libqt6gui6, libqt6dbus6, libsnmp-base, ${CPACK_DEBIAN_PACKAGE_DEPENDS_GSTREAMER}")
    endif()
    if(${UBUNTU_VERSION} MATCHES "24.04")
        message(STATUS "Ubuntu 24.04")
        set(CPACK_DEBIAN_PACKAGE_DEPENDS "libsnmp40, libgoogle-glog0v6t64, qt6-qpa-plugins, qt6-webview-plugins, libxcb-xinerama0, libqt6core6, qt6-qpa-plugins, libqt6widgets6, libqt6gui6, libqt6dbus6, libsnmp-base, ${CPACK_DEBIAN_PACKAGE_DEPENDS_GSTREAMER}")
    endif()
else()
  message(ERROR "Unsupported system")
endif()

set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE ${CMAKE_SYSTEM_PROCESSOR})
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
set(CPACK_DEBIAN_PACKAGE_GENERATE_SHLIBS ON)
set(CPACK_DEBIAN_PACKAGE_GENERATE_SHLIBS_POLICY ">=")
set(CPACK_DEBIAN_PACKAGE_CONTROL_STRICT_PERMISSION TRUE)
set(CPACK_DEBIAN_PACKAGE_SECTION "libs")
set(CPACK_DEBIAN_PACKAGE_HOMEPAGE "https://defencex.ai")
set(CPACK_DEBIAN_PACKAGE_DESCRIPTION "ToolX GUI for degugging LDM and GVA based systems")
set(CPACK_DEBIAN_PACKAGE_NAME "toolx")
set(CPACK_DEBIAN_FILE_NAME "${CPACK_DEBIAN_PACKAGE_NAME}_${CPACK_PACKAGE_VERSION}_${CPACK_DEBIAN_PACKAGE_ARCHITECTURE}.deb")
set(CPACK_STRIP_FILES TRUE)

# Disable error -Wno-dev
set(CMAKE_WARN_DEPRECATED OFF)

include(CPack)
