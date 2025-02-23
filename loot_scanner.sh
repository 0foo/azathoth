# dependencies: sudo apt install p7zip ripgrep

SCRIPT_DIR="$(cd "$(dirname "$BASH_SOURCE")" && pwd)"
# Directory to search
DIR=$1
# Search pattern
PATTERN="username|password|pass|user|email|pwd|usr"


echo -e "\n\n--------------- Searching Plaintext Files ---------------"
rg -i $PATTERN --hidden --no-ignore-parent --ignore-file "$SCRIPT_DIR/.gitignore" $1



echo -e "\n\n--------------- Searching Compressed Files ---------------"
# Function to search inside files using 7z extraction
search_file() {
    local file="$1"
    local mime_type
    mime_type=$(file --mime-type -b "$file")

    # Only process supported compressed files
    if [[ "$mime_type" =~ application/gzip|application/x-bzip2|application/x-xz|application/x-tar|application/zip|application/x-7z-compressed|application/x-rar ]]; then

        echo -e "\e[35m$file\e[0m"

        # Attempt extraction and search using 7z
        7z e -so "$file"  |  stdbuf -oL grep -a -i --color -Hn -E "$PATTERN" 
    fi
}

# Iterate over all files in the directory recursively
find "$DIR" -type f | while read -r file; do
    search_file "$file"
done


