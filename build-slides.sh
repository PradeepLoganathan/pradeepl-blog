#!/bin/bash

# Ensure Marp CLI is installed (Modify if you installed it differently) 
if ! command -v marp &> /dev/null
then
    echo "Marp CLI could not be found. Please install it"
    exit 1
fi

# Iterate through Markdown files in content/slides
for presentation_dir in content/slides/*/
do
    presentation_name=$(basename "$presentation_dir") 
    echo "presentation name -- "$presentation_name
    output_dir="static/slides/$presentation_name" 

    # Create output directory if needed
    mkdir -p "$output_dir"

    # Build presentation
    marp "$presentation_dir/index.md" -o "$output_dir/index.html" 

    # Check for images and copy 
    images_dir="$presentation_dir"images
    echo "images directory is -- "$images_dir
    if [ -n "$(find "$images_dir" -maxdepth 1 -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif'  -o -iname '*.svg' )" ] 
    then
        images_output="$output_dir/images" # Target images folder
        echo "images_output is "$images_output
        mkdir -p "$images_output"  # Create the 'images' folder if needed
        cp "$images_dir"/*.{jpg,jpeg,png,gif,svg} "$images_output"  # Copy to target
    fi
   
done

echo "Slides built successfully!"