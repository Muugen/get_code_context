# code context for AI chat bot
## This works for next.js projects currently

This is a script to get code context:
`get_code_cotext.sh`

This is a script to get the word count of the output file:
`word_char_count.sh`

# prerequirement
Install `jq` in your system :

```bash
sudo apt-get update
sudo apt-get install jq
```

## Put this in your root folder of your project
## Configuration file
### Edit the `project_config.json`

```json
{
  "root_directories": [],
  "ignore_patterns": [
    "*.ico",
    "*.png",
    "*.jpg",
    "*.jpeg",
    "*.gif",
    "*.svg",
    "*.zip",
    "*.pdf",
    "*.min.js"
  ],
  "specific_ignore_files": [],
  "output_format": "txt",
  "output_file": "get_code_context.txt"
}
```

### Add scripts & output to `.gitignore` file

```bash
project_config.json
code_context.sh
word_char_count.sh
get_code_context.txt
words_and_characters_count.txt
```

## RUN scripts

### before running :

```bash
chmod +x code_context.sh && chmod +x word_char_count.sh
```

### To run

```bash
./code_context.sh
```

```bash
./word_char_count.sh
```
