
# versatiles - Converter

This is a collection of scripts to prepare map tiles (\*.mbtiles) for cloud deployment (\*.versatiles) using the [versatiles rust crate](https://github.com/versatiles-org/versatiles).

# files

## `bin/run_google_compute/`

converting tiles on Google Compute Engines.

- `1_prepare_image.sh`
  - start an engine
  - update debian
  - install the versatiles crate
  - save disk as VM image
- `2_convert_tiles.sh`
  - start the VM from image
  - download ?.mbtiles from Google Cloud Storage into a RAM disk
  - convert to ?.versatiles using versatiles crate
  - uploads ?.versatiles back to Google Cloud Storage
  - shut down and delete VM
