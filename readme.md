
# OpenCloudTiles - Converter

This is a collection of scripts to prepare map tiles (\*.mbtiles) for cloud deployment (\*.cloudtiles) using [opencloudtiles-tools](https://github.com/OpenCloudTiles/opencloudtiles-tools).

# files

## `bin/run_google_compute/`

converting tiles on Google Compute Engines.

- `1_prepare_image.sh`
  - start an engine
  - update debian
  - install opencloudtiles-tools
  - save disk as VM image
- `2_convert_tiles.sh`
  - start the VM from image
  - download ?.mbtiles from Google Cloud Storage into a RAM disk
  - convert to ?.cloudtiles using opencloudtiles-tools
  - uploads ?.cloudtiles back to Google Cloud Storage
  - shut down and delete VM
