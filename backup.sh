#!/bin/bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Summary description of the script:
# This is a test bash script to backup contents of one directory
# (source) into another (target). The full path of the directories
# is assigned to variables below. 

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Full path to the source directory (include / at the end).
# Note: do not include \ to escape spaces. Example: 
source_dir='/Users/YourName/Notes/'

# Full path to the target directory (include / at the end).
# Note: do not include \ to escape spaces. Example:
target_dir='/Users/YourName/Library/Mobile Documents/com~apple~CloudDocs/Notes/'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Declare array variables to hold directory structure of the source
# and target directories. The directory structure elements are files
# with their relative paths (excluding path to source/target).
declare -a source_dir_content
declare -a target_dir_content

# Declare array to hold list of files to be removed
declare -a files_to_remove

# Declare array to hold list of files to be copied
declare -a files_to_copy

# Declare array to hold list of files to be skipped
declare -a files_to_skip

# Declare helper variables
declare -i index    # to keep track of array index later

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set IFS (Internal Field Separator) to the new line character only.
# By default, this built-in Bash variable uses whitespace, tabs,
# and new lines as separators. This causes issues when dealing
# with Mac file naming convention that allows white spaces in 
# file names and directory names.  
IFS=$'\n'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Ask user to verify that source and target dirs are set correctly:
echo "- - - - - - - - - - - - - - - - - - - - - -"
echo "This program will back up contents of the Source directory"
echo "into the Target directory. Those directories are currently"
echo "set as follows:"
echo "Source: " $source_dir
echo "Target: " $target_dir
read -p "Proceed? [y/n]: " answer
if [ $answer = "y" ]; then
	# User has confirmed; proceed with the script.
	:
else
	echo "Process cancelled"
	exit
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Test the source and target directories for existance.
if [ -d $source_dir ]; then
	# Looks good; proceed with the script.
	:
else
	echo "Source directory does not exist or is not accessible."
	exit
fi
if [ -d $target_dir ]; then
	# Looks good; proceed with the script.
	:
else
	echo "Target directory does not exist or is not accessible."
	exit
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Populate array 'source_dir_content'.
# Note, -R is for getting subdirectories recursively and -p is for
# printing / at the end of a file if it's a directory.
# Below, I am running the output of the ls -Rp command through an if
# statement to separate files from other stuff the command returns,
# such as directories and sub directories.
prefix=""
for i in $(ls -Rp $source_dir | xargs -0 -n1); do
	if [[ $i =~ /$ ]]; then
		# Do nothing if element ends with / - its a dir
		: 
	elif [[ $i =~ ^/ ]]; then
		# If element starts with / then this is a sub dir.
		# Extract the part after // and save it in prefix.
		prefix=$(echo $i | sed 's|.*//||' | sed 's|:||')/
	else
		# None of the previous 2 conditions were met,
		# so this is a file; append it into source_dir.
		source_dir_content+=($prefix$i)
	fi
done

# Similarly, populate array 'target_dir_content'.
prefix=""
for i in $(ls -Rp $target_dir | xargs -0 -n1); do
	if [[ $i =~ /$ ]]; then
		# Do nothing if element ends with / -its a dir
		:
	elif [[ $i =~ ^/ ]]; then
		# If element starts with / then this is a sub dir.
		# Extract the part after // and save it in prefix.
		prefix=$(echo $i | sed 's|.*//||' | sed 's|:||')/
	else
		# None of the previous 2 conditions were met,
		# so this is a file; append it into source_dir.
		target_dir_content+=($prefix$i)
	fi
done

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# For testing only: print out results so far
# echo '- - - Contents of source dir - - -'
# for i in ${source_dir_content[@]}; do
# 	echo $i
# done
# echo '- - - Contents of target dir - - -'
# for i in ${target_dir_content[@]}; do
# 	echo $i
# done

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Compare contents of the dirs to determine files to be removed
index=0
for i in ${target_dir_content[@]}; do
	flag="remove"
	for j in ${source_dir_content[@]}; do
		if [ $i = $j ]; then
			flag="keep"
		fi
	done
	if [ $flag = "remove" ]; then
		files_to_remove+=($i)
		unset target_dir_content[$index]
	fi
	index+=1
done

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# For testing only: print out results
# echo '- - - Files to remove - - -'
# for i in ${files_to_remove[@]}; do
# 	echo $i
# done

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Determine which files should be copied from source to target dir.
# This will be based on two things: 
# 1) Whether the file exists in the target dir;
# 2) If exists, whether it is identical or has changed.

for i in ${source_dir_content[@]}; do
	exist_in_target="no"
	for j in ${target_dir_content[@]}; do
		if [ $i = $j ]; then
			exist_in_target="yes"
		fi
	done
	if [ $exist_in_target = "no" ]; then
		files_to_copy+=($i)
	else
		# Get mtime of source and target files and compare.
		source_info=$(stat -s $source_dir$i)
		source_mtime=$(echo $source_info | sed 's/.*\(st_mtime=\)\([0-9]*\).*/\2/')
		target_info=$(stat -s $target_dir$i)
		target_mtime=$(echo $target_info | sed 's/.*\(st_mtime=\)\([0-9]*\).*/\2/')
		if [ $source_mtime != $target_mtime ]; then
			# Files are different; mark for copying.
			files_to_copy+=($i)
		else
			# Files are the same; mark for skipping.
			files_to_skip+=($i)
		fi
	fi
done

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# For testing only: print out results.
# echo '- - - Files to copy - - -'
# for i in ${files_to_copy[@]}; do
# 	echo $i
# done
# echo '- - - Files to skip - - -'
# for i in ${files_to_skip[@]}; do
# 	echo $i
# done

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Delete files marked for removal from the target directory.
# If file deletion results in an empty dir, remove the dir too.
for i in ${files_to_remove[@]}; do
	rm $target_dir$i
	target_dir_ext=$target_dir$(echo $i | sed -n 's|\(.*/\)[^/]*|\1|p')
	if test $(ls $target_dir_ext); then
		# This dir is not empty; do nothing.
		:
	else
		# This dir is empty; delete it.
		rm -R $target_dir_ext
	fi
done

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Copy files marked for copying from the source to target dir.
# Option -p when copying is to preserve file attributes such as
# modification time, access time, permissions, etc.
# Option -p when creating directories is for creating parent
# directories automatically when needed.

for i in ${files_to_copy[@]}; do
	# Append target dir with any additional sub dirs to match
	# the source, excluding the file name at the end.
	target_dir_ext="$target_dir"$(echo "$i" | sed -n 's|\(.*/\)[^/]*|\1|p')
	# Test if the dir exists; if not, create it first.
	if [ -d $target_dir_ext ]; then
		# Dir exists; proceed with copying.
		cp -p $source_dir$i $target_dir_ext
	else
		# Dir does not exist; create it first then copy.
		mkdir -p $target_dir_ext
		cp -p $source_dir$i $target_dir_ext
	fi
done

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Generate summary report.
echo "- - - - - - - - - - - - - - - - - - - - - -"
echo "Backup completed successfully:"
echo "- - - - - - - - - - - - - - - - - - - - - -"
printf "Files inside source directory:   \t%s\n" ${#source_dir_content[@]}
printf "Files copied to backup directory:\t%s\n" ${#files_to_copy[@]}
printf "Files skipped (unchanged files): \t%s\n" ${#files_to_skip[@]}
printf "Files removed from backup:       \t%s\n" ${#files_to_remove[@]}
echo "- - - - - - - - - - - - - - - - - - - - - -"
