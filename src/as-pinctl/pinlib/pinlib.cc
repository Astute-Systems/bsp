//
// Copyright (c) 2025, Astute Systems PTY LTD
//
// This file is part of the GXA-1 product developed by Astute Systems.
//
// Licensed under the MIT License. See the LICENSE file in the project root for full license
// details.
//
///
/// \brief A tool to manage the GPIO pins on the FTDI 232H chip on the GXA-1
///
/// \file pinlib.cc
///

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <unistd.h>
#include <errno.h>
#include <dirent.h>
#include <sys/stat.h>
#include <ftdi.h>
#include <gflags/gflags.h>
#include <iostream>
#include <stdio.h>
#include <libftdi1/ftdi.h>

struct ftdi_device_list *devlist;
int f, res, retval;

static void eeprom_get_value(struct ftdi_context *ftdi, enum ftdi_eeprom_value value_name,
                             int *value)
{
    if (ftdi_get_eeprom_value(ftdi, value_name, value) < 0) {
        printf("Unable to get eeprom value %d: %s. Aborting\n", value_name,
               ftdi_get_error_string(ftdi));
        exit(-1);
    }
}

int read_port(ftdi_context *ftdi)
{
    unsigned char buf[256];
    int f;

    // set baud rate 115200
    f = ftdi_set_baudrate(ftdi, 115200);

    while (true) {
        f = ftdi_read_data(ftdi, buf, 256);
        if (f < 0) {
            fprintf(stderr, "ftdi_read_data: %d (%s)\n", f, ftdi_get_error_string(ftdi));
            return -1;
        }
        for (int i = 0; i < f; i++) {
            printf("%c", buf[i]);
        }
    }
    return 0;
}

int open(struct ftdi_context **ftdiref, bool quiet)
{
    struct ftdi_context *ftdi;

    if (!quiet)
        printf("GXA-1 maintenance tool\n");

    if ((ftdi = ftdi_new()) == 0) {
        fprintf(stderr, "Failed to allocate ftdi structure :%s \n", ftdi_get_error_string(ftdi));
        retval = EXIT_FAILURE;
        return -1;
    }
    ftdi_set_interface(ftdi, INTERFACE_ANY);

    if ((res = ftdi_usb_find_all(ftdi, &devlist, 0, 0)) < 0) {
        fprintf(stderr, "No FTDI with default VID/PID found\n");
        retval = EXIT_FAILURE;
        return -1;
    }
    // printf("Number of FTDI devices found: %d\n", res);
    if (res > 1) {
        int i = 1;
        fprintf(stderr, "%d FTDI devices found: Remove other FTDI devices and try again.", res);
        retval = EXIT_FAILURE;
        return -1;
    } else if (res == 1) {
        f = ftdi_usb_open_dev(ftdi, devlist[0].dev);
        if (f < 0) {
            fprintf(stderr, "Unable to open device %s", ftdi_get_error_string(ftdi));
        }
    } else {
        fprintf(stderr, "No debug port found\n");
        f = 0;
        return -1;
    }

    *ftdiref = ftdi;
    return 0;
}

int close(ftdi_context *ftdi)
{
    // Restore normal UART mode before releasing the handle so any subsequent
    // ftdi_sio bind sees a sane chip. We do NOT re-attach the kernel driver
    // here (that is caller-controlled via reattach_kernel_driver()) because
    // after a recovery-strap the caller may want to leave the chip alone.
    if (ftdi) {
        ftdi_disable_bitbang(ftdi);
    }
    ftdi_usb_close(ftdi);
    ftdi_free(ftdi);
    return 0;
}

// Re-attach ftdi_sio to the FT232H by writing its interface path to
// /sys/bus/usb/drivers/ftdi_sio/bind. libftdi detaches ftdi_sio when it
// opens the device but never re-attaches on close, so /dev/ttyUSB* stays
// gone until we do this. libusb_attach_kernel_driver() returns success but
// does not reliably trigger a driver probe on ftdi_sio; sysfs bind does.
//
// Locates the FT232H (0403:6014, or any FTDI matched by libftdi_usb_find_all)
// via /sys and writes its interface-0 path to the bind attribute. Silent no-op
// if the driver is already bound or the device can't be found.
int reattach_kernel_driver(void)
{
    // Find the FTDI USB interface by scanning /sys/bus/usb/devices for
    // idVendor=0403. We intentionally don't hardcode the vid:pid or the
    // bus/port path so this works across carrier revisions.
    const char *dev_root = "/sys/bus/usb/devices";
    DIR *d = opendir(dev_root);
    if (!d) return -1;

    char busdev[256] = {0};
    struct dirent *ent;
    while ((ent = readdir(d)) != NULL) {
        // We want interface entries like "1-6.2:1.0"; skip everything else.
        const char *colon = strchr(ent->d_name, ':');
        if (!colon) continue;

        // Derive the parent USB device name by stripping ":X.Y". Sysfs
        // presents /sys/bus/usb/devices as a flat symlink farm, so we can't
        // just do "<iface>/../idVendor" — we need to look up the sibling.
        char parent[128] = {0};
        size_t plen = colon - ent->d_name;
        if (plen == 0 || plen >= sizeof(parent)) continue;
        memcpy(parent, ent->d_name, plen);
        parent[plen] = 0;

        char vid_path[512];
        snprintf(vid_path, sizeof(vid_path), "%s/%s/idVendor",
                 dev_root, parent);
        FILE *f = fopen(vid_path, "r");
        if (!f) continue;
        char vid[8] = {0};
        if (fgets(vid, sizeof(vid), f)) {
            // Strip newline for comparison.
            vid[strcspn(vid, "\r\n")] = 0;
        }
        fclose(f);
        if (vid[0] == 0 || strcmp(vid, "0403") != 0) continue;

        // Match interface 0 only (ftdi_sio binds per-interface).
        if (strcmp(colon, ":1.0") != 0) continue;

        snprintf(busdev, sizeof(busdev), "%s", ent->d_name);
        break;
    }
    closedir(d);

    if (busdev[0] == 0) {
        fprintf(stderr, "warning: no FTDI interface found under %s\n", dev_root);
        return -1;
    }

    // If already bound, nothing to do.
    char drv_link[512];
    snprintf(drv_link, sizeof(drv_link), "%s/%s/driver", dev_root, busdev);
    if (access(drv_link, F_OK) == 0) return 0;

    FILE *bind = fopen("/sys/bus/usb/drivers/ftdi_sio/bind", "w");
    if (!bind) {
        fprintf(stderr, "warning: cannot open ftdi_sio bind attribute: %s\n",
                strerror(errno));
        return -1;
    }
    if (fputs(busdev, bind) < 0) {
        fprintf(stderr, "warning: ftdi_sio bind write failed for %s: %s\n",
                busdev, strerror(errno));
        fclose(bind);
        return -1;
    }
    fclose(bind);
    return 0;
}

void bang(uint8_t pin_mask, struct ftdi_context *ftdi)
{
    if (ftdi_set_bitmode(ftdi, pin_mask, BITMODE_CBUS) < 0) {
        fprintf(stderr, "BITMODE failed.\n");
    }
}

int read_decode_eeprom_serial(struct ftdi_context *ftdi, bool quiet)
{
    char manufacturer[128], product[128], serial[128];
    ftdi_read_eeprom(ftdi);
    ftdi_eeprom_decode(ftdi, 0);
    ftdi_eeprom_get_strings(ftdi, manufacturer, 128, product, 128, serial, 128);

    // Print the serial number
    if (!quiet) {
        printf("Serial Number: %s\n", serial);

    } else {
        printf("%s\n", serial);
    }

    return 0;
}

int read_decode_eeprom(struct ftdi_context *ftdi)
{

    int i, j, f;
    int size;
    unsigned char buf[256];

    f = ftdi_read_eeprom(ftdi);
    if (f < 0) {
        fprintf(stderr, "ftdi_read_eeprom: %d (%s)\n", f, ftdi_get_error_string(ftdi));
        return -1;
    }

    ftdi_get_eeprom_value(ftdi, CHIP_SIZE, &size);
    if (size < 0) {
        fprintf(stderr, "No EEPROM found or EEPROM empty\n");
        return -1;
    }
    fprintf(stderr, "Chip type %d ftdi_eeprom_size: %d\n", ftdi->type, size);
    if (ftdi->type == TYPE_R) {
        fprintf(stderr, "Wrong FTDI chip detected. Aborting.\n");
        return -1;
    }

    ftdi_get_eeprom_buf(ftdi, buf, size);
    for (i = 0; i < size; i += 16) {
        fprintf(stdout, "0x%03x:", i);

        for (j = 0; j < 8; j++)
            fprintf(stdout, " %02x", buf[i + j]);
        fprintf(stdout, " ");
        for (; j < 16; j++)
            fprintf(stdout, " %02x", buf[i + j]);
        fprintf(stdout, " ");
        for (j = 0; j < 8; j++)
            fprintf(stdout, "%c", isprint(buf[i + j]) ? buf[i + j] : '.');
        fprintf(stdout, " ");
        for (; j < 16; j++)
            fprintf(stdout, "%c", isprint(buf[i + j]) ? buf[i + j] : '.');
        fprintf(stdout, "\n");
    }

    f = ftdi_eeprom_decode(ftdi, 1);
    if (f < 0) {
        fprintf(stderr, "ftdi_eeprom_decode: %d (%s)\n", f, ftdi_get_error_string(ftdi));
        return -1;
    }
    return 0;
}

void print_info(struct ftdi_context *ftdi)
{
    char manufacturer[128], product[128], serial[128];
    ftdi_read_eeprom(ftdi);
    ftdi_eeprom_decode(ftdi, 0);
    ftdi_eeprom_get_strings(ftdi, manufacturer, 128, product, 128, serial, 128);

    std::cout << "Device information:\n";
    std::cout << "\tManufacturer: " << manufacturer << "\n";
    std::cout << "\tProduct: " << product << "\n";
    std::cout << "\tSerial: " << serial << "\n";

// Check if ARM CPU
#if defined(__arm__) || defined(__aarch64__)
    std::cout << "\tSerial Ports:\n";
    std::cout << "\t\tPorts 1:\n";
    std::cout << "\t\tPorts 2:\n";
    std::cout << "\t\tPorts 3:\n";
    std::cout << "\t\tPorts 4:\n";
    std::cout << "\tBit LED:\n";
    std::cout << "\t\tStatus: ON\n";
    std::cout << "\tCAN termination:\n";
    std::cout << "\t\tcan0: UNTERMINATED\n";
    std::cout << "\t\tcan1: UNTERMINATED\n";
#endif
}
