#!/bin/bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# This is a test bash script to backup contents of one directory
# (source) into another (target). The full path of the directories
# is assigned to variables below. 

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Full path to the source directory (include / at the end).
# Note: do not include \ to escape spaces if your path contains them
source_dir='/Users/youraccount/test/'

# Full path to the target directory (include / at the end).
# Note: do not include \ to escape spaces if your path contains them
target_dir='/Users/youraccount/Library/Mobile Documents/com~apple~CloudDocs/test/'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Declare array variables to hold directory structure of the source
# and target directories. The directory structure elements are files
# with their relative paths (excluding path to source/target).
declare -a source_dir_files
declare -a target_dir_files

# Declare array variables to hold empty directories.
declare -a source_dir_empty
declare -a target_dir_empty

# Declare array to hold list of files to be removed in target
declare -a files_to_remove

# Declare array to hold list of files to be copied to target
declare -a files_to_copy

# Declare array to hold list of files to be checked for modification time
declare -a files_to_check

# Declare array to hold results of 'comm' command between source and target
declare -a diffs

# Declare array to hold list of files to be skipped
declare -a files_to_skip

# Declare array to hold list of empty dirs to be removed in target
declare -a dirs_to_remove

# Declare array to hold list of empty dirs to be created in target
declare -a dirs_to_create

# Declare helper variables
declare -i index     # to keep track of array index later
declare -i empty_dir # to flag empty directories

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set IFS (Internal Field Separator) to the new line character only.
# By default, this built-in Bash variable uses whitespace, tabs,
# and new lines as separators. This causes issues when dealing
# with Mac file naming convention that allows white spaces in 
# file names and directory names.  
IFS=$'\n'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Ask user to verify that source and target dirs are set correctly:
echo "- - - - - - - - - - - - - - - - - - - - - - -"
echo "This program will back up contents of the"
echo "Source directory into the Target directory."
echo "These directories are currently set to:"
echo "Source: " $source_dir
echo "Target: " $target_dir
echo "- - - - - - - - - - - - - - - - - - - - - - -"
read -p "Proceed? [y/n]: " answer
if [ $answer = "y" ]; then
	# User has confirmed; proceed with the script.
	:
else
	echo "Process cancelled."
	echo "- - - - - - - - - - - - - - - - - - - - - - -"
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

echo "- - - - - - - - - - - - - - - - - - - - - - -"
echo "Backup started. Please wait."
echo "Scanning the source directory...    $(date +'%H:%M:%S')"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Populate arrays source_dir_files and source_dir_empty.
# Note, -R is for getting subdirectories recursively, -p is for
# printing / at the end of a file if it's a directory, and -A is
# for getting all entries including the hidden ones like .DS_store 
# but excluding . and .. Below, I am running the output of the
# ls -RpA command through an if statement to separate files from other
# stuff the command returns, like directories and sub directories.
prefix=""
empty_dir=0
for i in $(ls -RpA $source_dir | xargs -0 -n1); do
	case $i in
		*/) 
			# Do nothing if element ends with / - its a dir
			empty_dir=0
			;;
		/*)
			# If element starts with / then this is a sub dir.
			# Extract the part after // and save it in prefix.
			if [ $empty_dir -eq 1 ]; then
				# This is an empty directory; append the last value
				# of prefix to source_dir_empty. Then save the current 
				# value as a prefix.
				source_dir_empty+=(${prefix:0:(${#prefix}-1)})
				prefix=$(echo $i | sed 's|.*//||' | sed 's|:||')/
			else
				# Non-empty directory; save it as a prefix.
				prefix=$(echo $i | sed 's|.*//||' | sed 's|:||')/
			fi
			empty_dir=1
			;;
		*)
			# None of the previous 2 conditions were met,
			# so this is a file; append it into source_dir.
			source_dir_files+=($prefix$i)
			empty_dir=0
		;;
	esac
done
# The following is needed to check the last record for 
# being an empty directory.
if [ $empty_dir -eq 1 ]; then
	source_dir_empty+=(${prefix:0:(${#prefix}-1)})
fi

echo "Scanning the target directory...    $(date +'%H:%M:%S')" 

# Similarly, populate arrays target_dir_files and target_dir_empty.
prefix=""
empty_dir=0
for i in $(ls -RpA $target_dir | xargs -0 -n1); do
	case $i in
		*/) 
			empty_dir=0
			;;
		/*)	
			if [ $empty_dir -eq 1 ]; then
				target_dir_empty+=(${prefix:0:(${#prefix}-1)})
				prefix=$(echo $i | sed 's|.*//||' | sed 's|:||')/
			else
				prefix=$(echo $i | sed 's|.*//||' | sed 's|:||')/
			fi
			empty_dir=1
			;;
		*)
			target_dir_files+=($prefix$i)
			empty_dir=0
		;;
	esac
done
if [ $empty_dir -eq 1 ]; then
	target_dir_empty+=(${prefix:0:(${#prefix}-1)})
fi
 
echo "Comparing source and target...      $(date +'%H:%M:%S')"

# The comm command compares the two lists and returns a 3-column result set:
# column 1: lines only in list 1, column 2: lines only in list 2, and column 3:
# lines in both lists. 
diffs=($(comm <(echo "${source_dir_files[*]}" | sort) <(echo "${target_dir_files[*]}" | sort)))
# Parse the 3-column list into 3 separate arrays. 
for i in ${diffs[@]}; do 
	if [[ $i =~ ^$'\t\t'.* ]]; then
		# This is column 3: files present in both source and target.   
		files_to_check+=($(echo $i | tr -d '\t'))
	elif [[ $i =~ ^$'\t'.* ]]; then
		# This is column 2: files present only in target. 
		files_to_remove+=($(echo $i | tr -d '\t'))
	else
		# This is column 1: files present only in source.
		files_to_copy+=($i)
	fi
done

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# For testing
# echo "Step 1 completed...                 $(date +'%H:%M:%S')"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Compare source and target to determine empty dirs to be removed.
for i in ${target_dir_empty[@]}; do
	flag="remove"
	for j in ${source_dir_empty[@]}; do
		if [ $i = $j ]; then
			flag="keep"
		fi
	done
	if [ $flag = "remove" ]; then
		dirs_to_remove+=($i)
	fi
done

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# For testing
# echo "Step 2 completed...                 $(date +'%H:%M:%S')"

# Sort out the files that are present in both source and target. 
# If both files are identical (have the same modification time), then
# mark it for skipping. If different, check whether the file is DS_Store
# which is a proprietory Apple file that stores information about the
# directory, and skip it if yes. Otherwise, mark it for copying. 

for i in ${files_to_check[@]}; do
	# Get mtime of source and target files and compare.
	source_info=$(stat -s $source_dir$i)
	source_mtime=$(echo $source_info | sed 's/.*\(st_mtime=\)\([0-9]*\).*/\2/')
	target_info=$(stat -s $target_dir$i)
	target_mtime=$(echo $target_info | sed 's/.*\(st_mtime=\)\([0-9]*\).*/\2/')
	if [[ $source_mtime != $target_mtime ]]; then
		# Files are different; mark for copying (unless file is .DS_Store)
		file_name=$(echo $i | sed 's|.*/||g' | tr 'A-Z' 'a-z')
		if [[ $file_name != ".ds_store" ]]; then
			# Mark for copying
			files_to_copy+=($i)
		else
			# Skip because this is .DS_store file
			files_to_skip+=($i)
		fi	
	else
		# Files are the same; mark for skipping
		files_to_skip+=($i)
	fi
done

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# For testing
# echo "Step 3 completed...                 $(date +'%H:%M:%S')"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Determine empty dirs to be created in target.
for i in ${source_dir_empty[@]}; do
	exist_in_target="no"
	for j in ${target_dir_empty[@]}; do
		if [ $i = $j ]; then
			exist_in_target="yes"
		fi
	done
	if [ $exist_in_target = "no" ]; then
		dirs_to_create+=($i)
	fi
done

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# For testing
# echo "Step 4 completed...                 $(date +'%H:%M:%S')"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# For testing
# Send results to an external file
# echo "- - - Contents of source dir files - - -" >> output.txt
# echo "${source_dir_files[*]}" >> output.txt
# echo "- - - Contents of source dir empty - - -" >> output.txt
# echo "${source_dir_empty[*]}" >> output.txt
# echo "- - - Contents of target dir files - - -" >> output.txt
# echo "${target_dir_files[*]}" >> output.txt
# echo "- - - Contents of target dir empty - - -" >> output.txt
# echo "${target_dir_empty[*]}" >> output.txt
# echo "- - - Dirs to remove - - -" >> output.txt
# echo "${dirs_to_remove[*]}" >> output.txt
# echo "- - - Dirs to create - - -" >> output.txt
# echo "${dirs_to_create[*]}" >> output.txt
# echo "- - - Files to check - - -" >> output.txt
# echo "${files_to_check[*]}" >> output.txt
# echo "- - - Files to remove - - -" >> output.txt
# echo "${files_to_remove[*]}" >> output.txt
# echo "- - - Files to copy - - -" >> output.txt
# echo "${files_to_copy[*]}" >> output.txt
# echo "- - - Files to skip - - -" >> output.txt
# echo "${files_to_skip[*]}" >> output.txt

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Danger! Action part begins here! Make sure code below is correct.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "Updating target...                  $(date +'%H:%M:%S')"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Delete empty dirs marked for removal from the target directory.
# If dir deletion results in an empty parent dir, remove it too
# and keep going recursively until reached the root of target dir. 
for i in ${dirs_to_remove[@]}; do
	# ---------------------------------------
	# This block is for testing
	# printf "1:rmdir %s " $target_dir$i
	# read -p "Proceed? [y/n]: " answer
	# if [ $answer = "y" ]; then
	# 	:
	# else
	# 	exit
	# fi
	# ---------------------------------------
	rmdir $target_dir$i
	sub_dir=$(echo $i | sed -n 's|\(.*/\)[^/]*|\1|p')
	while [ ${#sub_dir} -gt 0 ]; do
		sub_dir="${sub_dir:0:(${#sub_dir}-1)}" # to remove / from end
		target_dir_full=$target_dir$sub_dir
		if [ "$(ls -A $target_dir_full)" ]; then
			# This dir is not empty; break out of the loop.
			break
		else
			# This dir is empty; delete it and get the parent dir.
			# ---------------------------------------
			# This block is for testing
			# printf "2:rmdir %s " $target_dir_full
			# read -p "Proceed? [y/n]: " answer
			# if [ $answer = "y" ]; then
			# 	:
			# else
			# 	exit
			# fi
			# ---------------------------------------
			rmdir $target_dir_full
			sub_dir=$(echo $sub_dir | sed -n 's|\(.*/\)[^/]*|\1|p')
		fi
	done
done

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Delete files marked for removal from the target directory.
# If file deletion results in an empty dir, remove it too and
# keep going recursively until reached the root of target dir. 
for i in ${files_to_remove[@]}; do
	# ---------------------------------------
	# This block is for testing
	# printf "3:rm %s " $target_dir$i
	# read -p "Proceed? [y/n]: " answer
	# if [ $answer = "y" ]; then
	# 	:
	# else
	# 	exit
	# fi
	# ---------------------------------------
	rm $target_dir$i
	sub_dir=$(echo $i | sed -n 's|\(.*/\)[^/]*|\1|p')
	while [ ${#sub_dir} -gt 0 ]; do
		sub_dir="${sub_dir:0:(${#sub_dir}-1)}" # to remove / from end
		target_dir_full=$target_dir$sub_dir
		if [ "$(ls -A $target_dir_full)" ]; then
			# This dir is not empty; break out of the loop.
			break
		else
			# This dir is empty; delete it and get the parent dir.
			# ---------------------------------------
			# This block is for testing
			# printf "4:rmdir %s " $target_dir_full
			# read -p "Proceed? [y/n]: " answer
			# if [ $answer = "y" ]; then
			# 	:
			# else
			# 	exit
			# fi
			# ---------------------------------------
			rmdir $target_dir_full
			sub_dir=$(echo $sub_dir | sed -n 's|\(.*/\)[^/]*|\1|p')
		fi
	done
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
	target_dir_full="$target_dir"$(echo "$i" | sed -n 's|\(.*/\)[^/]*|\1|p')
	# Test if the dir exists; if not, create it first.
	if [ -d $target_dir_full ]; then
		# Dir exists; proceed with copying.
		# ---------------------------------------
		# This block is for testing
		# printf "5:cp %s %s " $source_dir$i $target_dir_full
		# read -p "Proceed? [y/n]: " answer
		# if [ $answer = "y" ]; then
		# 	:
		# else
		# 	exit
		# fi
		# ---------------------------------------
		cp -p $source_dir$i $target_dir_full
	else
		# Dir does not exist; create it first then copy.
		# ---------------------------------------
		# This block is for testing
		# printf "6:mkdir %s " $target_dir_full
		# read -p "Proceed? [y/n]: " answer
		# if [ $answer = "y" ]; then
		# 	:
		# else
		# 	exit
		# fi
		# ---------------------------------------
		mkdir -p $target_dir_full
		# ---------------------------------------
		# This block is for testing
		# printf "7:cp %s %s " $source_dir$i $target_dir_full
		# read -p "Proceed? [y/n]: " answer
		# if [ $answer = "y" ]; then
		# 	:
		# else
		# 	exit
		# fi
		# ---------------------------------------
		cp -p $source_dir$i $target_dir_full
	fi
done

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Create empty dirs marked to be created in the target.
for i in ${dirs_to_create[@]}; do
	target_dir_full=$target_dir$i
	# ---------------------------------------
	# This block is for testing
	# printf "8:mkdir %s " $target_dir_full
	# read -p "Proceed? [y/n]: " answer
	# if [ $answer = "y" ]; then
	# 	:
	# else
	# 	exit
	# fi
	# ---------------------------------------
	mkdir -p $target_dir_full
done

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Generate summary report.
echo "- - - - - - - - - - - - - - - - - - - - - - -"
echo "Backup completed.                   $(date +'%H:%M:%S')"
echo "- - - - - - - - - - - - - - - - - - - - - - -"
printf "Files inside source directory:      %s\n" ${#source_dir_files[@]}
printf "Files copied to backup directory:   %s\n" ${#files_to_copy[@]}
printf "Files skipped (unchanged files):    %s\n" ${#files_to_skip[@]}
printf "Files removed from backup:          %s\n" ${#files_to_remove[@]}
echo "- - - - - - - - - - - - - - - - - - - - - - -"
