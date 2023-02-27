#!/usr/bin/env bash

echo "   👷 fetch files"

files=$(gcloud storage ls gs://versatiles/download/mbtiles | sed 's/.*\///g' | sed 's/\..*//g' | sed '/^$/d' | sort)
IFS=$'\n'
files=($files)
COLUMNS=1
echo "   please select a file:"
select name in "${files[@]}"; do
	break;
done

echo "   👷 fetch \"$name\" metadata"

tile_src="gs://versatiles/download/mbtiles/$name.mbtiles"
tile_dst="gs://versatiles/download/versatiles/$name.versatiles"

file_size=$(gcloud storage ls -L $tile_src | grep "Content-Length" | sed 's/^.*: *//')

if ! [[ $file_size =~ ^[0-9]{5,}$ ]]; then
   echo "   ❗️ file_size '$file_size' is not a number, maybe '$tile_src' does not exist?"
	exit 1
else
	echo "   ✅ file exists: $tile_src"
fi

ram_disk_size=$(perl -E "use POSIX;say ceil($file_size/1073741824 + 0.3)")
cpu_count=$(perl -E "use POSIX; use List::Util qw(max); say 2 ** max(2, ceil(log($ram_disk_size+2)/log(2)) - 3)")
machine_type="n2d-highmem-$cpu_count"

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

value=$(gcloud compute instances describe versatiles-converter 2>&1 > /dev/null)
if [ $? -eq 0 ]; then
	echo "   ❗️ versatiles-converter machine already exist. Delete it:"
	echo "   # gcloud compute instances delete versatiles-converter -q"
	exit 1
else
	echo "   ✅ gcloud instance free"
fi

value=$(gcloud compute images describe versatiles-converter 2>&1 > /dev/null)
if [ $? -ne 0 ]; then
	echo "   ❗️ versatiles-converter image does not exist. Create it:"
	echo "   # ./1_prepare_image.sh"
	exit 1
else
	echo "   ✅ gcloud image ready"
fi



# create VM from image
gcloud compute instances create versatiles-converter \
	--image=versatiles-converter \
	--machine-type=$machine_type \
	--scopes=storage-rw

# Wait till SSH is available
sleep 10
while ! gcloud compute ssh versatiles-converter --command=ls
do
   echo "   SSL not available at VM, trying again..."
	sleep 5
done

# prepare command and run it via SSH
file_src=$(basename $tile_src)
file_dst=$(basename $tile_dst)

gcloud compute ssh versatiles-converter --command="
source .profile
mkdir ramdisk
sudo mount -t tmpfs -o size=${ram_disk_size}G ramdisk ramdisk
gcloud storage cp $tile_src ramdisk/$file_src
versatiles convert ramdisk/$file_src $file_dst
gcloud storage cp $file_dst $tile_dst
" -- -t

# Stop and delete
gcloud compute instances stop versatiles-converter --quiet
gcloud compute instances delete versatiles-converter --quiet
