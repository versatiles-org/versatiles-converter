#!/bin/bash
cd "$(dirname "$0")"


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


value=$(gcloud config get-value project)
if [ $value = "" ]; then
	echo "   ❗️ set a default project in gcloud, e.g.:"
	echo "   # gcloud config set project PROJECT_ID"
	echo "   ❗️ see also: https://cloud.google.com/artifact-registry/docs/repositories/gcloud-defaults#project"
	exit 1
else
	echo "   ✅ gcloud project: $value"
fi

value=$(gcloud config get-value compute/region)
if [ $value = "" ]; then
	echo "   ❗️ set a default compute/region in gcloud, e.g.:"
	echo "   # gcloud config set compute/region europe-west3"
	echo "   ❗️ see also: https://cloud.google.com/compute/docs/gcloud-compute#set_default_zone_and_region_in_your_local_client"
	exit 1
else
	echo "   ✅ gcloud compute/region: $value"
fi

value=$(gcloud config get-value compute/zone)
if [ $value = "" ]; then
	echo "   ❗️ set a default compute/zone in gcloud, e.g.:"
	echo "   # gcloud config set compute/zone europe-west3-c"
	echo "   ❗️ see also: https://cloud.google.com/compute/docs/gcloud-compute#set_default_zone_and_region_in_your_local_client"
	exit 1
else
	echo "   ✅ gcloud compute/zone: $value"
fi

value=$(gcloud compute instances describe opencloudtiles-converter 2>&1 > /dev/null)
if [ $? -eq 0 ]; then
	echo "   ❗️ opencloudtiles-converter machine already exist. Delete it:"
	echo "   # gcloud compute instances delete opencloudtiles-converter -q"
	exit 1
else
	echo "   ✅ gcloud instance free"
fi

value=$(gcloud compute images describe opencloudtiles-converter 2>&1 > /dev/null)
if [ $? -ne 0 ]; then
	echo "   ❗️ opencloudtiles-converter image does not exist. Create it:"
	echo "   # ./1_prepare_image.sh"
	exit 1
else
	echo "   ✅ gcloud image ready"
fi



set -ex

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
