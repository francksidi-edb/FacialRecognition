#!/bin/bash

# The directory containing the images
SOURCE_DIR="./img_align_celeba" # Replace "./images" with your actual directory path

# Base name for target directories
TARGET_DIR_BASE="./image_group"

# Max images per directory
MAX_IMAGES=250

# Counter for images and directories
img_count=0
dir_count=1

# Create the first directory
mkdir -p "${TARGET_DIR_BASE}_${dir_count}"

# Loop through all images in the source directory
for img in "${SOURCE_DIR}"/*; do
  # Move image to the current target directory
  mv "$img" "${TARGET_DIR_BASE}_${dir_count}/"

  # Increment image counter
  ((img_count++))

  # Check if we reached the max images for this directory
  if [ "$img_count" -ge "$MAX_IMAGES" ]; then
    # Reset image counter and increment directory counter
    img_count=0
    ((dir_count++))

    # Create next target directory
    mkdir -p "${TARGET_DIR_BASE}_${dir_count}"
  fi
done

echo "Distribution complete."
