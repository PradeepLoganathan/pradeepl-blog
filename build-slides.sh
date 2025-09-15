#!/bin/bash

echo "🔍 Checking if Marp CLI is installed..."
if ! command -v marp &> /dev/null; then
    echo "❌ Marp CLI not found! Install it using: npm install -g @marp-team/marp-cli"
    exit 1
fi
echo "✅ Marp CLI found."

echo "🔄 Starting Marp slide generation..."
echo "------------------------------------------"

# Loop through each slide folder inside content/marp-slides/
for folder in content/marp-slides/*/; do
    slide_name=$(basename "$folder")

    echo "📂 Processing slide: $slide_name"
    echo "   - Source folder: $folder"

    # Ensure the slide file exists
    slide_file="$folder/index.md"
    if [ ! -f "$slide_file" ]; then
        echo "   ⚠️  Warning: No index.md file found for $slide_name. Skipping..."
        continue
    fi

    # Create the output folder inside content/slides/
    output_folder="content/slides/$slide_name"
    mkdir -p "$output_folder/images"

    echo "   ✅ Created output directory: $output_folder"

    # Convert Markdown to HTML inside the output folder
    html_output="$output_folder/index.html"
    echo "   📝 Converting to HTML..."
    marp "$slide_file" --html -o "$html_output"
    if [ $? -eq 0 ]; then
        echo "   ✅ HTML slide generated: $html_output"
    else
        echo "   ❌ Failed to generate HTML for $slide_name"
    fi

    # Copy images if they exist
    image_src="$folder/images"
    image_dest="$output_folder/images"
    if [ -d "$image_src" ]; then
        echo "   🖼️  Copying images from $image_src to $image_dest..."
        rsync -av --progress "$image_src/" "$image_dest/"
        echo "   ✅ Images copied."
    else
        echo "   ⚠️  No images folder found for $slide_name. Skipping image copy."
    fi

    echo "------------------------------------------"
done

echo "🎉 ✅ All slides processed successfully!"
