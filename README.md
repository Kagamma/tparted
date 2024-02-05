# tparted

TUI frontend for `parted`, an utility for creating, reorganizing, and deleting (for now) GPT disk partitions, based on Free Vision application framework.

The app is currently in beta state, thus critical bugs can occur at anytime.

Currently supported filesystems:

| | Create | Move | Resize | Label |
|-|-|-|-|-|
| ext2 | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| ext3 | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| ext4 | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| linux-swap | :heavy_check_mark: | | | |
| fat16 | :heavy_check_mark: | | | :heavy_check_mark: |
| fat32 | :heavy_check_mark: | | | :heavy_check_mark: |
| ntfs | :heavy_check_mark: | | | :heavy_check_mark: |
| btrfs | :heavy_check_mark: | | | | | |

## Install

#### Pre-build binary
- See `Releases` section.

#### Building from source
- Since the app requires Unicode version of Free Vision, you need to have Free Pascal 3.1.1 or later installed on the system.
- Run `make build` to build the app. The binary is located in `./bin` directory.
- Run `make install` to install the app to `/usr/bin`

## Dependencies
- `parted`
- `sfdisk` for Move operations.

![image](./docs/images/1.png)
