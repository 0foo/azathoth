#!/bin/bash

# Check if both parameters are provided
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <directory> <output_file>"
    exit 1
fi

# Assign parameters
DIR="$1"
OUTPUT_FILE="$2"

# Ensure the provided directory exists
if [ ! -d "$DIR" ]; then
    echo "Error: Directory '$DIR' does not exist."
    exit 1
fi

# Clear or create the output file
> "$OUTPUT_FILE"

# Function to iterate through directories and concatenate files
function cat_files() {
    for file in "$1"/*; do
        if [ -d "$file" ]; then
            # If it's a directory, recursively call the function
            cat_files "$file"
        elif [ -f "$file" ]; then
            # Append file name and content to the output file
            echo "===== $file =====" >> "$OUTPUT_FILE"
            cat "$file" >> "$OUTPUT_FILE"
            echo -e "\n" >> "$OUTPUT_FILE"
        fi
    done
}

# Start recursive function
cat_files "$DIR"

echo "All files have been concatenated into $OUTPUT_FILE"
