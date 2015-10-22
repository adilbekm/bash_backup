====================================================================
What is this?
====================================================================

This is a test bash script to backup contents of one directory
(source) into another (target). The full path of the directories
is assigned to variables source_dir and target_dir in the script.
Assigning those two variables to correct paths is the only thing
a user needs to do to make it work on their computer (Mac).
Mac's built-in backup utility (Time Machine) doesn't work with 
iCloud drive.

Here is an example of a typical use of this script:

You have a folder on your Mac where you keep important files,
such as class notes or important spreadsheets, that you would like
to be able to backup to your iCloud drive. Note, this works best
for a small size directory with maybe 100-200 files (10-30 MB),
not an entire home drive (for backing up your entire drive please
use Mac's backup utility, Time Machine, to backup to a portable
hard drive). The script will backup files in any sub directories. 

You can use this script to make regular backups of this directory
to an iCloud directory with ease, by saving a copy of this script,
making a quick customization for your environment, and then simply
executing the script whenever you feel it's time to back things up.

====================================================================
How to execute this program?
====================================================================

1. Download or clone this script ("backup.sh"), or copy and paste its
content in a text file somewhere on your local machine, renaming
it "somename.sh".

2. Using any text editor such as Sublime or Nano, change the value
of 2 variables inside the script - "source_dir" and "target_dir",
located around lines 10-15 in the script, to whatever paths you will
be using. Source refers to the directory you want to backup,
and Target refers to the directory you want to backup to. Normally,
Source would be a directory on your machine and Target would be a
directory on your iCloud drive. I provided examples in the script.

3. Execute the script by opening Terminal and running command:
"bash backup.sh". Please note that if you are not in the same 
directory that the file is located, you will have to include the 
path in the command like so: "bash ~/scripts/backup.sh". 
Also note that if you changed the name of the file, you will have
to provide that name in place of "backup.sh".

====================================================================
Important information
====================================================================

The author of this program is Adilbek Madaminov. For questions, 
contact adilbekm@yahoo.com or by any other means available.
The program was completed on 10/22/2015.

Do not use this script if you are not an advanced computer user. 
If used incorrectly, this program could delete files and you won't
be able to recover them. The author won't be liable for any 
unintended consequences.

This is a free software and comes without any warranty. You can
distribute it or modify it as you like, but you are not allowed 
to use this program for commercial purposes without obtaining an
explicit permission from the author.
