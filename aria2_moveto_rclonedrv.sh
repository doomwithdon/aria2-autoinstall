#!/bin/bash

# The name of the linked network disk, which is the Name column displayed by rclone config
rcloneDrive='gdrv'                 
# aria2 download directory
downloadPath='/usr/local/caddy/www/aria2/download'  

# Aria2 Parameters passed to this script
# $1 is a serial number, generally not useful
# $2 is the number of files. If it is HTTP/FTP download, the number of files is generally 1. If it is a BT download, the number of files is generally greater than 1.
# $3 is the file path. If it is multiple files (such as BT download), it is the path of the first file.

if [ $2 -eq 0 ]; then      # No file, return directly
  exit 0  
elif [ $2 -eq 1 ]; then    # 1 File, directly processed
  # eg: rclone move /downloadPath/a.jpg gdrv:
  su - -c "rclone move \"$3\" $rcloneDrive:"  
  exit 0
else    # Multiple files, usually BT download 
  filePath=$3     # eg: /downloadPath/bt/a/b/c/d.jpg
  while true; do  
    # Peel a layer of catalog eg: Get /downloadPath/bt/a/b/c from /downloadPath/bt/a/b/c/d.jpg  
    dirnameStr=`dirname "$filePath"`    
    if [ "$dirnameStr" = "$downloadPath" ]; then    # Peel one level of directory to the aria2 download directory, indicating that filePath should be /downloadPath/bt     
      # eg: Get bt from /downloadPath/bt
      basenameStr=`basename "$filePath"`	  
      # eg: rclone move /downloadPath/bt gdrv:bt
      su - -c "rclone move \"$filePath\" $rcloneDrive:\"$basenameStr\""
      # Delete the remaining directories on the VPS eg: rm -rf /downloadPath/bt
      rm -rf "$filePath"            
      exit 0      
    elif [ "$dirnameStr" = "/" ]; then              #There is a problem with the script, it is stripped to the root directory, but it has not matched the aria2 download directory
      # Print error log
      echo "`date` [ERROR] rcloneDrive=$rcloneDrive;downloadPath=$downloadPath;[$1];[$2];[$3];" >> /tmp/aria2_download_complete.log
      exit 0
    else
      filePath=$dirnameStr
    fi
  done
fi
