#!/bin/bash

# Script to clean Windows line endings from all files in the Script folder

SCRIPT_DIR="./"

# Check if the directory exists
if [ ! -d "$SCRIPT_DIR" ]; then
    echo "Error: Directory '$SCRIPT_DIR' not found."
    exit 1
fi

# Find all files in the directory and clean line endings
find "$SCRIPT_DIR" -type f -exec sed -i 's/\r$//' {} +

echo "Cleaned Windows line endings from all files in '$SCRIPT_DIR'."

# Clean the .env file in the parent folder
if [ -f "../.env" ]; then
    sed -i 's/\r$//' "../.env"
    echo "Cleaned Windows line endings from '../.env'."
else
    echo "Warning: '../.env' not found."
fi