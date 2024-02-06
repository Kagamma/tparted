# tparted

TUI frontend for `parted`: A simple, user-friendly utility for creating, reorganizing, and deleting (for now) GPT disk partitions, based on Free Vision application framework.

The app is currently in beta state, thus bugs can occur.

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
- `dosfstools` for fat operations.
- `exfatprogs` for exfat operations.
- `e2fsprogs` for ext2/3/4 operations.
- `ntfs-3g` for ntfs operations.
- `btrfs-progs` for btrfs operations.
- `xfsprogs` for xfs operations.
- `util-linux` for linux-swap operations.

![image](./docs/images/1.png)
