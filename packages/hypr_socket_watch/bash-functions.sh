#!bin/sh

extract_after_double_arrow() {
	local input_string="$1"
	local result="${input_string##*>}"
	echo "$result"
}

nth_file() {
	# Check for the correct number of arguments
	if [ $# -ne 2 ]; then
		echo "Usage: $0 <directory> <n>"
		exit 1
	fi

	directory="$1"
	n="$2"

	# Check if the directory exists
	if [ ! -d "$directory" ]; then
		echo "Error: Directory '$directory' does not exist."
		exit 1
	fi

	# List files in the directory, sort them, and grab the nth file
	file=$(ls "$directory" | sort | sed -n "${n}p")

	if [ -n "$file" ]; then
		full_path="$directory/$file"
		echo "$full_path"
	else
		echo "Error: Not enough files in '$directory' to find the ${n}th file."
	fi
}
