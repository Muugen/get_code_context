#!/bin/bash

# This works for next.js projects currently
# Put this in your root folder of your project
# run the command chmod +x get_code_context.sh
# then run ./code_context.sh

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

# Get all directories in src and other specified directories
src_directories=($(find src -maxdepth 1 -type d -not -name "src" -printf "src/%P\n" 2>/dev/null))
root_directories=()
for dir in "public" "posts" "lancement" "lancements"; do
    if [ -d "$project_dir/$dir" ]; then
        root_directories+=("$dir")
    else
        echo "Note: Directory '$dir' not found in project root"
    fi
done
all_directories=("${src_directories[@]}" "${root_directories[@]}")
echo "All available directories: ${all_directories[*]}"

select_subdirectories() {
  local parent_dir="$1"
  local subdirs=($(find "$parent_dir" -maxdepth 1 -type d -not -name "$(basename "$parent_dir")" -printf "%P\n"))
  local options=("All" "${subdirs[@]}" "Finish selection" "Exit script")
  local selected=()
  local choice

  echo "Select subdirectories of $parent_dir to process:"
  while true; do
    select choice in "${options[@]}"; do
      case $choice in
        "All")
          selected=("${subdirs[@]}")
          return 0
          ;;
        "Finish selection")
          if [ ${#selected[@]} -eq 0 ]; then
            echo "No subdirectories selected. Please select at least one subdirectory or choose 'All'."
          else
            echo "Selected subdirectories: ${selected[*]}"
            return 0
          fi
          ;;
        "Exit script")
          echo "Exiting script."
          exit 0
          ;;
        *)
          if [[ " ${selected[*]} " =~ " ${choice} " ]]; then
            selected=(${selected[@]/$choice})
            echo "Removed $choice"
          else
            selected+=("$choice")
            echo "Added $choice"
          fi
          ;;
      esac
      break
    done
  done
}

select_directories() {
  local options=("All" "${all_directories[@]}" "Finish selection" "Exit script")
  local selected=()
  local choice

  while true; do
    echo "Select directories to process (or 'All' for all directories):"
    select choice in "${options[@]}"; do
      case $choice in
        "All")
          selected=("${all_directories[@]}")
          directories=("${selected[@]}")
          return 0
          ;;
        "Finish selection")
          if [ ${#selected[@]} -eq 0 ]; then
            echo "No directories selected. Please select at least one directory or choose 'All'."
          else
            echo "Selected directories: ${selected[*]}"
            directories=("${selected[@]}")
            return 0
          fi
          ;;
        "Exit script")
          echo "Exiting script."
          exit 0
          ;;
        *)
          if [[ "$choice" == "src/components" ]]; then
            local component_subdirs=()
            if ! select_subdirectories "${project_dir}/$choice"; then
              return 1
            fi
            for subdir in "${selected[@]}"; do
              component_subdirs+=("$choice/$subdir")
            done
            selected+=("${component_subdirs[@]}")
          elif [[ " ${selected[*]} " =~ " ${choice} " ]]; then
            selected=(${selected[@]/$choice})
            echo "Removed $choice"
          else
            selected+=("$choice")
            echo "Added $choice"
          fi
          ;;
      esac
      break
    done
  done
}

# Call the function to select directories
if ! select_directories; then
  echo "Script terminated."
  exit 1
fi

# List of file types to ignore
ignore_files=("*.ico" "*.png" "*.jpg" "*.jpeg" "*.gif" "*.svg" "*.zip" "*.txt" "*.json" "*.css" "*.jsx" "*.pdf" "*.csv")
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

# Process each selected directory
for dir in "${directories[@]}"; do
    full_dir="${project_dir}/${dir}"
    echo "Checking directory: ${full_dir}"
    if [ -d "$full_dir" ]; then
        echo "Processing directory: ${dir}"
        read_files "$full_dir"
    else
        echo "Directory not found: ${dir}"
        echo "Contents of ${project_dir}:"
        ls -la "${project_dir}"
    fi
done

echo "Script execution completed"

# Disable debugging
set +x