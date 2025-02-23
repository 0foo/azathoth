#!/bin/bash

# Check if the user provided a directory argument
if [ -z "$1" ]; then
    echo -e "\e[31mError: Please provide a directory to search.\e[0m"
    echo "Usage: $0 /path/to/directory"
    exit 1
fi

# Root directory (passed as argument)
ROOT_DIR="$1"

# Function to extract a compressed file
extract_file() {
    local file="$1"
    local dir
    dir=$(dirname "$file")  # Get the directory of the file
    local base_name
    base_name=$(basename "$file")  # Get file name

    # Remove the extension to create an extraction folder
    local extracted_folder="${dir}/${base_name%.*}_extracted"

    # Create extraction folder
    mkdir -p "$extracted_folder"

    echo -e "\e[35mExtracting: $file → $extracted_folder\e[0m"

    # Extract file using 7z
    7z x -o"$extracted_folder" "$file" -y
}

# Find all files recursively and check MIME type
find "$ROOT_DIR" -type f | while read -r file; do
    mime_type=$(file --mime-type -b "$file")

    # Check if the MIME type is a known compressed format
    if [[ "$mime_type" =~ application/gzip|application/x-bzip2|application/x-xz|application/x-tar|application/zip|application/x-7z-compressed|application/x-rar ]]; then
        extract_file "$file"
    fi
done

echo -e "\e[32mExtraction completed!\e[0m"
