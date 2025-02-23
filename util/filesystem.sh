create_clean_directory() {
    local DIR_NAME="$1"

    # Check if directory exists, then delete it
    if [ -d "$DIR_NAME" ]; then
        echo "Directory $DIR_NAME exists. Deleting..."
        rm -rf "$DIR_NAME"
    fi

    # Create new directory
    mkdir "$DIR_NAME"
    echo "Directory $DIR_NAME created successfully."
}
