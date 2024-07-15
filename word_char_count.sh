#!/bin/bash

# run the command chmod +x word_char_count.sh
# then run ./word_char_count.sh /path/to/your/file.txt

echo "Starting the script..."

# Check if the file path is provided as an argument
if [ $# -eq 0 ]; then
    echo "Error: Please provide the path to the .txt file as an argument."
    exit 1
fi

# Assign the file path to a variable
file_path=$1
echo "Input file path: $file_path"

# Check if the file exists
if [ ! -f "$file_path" ]; then
    echo "Error: File not found: $file_path"
    exit 1
fi

echo "File found. Proceeding with word and character count..."

# Count the number of words
word_count=$(wc -w < "$file_path")
echo "Word count completed."

# Count the number of characters
char_count=$(wc -c < "$file_path")
echo "Character count completed."

# Create the output file
output_file="words_and_characters_count.txt"
echo "Creating output file: $output_file"

# Write the results to the output file
echo "Word count: $word_count" > "$output_file"
echo "Character count: $char_count" >> "$output_file"
echo "Results written to $output_file"

echo "Script completed successfully."