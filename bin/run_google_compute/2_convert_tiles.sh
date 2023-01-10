#!/bin/bash
cd "$(dirname "$0")"

set -ex

name="2023-01-eu"
tile_src="gs://opencloudtiles/mbtiles/$name.mbtiles"
tile_dst="gs://opencloudtiles/cloudtiles/$name.cloudtiles"

#machine_type="n2d-highcpu-2"     # 2 cores
#machine_type="n2d-highcpu-4"     # 4 cores
machine_type="n2d-highcpu-8"     # 8 cores
#machine_type="n2d-highcpu-16"    # 16 cores
#machine_type="n2d-highcpu-32"    # 32 cores
#machine_type="n2d-highcpu-48"    # 48 cores
#machine_type="n2d-highcpu-80"    # 80 cores
#machine_type="n2d-highcpu-96"    # 96 cores
#machine_type="n2d-highcpu-128"   # 128 cores
#machine_type="n2d-highcpu-224"   # 224 cores

# create VM from image
gcloud compute instances create opencloudtiles-converter \
	--image=opencloudtiles-converter \
	--machine-type=$machine_type \
	--scopes=storage-rw

# Wait till SSH is available
sleep 10
while ! gcloud compute ssh opencloudtiles-converter --command=ls
do
   echo "   SSL not available at VM, trying again..."
	sleep 5
done

# prepare command and run it via SSH
command="source .profile"
command="$command; gsutil cp $tile_src ."
command="$command; opencloudtiles convert --precompress brotli $(basename $tile_src) $(basename $tile_dst)"
command="$command; gsutil cp $(basename $tile_dst) $tile_dst"

gcloud compute ssh opencloudtiles-converter --command="$command" -- -t

gcloud compute instances stop opencloudtiles-converter --quiet

gcloud compute instances delete opencloudtiles-converter --quiet
