# APT Sources Configuration for Yocto

This directory contains the bitbake recipe and configuration files to include custom APT sources in your Yocto-built Ubuntu image.

## Files Structure

```
meta-astute/
├── conf/
│   └── layer.conf                          # Layer configuration
├── recipes-core/
│   ├── apt-sources/
│   │   ├── apt-sources_1.0.bb              # APT sources bitbake recipe
│   │   └── files/
│   │       ├── astute.list                 # APT repository configuration
│   │       ├── astute.gpg                  # GPG public key
│   │       └── apt.conf                    # APT configuration settings
│   └── motd/
│       ├── motd_1.0.bb                     # MOTD bitbake recipe
│       └── files/
│           ├── motd                        # BushNET banner template
│           └── update-motd.sh              # Dynamic MOTD updater script
└── recipes-graphics/
    └── wallpaper/
        ├── wallpaper_1.0.bb                # Wallpaper bitbake recipe
        ├── README.md                       # Wallpaper documentation
        └── files/
            └── Wallpaper.png               # BushNET desktop wallpaper (1536x1024)
```

## Configuration

### 1. Update APT Sources

Edit `files/astute.list` to include your actual repository URLs:

```bash
deb [signed-by=/etc/apt/trusted.gpg.d/astute.gpg] https://your-repo.com/ubuntu jammy main
deb-src [signed-by=/etc/apt/trusted.gpg.d/astute.gpg] https://your-repo.com/ubuntu jammy main
```

### 2. Add Your GPG Key

Replace `files/astute.gpg` with your actual GPG public key:

```bash
# Export your GPG key in armor format
gpg --armor --export YOUR_KEY_ID > files/astute.gpg

# Or in binary format
gpg --export YOUR_KEY_ID > files/astute.gpg
```

### 3. Build Configuration

The recipe is automatically included when you build your image. The APT sources will be installed to:

- `/etc/apt/sources.list.d/astute.list`
- `/etc/apt/trusted.gpg.d/astute.gpg`

## Usage in Built Image

After the image boots, you will see the BushNET MOTD banner with system information, and the BushNET wallpaper will be set as the desktop background.

### Wallpaper

The BushNET wallpaper (1536x1024) is installed to:

- `/usr/share/backgrounds/bushnet-wallpaper.png` - Standard backgrounds location
- `/usr/share/pixmaps/bushnet-wallpaper.png` - Standard pixmaps location

For Weston (Wayland compositor), the wallpaper is automatically configured in `/etc/xdg/weston/weston.ini`.

### APT Repository Usage

You can use the configured repositories:

```bash
# Update package lists
sudo apt update

# Install packages from your custom repository
sudo apt install your-custom-package
```

### MOTD Features

- **BushNET Banner**: Displays a prominent BushNET logo on login
- **System Information**: Shows OS version, kernel, architecture, and build date
- **Dynamic Updates**: MOTD automatically updates with current system information
- **Manual Update**: Run `sudo update-motd` to refresh system information

## Customization

To add more repositories or modify the configuration:

1. Edit `files/astute.list` to add more repository entries
2. Add additional GPG keys to the `files/` directory
3. Update the recipe to install additional key files if needed

## Testing

To verify the APT sources are correctly configured in your built image:

```bash
# Check sources list
cat /etc/apt/sources.list.d/astute.list

# Check GPG key
ls -la /etc/apt/trusted.gpg.d/

# Test repository access
sudo apt update
```
