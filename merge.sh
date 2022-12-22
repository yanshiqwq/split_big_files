#!/bin/bash
function test_error(){
	if [ ! $? = 0 ]; then
		cd ${dir}
		echo "Failed to merge file"
		rm ${dirname}/${file_name}
		exit 1
	fi
}
trap "onCtrlC" INT
function onCtrlC () {
    echo -e "\nCtrl+C is captured, script exit"
    exit
}

dir=$(realpath "$PWD")
folder_path=$(realpath "$1")
dirname=$(dirname "$folder_path")
if [ ! -d "${folder_path}" ]; then
	echo "Bad input (folder_path=${folder_path})"
	exit 1
else
	source "${folder_path}/conf"
fi

cd "${folder_path}"
echo "Checking md5sum for data chunks (proc=0) ..."
md5sum -c chunks.md5
test_error

echo "Start merging ${file_name} (proc=1) ..."
cat chunk.dat.* > "${dirname}/${file_name}"
test_error

cd "${dirname}"
echo "Checking md5sum for ${file_name} (proc=2) ..."
md5sum -c "${folder_path}/checksum.md5"
test_error

cd ${dir}
echo "File merged"