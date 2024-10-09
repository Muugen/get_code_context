#!/bin/bash

# This works for next.js projects currently
# Put this in your root folder of your project
# run the command chmod +x get_code_context.sh
# then run ./get_code_context.sh

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Use the current directory as the project directory
project_dir=$(pwd)
echo -e "${BLUE}Project directory:${NC} $project_dir"

# Use a fixed name for the output file in the current directory
output_file="${project_dir}/get_code_context.txt"
echo -e "${BLUE}Output file:${NC} $output_file"

# Check if the output file exists and remove it if it does
if [ -f "$output_file" ]; then
  echo -e "${YELLOW}Removing existing output file${NC}"
  rm "$output_file"
fi

# Get all directories in src and other specified directories
src_directories=($(find src -maxdepth 1 -type d -not -name "src" -printf "src/%P\n" 2>/dev/null))
root_directories=()
for dir in "public" "posts" "lancement" "lancements"; do
    if [ -d "$project_dir/$dir" ]; then
        root_directories+=("$dir")
    else
        echo -e "${YELLOW}Note: Directory '$dir' not found in project root${NC}"
    fi
done
all_directories=("${src_directories[@]}" "${root_directories[@]}")
echo -e "${BLUE}All available directories:${NC} ${all_directories[*]}"

# Function to display menu with highlighted numbers
display_menu() {
    local options=("$@")
    for i in "${!options[@]}"; do
        printf "${WHITE}%3d)${NC} %s\n" $((i+1)) "${options[i]}"
    done
}

select_subdirectories() {
  local parent_dir="$1"
  local subdirs=($(find "$parent_dir" -maxdepth 1 -type d -not -name "$(basename "$parent_dir")" -printf "%P\n"))
  local options=("All" "${subdirs[@]}" "Finish selection" "Exit script")
  local selected=()
  local choice

  echo -e "${CYAN}Select subdirectories of $parent_dir to process:${NC}"
  while true; do
    display_menu "${options[@]}"
    read -p "Enter your choice: " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
      choice="${options[$((choice-1))]}"
      case $choice in
        "All")
          selected=("${subdirs[@]}")
          return 0
          ;;
        "Finish selection")
          if [ ${#selected[@]} -eq 0 ]; then
            echo -e "${YELLOW}No subdirectories selected. Please select at least one subdirectory or choose 'All'.${NC}"
          else
            echo -e "${GREEN}Selected subdirectories: ${selected[*]}${NC}"
            return 0
          fi
          ;;
        "Exit script")
          echo -e "${RED}Exiting script.${NC}"
          exit 0
          ;;
        *)
          if [[ " ${selected[*]} " =~ " ${choice} " ]]; then
            selected=(${selected[@]/$choice})
            echo -e "${YELLOW}Removed $choice${NC}"
          else
            selected+=("$choice")
            echo -e "${GREEN}Added $choice${NC}"
          fi
          ;;
      esac
    else
      echo -e "${RED}Invalid choice. Please try again.${NC}"
    fi
  done
}

select_directories() {
  local options=("All" "${all_directories[@]}" "Finish selection" "Exit script")
  local selected=()
  local choice

  while true; do
    echo -e "${CYAN}Select directories to process (or 'All' for all directories):${NC}"
    display_menu "${options[@]}"
    read -p "Enter your choice: " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
      choice="${options[$((choice-1))]}"
      case $choice in
        "All")
          selected=("${all_directories[@]}")
          directories=("${selected[@]}")
          return 0
          ;;
        "Finish selection")
          if [ ${#selected[@]} -eq 0 ]; then
            echo -e "${YELLOW}No directories selected. Please select at least one directory or choose 'All'.${NC}"
          else
            echo -e "${GREEN}Selected directories: ${selected[*]}${NC}"
            directories=("${selected[@]}")
            return 0
          fi
          ;;
        "Exit script")
          echo -e "${RED}Exiting script.${NC}"
          exit 0
          ;;
        *)
          if [[ "$choice" == "src/components" ]]; then
            selected+=("$choice")  # Add src/components itself
            echo -e "${GREEN}Added $choice${NC}"
            local component_subdirs=()
            if ! select_subdirectories "${project_dir}/$choice"; then
              return 1
            fi
            for subdir in "${selected[@]}"; do
              if [[ "$subdir" != "$choice" ]]; then
                component_subdirs+=("$choice/$subdir")
              fi
            done
            selected+=("${component_subdirs[@]}")
          elif [[ " ${selected[*]} " =~ " ${choice} " ]]; then
            selected=(${selected[@]/$choice})
            echo -e "${YELLOW}Removed $choice${NC}"
          else
            selected+=("$choice")
            echo -e "${GREEN}Added $choice${NC}"
          fi
          ;;
      esac
    else
      echo -e "${RED}Invalid choice. Please try again.${NC}"
    fi
  done
}

# List of file types to ignore
ignore_files=("*.ico" "*.png" "*.jpg" "*.jpeg" "*.gif" "*.svg" "*.zip" "*.txt" "*.json" "*.css" "*.pdf" "*.PDF" "*.csv")
echo -e "${BLUE}File types to ignore:${NC} ${ignore_files[*]}"

# Specific files and directories to ignore
specific_ignore_files=(
  # here
)
echo -e "${BLUE}Specific files and directories to ignore:${NC} ${specific_ignore_files[*]}"

# Recursive function to read files and append their content
read_files() {
  local dir="$1"
  echo -e "${CYAN}Searching directory: $dir${NC}"
  for entry in "$dir"/*
  do
    if [ -d "$entry" ]; then
        # Check if the directory should be ignored
        relative_dir=${entry#"$project_dir/"}
        if [[ " ${specific_ignore_files[@]} " =~ " ${relative_dir} " ]]; then
            echo -e "${YELLOW}Ignoring directory: $relative_dir${NC}"
            continue
        fi
        read_files "$entry"
    elif [ -f "$entry" ]; then
      should_ignore=false
      relative_path=${entry#"$project_dir/"}

      # Check if the file is one of the specific files to ignore
      for specific_file in "${specific_ignore_files[@]}"; do
        if [[ "$relative_path" == "$specific_file" || "$relative_path" == $specific_file/* ]]; then
          should_ignore=true
          echo -e "${YELLOW}Ignoring specific file or directory: $relative_path${NC}"
          break
        fi
      done

      # If not a specific file to ignore, check against ignore patterns
      if ! $should_ignore; then
        for ignore_pattern in "${ignore_files[@]}"; do
          if [[ "$entry" == $ignore_pattern ]]; then
            should_ignore=true
            echo -e "${YELLOW}Ignoring file: $entry${NC}"
            break
          fi
        done
      fi

      # If the file should not be ignored, append its relative path and content to the output file
      if ! $should_ignore; then
        echo -e "${GREEN}Processing file: $relative_path${NC}"
        echo "// File: $relative_path" >> "$output_file"
        cat "$entry" >> "$output_file"
        echo "" >> "$output_file"
      fi
    fi
  done
}

# Call the function to select directories
if ! select_directories; then
  echo -e "${RED}Script terminated.${NC}"
  exit 1
fi

# Debug output to verify selected directories
echo -e "${MAGENTA}Directories to process:${NC}"
for dir in "${directories[@]}"; do
  echo -e "${MAGENTA} - $dir${NC}"
done

# Process each selected directory
for dir in "${directories[@]}"; do
    # Correct the directory name if it's the lancement subdirectory
    if [[ "$dir" == "src/components/lancements" ]]; then
        dir="src/components/lancement"
    fi
    
    full_dir="${project_dir}/${dir}"
    echo -e "${CYAN}Checking directory: ${full_dir}${NC}"
    if [ -d "$full_dir" ]; then
        echo -e "${GREEN}Processing directory: ${dir}${NC}"
        read_files "$full_dir"
    else
        echo -e "${RED}Directory not found: ${dir}${NC}"
        echo -e "${YELLOW}Contents of ${project_dir}/src/components:${NC}"
        ls -la "${project_dir}/src/components"
    fi
done

echo -e "${MAGENTA}Script execution completed${NC}"
