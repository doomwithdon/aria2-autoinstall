#!/bin/bash

# The name of the network disk linked to rclone, which is the Name column displayed in rclone config
rcloneDrive='sharepoint'                 
# aria2 download directory, which is the value of aria2’s dir configuration item
downloadPath='/usr/local/caddy/www/aria2/download'  

# Parameters passed by Aria2 to this script
# $1 is a serial number, generally of no practical use
# $2 is the number of files. If it is HTTP/FTP download, the number of files is generally 1. If it is a BT download, the number of files is generally greater than 1.
# $3 is the file path. If there are multiple files (such as BT download), it is the path of the first file.

if [ $2 -eq 0 ]; then # If there is no file, return directly
  exit 0  
elif [ $2 -eq 1 ]; then # 1 file, processed directly
  # eg: rclone move /downloadPath/a.jpg gdrv:
  su - -c "rclone move \"$3\" $rcloneDrive:"  
  exit 0
else # Multiple files, usually BT downloads
  filePath=$3 # eg: /downloadPath/bt/a/b/c/d.jpg
  while true; do  
    # Peel off a layer of directory eg: get /downloadPath/bt/a/b/c from /downloadPath/bt/a/b/c/d.jpg  
    dirnameStr=`dirname "$filePath"`    
    if [ "$dirnameStr" = "$downloadPath" ]; then # Peel off one layer of the directory to reach the aria2 download directory, indicating that filePath should be /downloadPath/bt     
      #eg: Get bt from /downloadPath/bt
      basenameStr=`basename "$filePath"`	  
      #eg: rclone move /downloadPath/bt gdrv:bt
      su - -c "rclone move \"$filePath\" $rcloneDrive:\"$basenameStr\""
      # Delete the remaining directories eg on the VPS: rm -rf /downloadPath/bt
      rm -rf "$filePath"            
      rm "$filePath".aria2
      exit 0      
    elif [ "$dirnameStr" = "/" ]; then #There is a problem with the script. It has been stripped to the root directory and has not yet matched the aria2 download directory.
      # Print error log
      echo "`date` [ERROR] rcloneDrive=$rcloneDrive;downloadPath=$downloadPath;[$1];[$2];[$3];" >> /tmp/aria2_download_complete.log
      exit 0
    else
      filePath=$dirnameStr
    fi
  done
fi
