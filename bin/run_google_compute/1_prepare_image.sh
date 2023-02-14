#!/usr/bin/env bash



##########################################
## CHECK GCLOUD CONFIGURATION           ##
##########################################

value=$(gcloud config get-value project)
if [[ $value = "" ]]; then
	echo "   ❗️ set a default project in gcloud, e.g.:"
	echo "   # gcloud config set project PROJECT_ID"
	echo "   ❗️ see also: https://cloud.google.com/artifact-registry/docs/repositories/gcloud-defaults#project"
	exit 1
else
	echo "   ✅ gcloud project: $value"
fi

value=$(gcloud config get-value compute/region)
if [[ $value = "" ]]; then
	echo "   ❗️ set a default compute/region in gcloud, e.g.:"
	echo "   # gcloud config set compute/region europe-west3"
	echo "   ❗️ see also: https://cloud.google.com/compute/docs/gcloud-compute#set_default_zone_and_region_in_your_local_client"
	exit 1
else
	echo "   ✅ gcloud compute/region: $value"
fi

value=$(gcloud config get-value compute/zone)
if [[ $value = "" ]]; then
	echo "   ❗️ set a default compute/zone in gcloud, e.g.:"
	echo "   # gcloud config set compute/zone europe-west3-c"
	echo "   ❗️ see also: https://cloud.google.com/compute/docs/gcloud-compute#set_default_zone_and_region_in_your_local_client"
	exit 1
else
	echo "   ✅ gcloud compute/zone: $value"
fi

while true; do
	gcloud compute instances describe versatiles-converter &> /dev/null
	if [ $? -eq 0 ]; then
		echo "   ❗️ versatiles-converter machine already exist. Delete it?"
		select yn in "Yes" "No"; do
			case $yn in
				Yes)
					echo "   👷 deleting machine ..."
					gcloud compute instances delete versatiles-converter -q;
					break;;
				No) exit;;
			esac
		done
	else
		echo "   ✅ gcloud instance free"
		break
	fi
done

while true; do
	gcloud compute images describe versatiles-converter &> /dev/null
	if [ $? -eq 0 ]; then
		echo "   ❗️ versatiles-converter image already exist. Delete it?"
		select yn in "Yes" "No"; do
			case $yn in
				Yes)
					echo "   👷 deleting image ..."
					gcloud compute images delete versatiles-converter -q;
					break;;
				No) exit;;
			esac
		done
	else
		echo "   ✅ gcloud image free"
		break
	fi
done



##########################################
## BUILD VM                             ##
##########################################

# Create VM
gcloud compute instances create versatiles-converter \
	--image-project=debian-cloud \
	--image-family=debian-11 \
	--boot-disk-size=300GB \
	--machine-type=n2d-highcpu-2

# Wait till SSH is available
sleep 10
while ! gcloud compute ssh versatiles-converter --command=ls
do
   echo "   SSL not available at VM, trying again..."
	sleep 5
done

# Setup machine
gcloud compute ssh versatiles-converter --command="
sudo apt-get -q update
sudo apt-get -q install -y build-essential git wget unzip tmux htop aria2 sysstat brotli cmake ifstat libsqlite3-dev openssl libssl-dev pkg-config
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source \"\$HOME/.cargo/env\"
cargo install versatiles
sudo shutdown -P now
" -- -t || true



##########################################
## GENERATE IMAGE                       ##
##########################################

# Generate image
gcloud compute images create versatiles-converter --source-disk=versatiles-converter

# Delete Instance
gcloud compute instances delete versatiles-converter --quiet
