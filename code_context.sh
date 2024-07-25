#!/bin/bash

# This works for next.js projects currently
# Put this in your root folder of your project
# run the command chmod +x get_code_context.sh
# then run ./code_context.sh

# Enable debugging
set -x

# Use the current directory as the project directory
project_dir=$(pwd)
echo "Project directory: $project_dir"

# Use a fixed name for the output file in the current directory
output_file="${project_dir}/code_context.txt"
echo "Output file: $output_file"

# Check if the output file exists and remove it if it does
if [ -f "$output_file" ]; then
  echo "Removing existing output file"
  rm "$output_file"
fi

# Check if src directory exists
if [ ! -d "${project_dir}/src" ]; then
  echo "Error: src directory not found in ${project_dir}"
  exit 1
fi

# Get all directories in src, excluding specific ones
directories=($(find src -maxdepth 1 -type d -not -name "assets" -not -name "data" -not -name "helpers" -not -name "icons" -not -name "static" -not -name "src" -not -name "lib" -not -name "schemas" -printf "%P\n"))
echo "Directories to search: ${directories[*]}"

# List of file types to ignore
ignore_files=("*.ico" "*.png" "*.jpg" "*.jpeg" "*.gif" "*.svg" "*.zip" "*.txt" "*.json" "*.css" "*.jsx")
echo "File types to ignore: ${ignore_files[*]}"

# Specific files to ignore
specific_ignore_files=(
  "src/components/ui/Icons.tsx"
  "src/components/ui/dropdown-menu.tsx"
  "src/app/(pages)/cgu/page.tsx"
)
echo "Specific files to ignore: ${specific_ignore_files[*]}"

# Recursive function to read files and append their content
read_files() {
  local dir="$1"
  echo "Searching directory: $dir"
  for entry in "$dir"/*
  do
    if [ -d "$entry" ]; then
        # If entry is a directory, call this function recursively
        read_files "$entry"
    elif [ -f "$entry" ]; then
      should_ignore=false
      relative_path=${entry#"$project_dir/"}

      # Check if the file is one of the specific files to ignore
      for specific_file in "${specific_ignore_files[@]}"; do
        if [[ "$relative_path" == "$specific_file" ]]; then
          should_ignore=true
          echo "Ignoring specific file: $relative_path"
          break
        fi
      done

      # If not a specific file to ignore, check against ignore patterns
      if ! $should_ignore; then
        for ignore_pattern in "${ignore_files[@]}"; do
          if [[ "$entry" == $ignore_pattern ]]; then
            should_ignore=true
            echo "Ignoring file: $entry"
            break
          fi
        done
      fi

      # If the file should not be ignored, append its relative path and content to the output file
      if ! $should_ignore; then
        echo "Processing file: $relative_path"
        echo "// File: $relative_path" >> "$output_file"
        cat "$entry" >> "$output_file"
        echo "" >> "$output_file"
      fi
    fi
  done
}

# Call the recursive function for each specified directory in the project directory
for dir in "${directories[@]}"; do
  full_dir="${project_dir}/src/${dir}"
  if [ -d "$full_dir" ]; then
    echo "Processing directory: src/${dir}"
    read_files "$full_dir"
  else
    echo "Directory not found: src/${dir}"
  fi
done

echo "Script execution completed"

# Disable debugging
set +x
