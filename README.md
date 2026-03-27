[![GitHub License](https://img.shields.io/github/license/Kagamma/tparted)](https://github.com/Kagamma/tparted/blob/main/LICENSE)
[![GitHub Release](https://img.shields.io/github/v/release/Kagamma/tparted)](https://github.com/Kagamma/tparted/releases)
[![Total Downloads](https://img.shields.io/github/downloads/Kagamma/tparted/total)](https://github.com/Kagamma/tparted/releases)

# tparted

https://github.com/user-attachments/assets/8bdd2978-5892-4505-8226-1ac3b5465b3c

TUI frontend for `parted`: A simple, user-friendly utility for creating, moving, resizing, and deleting disk partitions, based on Free Vision application framework.

MBR is partially supported, as long as no extended partition found on the device.

Currently supported filesystems:

| | Create | Move | Shrink | Grow | Label |
|-|-|-|-|-|-|
| bcachefs | :heavy_check_mark: | :heavy_check_mark: | | :heavy_check_mark:* | |
| btrfs | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark:* | :heavy_check_mark:* | :heavy_check_mark: |
| ext2 | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| ext3 | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| ext4 | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| exfat | :heavy_check_mark: | :heavy_check_mark: | | | :heavy_check_mark: |
| f2fs | :heavy_check_mark: | :heavy_check_mark: | | :heavy_check_mark: | :heavy_check_mark: |
| fat16 | :heavy_check_mark: | :heavy_check_mark: | | | :heavy_check_mark: |
| fat32 | :heavy_check_mark: | :heavy_check_mark: | | | :heavy_check_mark: |
| jfs | :heavy_check_mark: | :heavy_check_mark: | | :heavy_check_mark: | :heavy_check_mark: |
| linux-swap | :heavy_check_mark: | :heavy_check_mark: | | | |
| luks | :heavy_check_mark: | | | | |
| nilfs2 | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| ntfs | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| xfs | :heavy_check_mark: | :heavy_check_mark: | | :heavy_check_mark: | :heavy_check_mark: |

*In case of btrfs and bcachefs, for now the app doesn't deal with multi disk array.

*The app does not support full disk encryption/decryption at the moment.

## Install

#### Pre-built binary
- See `Releases` section.

#### Archlinux User Repository (AUR)
- For unicode version: Run `git clone https://aur.archlinux.org/tparted-bin.git`, then enter `tparted-bin` directory and run `makepkg -si`
- For ShortString/non-unicode version: Run `git clone https://aur.archlinux.org/tparted-git.git`, then enter `tparted-git` directory and run `makepkg -si`

#### Building from source
- For unicode version:
  + Requires Free Pascal (beta 3.3.1) or later beta version installed on the system.
- For ShortString version:
  + Officially support for Free Pascal 3.2.2 and newer, although older versions should work.
- By default unicode version will be built automatically if it detects fpc 3.3.1 on the system.
- Run `make build` to build the app. The binary is located in `./bin` directory.
- Run `make install` to install the app to `/usr/local/bin`

#### Translation
- The unicode version of the app is capable of loading translation files in `.mo` format. Simply translate the default `en_US.po` file to your language of choice, convert it to the `.mo` format via `msgfmt` tool, then place the converted file into the `./bin/locale` directory.
- The app depends on the `LANG` environment variable to determine the language. For example, the app will try to load `ja_JP.mo` or `ja.mo` if `LANG=ja_JP.UTF-8`.

## Dependencies
- `parted`
- `util-linux`
- `cryptsetup` (optional) for decrypting LUKS partitions.
- `sfdisk` (optional) for moving partitions.
- `dosfstools` (optional) for fat operations.
- `exfatprogs` (optional) for exfat operations.
- `e2fsprogs` (optional) for ext2/3/4 operations.
- `ntfs-3g` (optional) for ntfs operations.
- `nilfs-utils` (optional) for nilfs2 operations.
- `btrfs-progs` (optional) for btrfs operations.
- `xfsprogs` (optional) for xfs operations.
- `jfsutils` (optional) for jfs operations.
- `f2fs-tools` (optional) for f2fs operations.
- `bcachefs-tools` (optional) for bcachefs operations.
