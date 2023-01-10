
# OpenCloudTiles - Converter

The Converter uses [opencloudtiles-tools](https://github.com/OpenCloudTiles/opencloudtiles-tools) to prepare the generated vector tiles (\*.mbtiles) for cloud deployment (\*.cloudtiles).

Every tile will be precompressed using maximum Brotli compression. This will use a lot of computing power, but opencloudtiles-tools runs very efficient in parallel using every core.

# files

Currently it uses Bash scripts:

## `bin/basic_scripts`

- `1_setup_debian.sh` prepares a debian system and installs rust

## `bin/run_google_compute`

scripts for tile conversion on a Google Compute VM.

- `1_prepare_image.sh` prepares a VM image (using `1_setup_debian.sh` ) that can be used for tile conversion
- `2_convert_tiles.sh` starts a VM (RAM is not important, but 16-32 cores are necessary), converts tiles using opencloudtiles-tools and uploads the result to Google Storage.
