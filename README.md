# tparted

TUI frontend for `parted`, an utility for creating, reorganizing, and deleting (for now) GPT disk partitions, based on Free Vision application framework.

The app is currently in beta state, thus critical bugs can occur at anytime.

Currently supported filesystems:

| | Create | Move | Shrink | Grow | Label |
|-|-|-|-|-|-|
| btrfs | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| ext2 | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| ext3 | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| ext4 | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| exfat | :heavy_check_mark: | :heavy_check_mark: | | | :heavy_check_mark: |
| fat16 | :heavy_check_mark: | :heavy_check_mark: | | | :heavy_check_mark: |
| fat32 | :heavy_check_mark: | :heavy_check_mark: | | | :heavy_check_mark: |
| linux-swap | :heavy_check_mark: | :heavy_check_mark: | | | |
| ntfs | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| xfs | :heavy_check_mark: | :heavy_check_mark: | | :heavy_check_mark: | :heavy_check_mark: |

## Install

#### Pre-built binary
- See `Releases` section.

#### Building from source
- Since the app requires Unicode version of Free Vision, you need to have Free Pascal 3.1.1 or later installed on the system.
- Run `make build` to build the app. The binary is located in `./bin` directory.
- Run `make install` to install the app to `/usr/bin`

## Dependencies
- `parted`
- `sfdisk` for moving partitions.
- `mkfs`
- `resize2fs` for resizing ext2/3/4 partitions.
- `ntfs-utils` for resizing ntfs partitions.
- `btrfs-utils` for labeling & resizing btrfs partitions.

![image](./docs/images/1.png)
