#!/bin/bash

# Check if an image name was provided
if [ -z "$1" ]; then
    echo "Usage: $0 <image-name>"
    exit 1
fi

IMAGE="$1"

# Remove the image from kind-control-plane containerd
echo "✅Removing image: $IMAGE"
docker exec kind-control-plane ctr -n=k8s.io images rm "$IMAGE"


REMOVE_STATUS=$?

if [ $REMOVE_STATUS -eq 0 ]; then
    echo "✅ Successfully removed image: $IMAGE"
else
    echo "❌ Failed to remove image: $IMAGE"
    exit $REMOVE_STATUS
fi

sleep 2

# List remaining images
echo "Listing remaining images in kind-control-plane:"
docker exec kind-control-plane ctr -n=k8s.io images list