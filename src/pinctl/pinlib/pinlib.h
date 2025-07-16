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
/// \file pinlib.h
///

#ifndef __PINCTL_PINLIB_PINLIB_H
#define __PINCTL_PINLIB_PINLIB_H

#include <ctype.h>
#include <ftdi.h>

///
/// \brief Get eeprom value
///
/// \param ftdi pointer to ftdi_context
/// \param value_name Enum of the value to get
/// \param value Value to get
///
/// Function will abort the program on error
///
int open(struct ftdi_context **ftdi, bool quiet);

///
///  Read the FTDI serial port and print received data to stdout
///
/// \param ftdi pointer to ftdi_context
/// \return 0 on success, -1 on error
///
int close(struct ftdi_context *ftdi);

///
/// \brief Open the FTDI device
///
/// \param ftdiref pointer to ftdi_context
/// \param quiet bool to suppress output
/// \return 0 on success, -1 on error
///
int read_port(ftdi_context *ftdi);

///
/// \brief Close the FTDI device
///
/// \param ftdi pointer to ftdi_context
/// \return 0 on success
///
void bang(uint8_t pin_mask, struct ftdi_context *ftdi);

///
/// \brief Set the CBUS pins on the FTDI device
///
/// \param pin_mask Mask of the pins to set
/// \param ftdi pointer to ftdi_context
///
int read_decode_eeprom_serial(struct ftdi_context *ftdi, bool quiet);

///
/// \brief Read and decode the EEPROM serial number
///
/// \param ftdi pointer to ftdi_context
/// \param quiet bool to suppress output
/// \return 0 on success
///
int read_decode_eeprom(struct ftdi_context *ftdi);

///
/// \brief Read and decode the EEPROM
///
/// \param ftdi pointer to ftdi_context
/// \return 0 on success
///
void print_info(struct ftdi_context *ftdi);

#endif
