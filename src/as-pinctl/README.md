# as-pinctl

`as-pinctl` is a command-line utility for controlling and configuring GPIO pins and related hardware features on Astute Systems boards, including GXA-1 Jetson AGX Orin platforms. It is designed to interface with FTDI chips and provides flexible pin control for development, testing, and automation.

## Features

- Control GPIO pins via FTDI interface
- Set pin direction (input/output)
- Read and write pin states
- Support for pinmux and pad voltage configuration
- Command-line options for scripting and automation
- Integration with libftdi1 and gflags libraries

## Installation

### Build from Source

1. **Install Dependencies**

   ```bash
   sudo apt-get update
   sudo apt-get install -y cmake g++ libftdi1-dev libgflags-dev
   ```

2. **Build**

   ```bash
   mkdir -p build
   cd build
   cmake ..
   make as-pinctl
   ```

3. **Install**

   ```bash
   sudo make install
   ```

   The binary will be installed to `/usr/local/bin/as-pinctl` or the specified CMake install prefix.

### .deb Package

If you built with CPack, a `.deb` package will be available in the `build/` directory:

```bash
sudo dpkg -i build/as-pinctl-<version>-ubuntu-<version>.deb
```

## Usage

### Basic Commands

```bash
as-pinctl <command> [options]
```

#### Examples

- **Show version**

  ```bash
  as-pinctl -version
  ```

- **List available pins**

  ```bash
  as-pinctl --list
  ```

- **Set pin 5 as output and drive high**

  ```bash
  as-pinctl --set 5 --output --high
  ```

- **Read pin 7 state**

  ```bash
  as-pinctl --get 7
  ```

- **Configure pinmux**

  ```bash
  as-pinctl --pinmux <config-file>
  ```

- **Set pad voltage**

  ```bash
  as-pinctl --padvoltage <pin> <voltage>
  ```

## Command-Line Options

| Option         | Description                                                                                  |
|----------------|----------------------------------------------------------------------------------------------|
| `--info`       | Print all the device information and current state                                           |
| `--shutdown`   | Shutdown: assert reset (set CBUS pin 5 low)                                                 |
| `--startup`    | Startup: release reset (set CBUS pin 5 high)                                                |
| `--reboot`     | Reboot: assert reset then release reset (toggle CBUS pin 5 low/high)                        |
| `--quiet`      | Less output, print only raw values                                                          |
| `--serial`     | Print FTDI device serial number                                                             |
| `--recovery`   | Enable recovery mode (will reboot the device using CBUS pin 6 sequence)                     |
| `--read`       | Read the FTDI device EEPROM                                                                 |
| `--uart`       | Dump the UART data from the FTDI device                                                     |
| `--pin <n>`    | Specify FTDI CBUS pin value (0-7)                                                           |
| `--high`       | Set specified CBUS pin high                                                                 |

## Usage Examples

- **Show device info**

  ```bash
  sudo as-pinctl --info
  ```

- **Shutdown the device**

  ```bash
  sudo as-pinctl --shutdown
  ```

- **Startup the device**

  ```bash
  sudo as-pinctl --startup
  ```

- **Reboot the device**

  ```bash
  sudo as-pinctl --reboot
  ```

- **Enable recovery mode**

  ```bash
  sudo as-pinctl --recovery
  ```

- **Read FTDI EEPROM**

  ```bash
  sudo as-pinctl --read
  ```

- **Dump UART data**

  ```bash
  sudo as-pinctl --uart
  ```

- **Get FTDI serial number**

  ```bash
  sudo as-pinctl --serial
  ```

- **Set CBUS pin 5 high**

  ```bash
  sudo as-pinctl --pin 5 --high
  ```

- **Set CBUS pin 6 low**

  ```bash
  sudo as-pinctl --pin 6
  ```
  
## Development

- Source code is organized in:
    - `pinlib/` (library for pin control)
    - `pinctl.cc` (main utility source)
- Uses [libftdi1](https://www.intra2net.com/en/developer/libftdi/) for FTDI communication
- Uses [gflags](https://gflags.github.io/gflags/) for command-line parsing

## License

This project is licensed under the MIT License. See [LICENSE](../../LICENSE) for details.

## Support

For issues or feature requests, please open an issue in the repository or contact the maintainer.
