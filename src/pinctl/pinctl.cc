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
/// \file pinctl.cc
///

#include <ctype.h>
#include <unistd.h>
#include <version.h>
#include <info.h>
#include <pinlib.h>
#include <gflags/gflags.h>
#include <ftdi.h>
#include <signal.h>
#include <iostream>

DEFINE_bool(info, false, "Print all the device information and current state");
DEFINE_bool(shutdown, false, "Shutdown, assert reset");
DEFINE_bool(startup, false, "Startup, release reset");
DEFINE_bool(reboot, false, "Reboot, assert reset then release reset");
DEFINE_bool(quiet, false, "Less output, raw vales");
DEFINE_bool(serial, false, "Serial number request");
DEFINE_bool(recovery, false, "Enable recovery mode (will reboot the device)");
DEFINE_bool(read, false, "Read the FTDI device");
DEFINE_bool(uart, false, "Dump the UART data");
DEFINE_int32(pin, 0, "FTDI CBUS pin value 0-7");
DEFINE_bool(high, false, "Set CBUS pin high");

#define USE_LIB 0

// Signal interrupt handler
void signal_handler(int signum)
{
    std::cerr << "Closing device\n";
    exit(signum);
}

int main(int argc, char **argv)
{
    struct ftdi_context *ftdi = nullptr;

    // Register signal and signal handler
    signal(SIGINT, signal_handler);

    gflags::SetUsageMessage("Control the CBUS pins on the FTDI 232H chip");
    gflags::SetVersionString("v" + kVersion + " " GIT_HASH_SHORT " (Build date " BUILD_DATE ")");
    gflags::ParseCommandLineFlags(&argc, &argv, true);

    // Check sudo and exit if not
    if (geteuid() != 0) {
        std::cerr << "This program must be run as root\n";
        exit(EXIT_FAILURE);
    }

    int retval = 0;

    if (open(&ftdi, FLAGS_quiet) < 0) {
        return EXIT_FAILURE;
    }

    unsigned char pin_mask = 0b11111111;

    const unsigned char pin6_low = 0b00010000; //  cbus 5 low RESET
    const unsigned char pin6_high = 0b00010001; //  cbus 5 high RESET
    const unsigned char pin5_low = 0b00100000; //  cbus 6 low RECOVERY
    const unsigned char pin5_high = 0b00100010; //  cbus 6 high RECOVERY

    if (FLAGS_info) {
        print_info(ftdi);
    }

    if (FLAGS_shutdown) {
        if (!FLAGS_quiet)
            std::cout << "Shutdown requested.\n";
        bang(pin6_low, ftdi);
    }

    if (FLAGS_startup) {
        if (!FLAGS_quiet)
            std::cout << "Startup requested.\n";
        bang(pin6_high, ftdi);
    }

    if (FLAGS_reboot) {
        if (!FLAGS_quiet)
            std::cout << "Reboot requested.\n";
        bang(pin6_low, ftdi);
        usleep(500000);
        bang(pin6_high, ftdi);
    }

    if (FLAGS_uart) {
        if (!FLAGS_quiet)
            std::cout << "Dumping UART data (CTRL+C to quit):\n";
        read_port(ftdi);
    }

    if (FLAGS_serial) {
        read_decode_eeprom_serial(ftdi, FLAGS_quiet);
    }

    if (FLAGS_recovery) {
        if (!FLAGS_quiet)
            std::cerr << "Recovery requested.\n";
        bang(pin5_low, ftdi);
        usleep(500000);
        bang(pin5_low | pin6_low, ftdi);
        usleep(500000);
        bang(pin5_low | pin6_high, ftdi);
        usleep(500000);
        bang(pin5_high | pin6_high, ftdi);
    }
    if (FLAGS_pin == 5) {
        if (FLAGS_high) {
            pin_mask |= 0b00010001;
        }
        if (!FLAGS_high) {
            pin_mask |= 0b00010000;
        }
    }
    if (FLAGS_pin == 6) {
        if (FLAGS_high) {
            pin_mask |= 0b00010001;
        }
        if (!FLAGS_high) {
            pin_mask |= 0b00010000;
        }
    }

    if (FLAGS_read) {
        if (read_decode_eeprom(ftdi) < 0) {
            retval = EXIT_FAILURE;
        } else {
            retval = EXIT_SUCCESS;
        }
    }

    // if (ftdi_set_bitmode(ftdi, pin_mask, BITMODE_CBUS) < 0) {
    if (ftdi_set_bitmode(ftdi, pin_mask, BITMODE_RESET) < 0) {
        std::cerr << "BITMODE failed.\n";
    }

    close(ftdi);

    gflags::ShutDownCommandLineFlags();

    if (!FLAGS_quiet)
        std::cout << "Done!\n";

    return retval;
}

