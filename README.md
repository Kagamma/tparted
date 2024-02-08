# tparted

TUI frontend for `parted`: A simple, user-friendly utility for creating, reorganizing, and deleting GPT disk partitions, based on Free Vision application framework.

Currently supported filesystems:

| | Create | Move | Shrink | Grow | Label |
|-|-|-|-|-|-|
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
| ntfs | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: | :heavy_check_mark: |
| xfs | :heavy_check_mark: | :heavy_check_mark: | | :heavy_check_mark: | :heavy_check_mark: |

*In case of btrfs, for now the app doesn't deal with multi disk array.

## Install

#### Pre-built binary
- See `Releases` section.

#### Building from source
- Since the app requires Unicode version of Free Vision, you need to have Free Pascal 3.1.1 or later installed on the system.
- Run `make build` to build the app. The binary is located in `./bin` directory.
- Run `make install` to install the app to `/usr/bin`

## Dependencies
- `parted`
- `util-linux`
- `sfdisk` (optional) for moving partitions.
- `dosfstools` (optional) for fat operations.
- `exfatprogs` (optional) for exfat operations.
- `e2fsprogs` (optional) for ext2/3/4 operations.
- `ntfs-3g` (optional) for ntfs operations.
- `btrfs-progs` (optional) for btrfs operations.
- `xfsprogs` (optional) for xfs operations.
- `jfsutils` (optional) for jfs operations.
- `f2fs-tools` (optional) for f2fs operations.

![image](./docs/images/1.png)
