#!/bin/bash
function set_config(){
	echo "$1=$2" >> "$3"
	source "$3"
}
trap "onCtrlC" INT
function onCtrlC () {
    echo -e "\nCtrl+C is captured, script exit"
    exit
}

version_code=2
version="1.0"
dir=$(realpath "$PWD")
filepath=$(realpath "$1")
if [ ! -e "$filepath" ]; then
	echo "Bad input"
	exit 1
fi
if [ $2 ]; then
	chunk_size="$2"
else
	chunk_size="10000M"
fi
ext=.${filepath##*.}
if [ "${ext}" = "." ]; then
	ext=""
else
	ext="${ext}"
fi
basename=$(basename "$filepath" "${ext}")
dirname=$(cd "$(dirname "$filepath")"; pwd; cd "${dir}")
filesize=$(ls -l "$filepath" | awk '{print $5}')
cd "${dirname}"

folder_path=$(realpath "${dirname}/${basename}")
if [ -e "${folder_path}/conf" ]; then
	echo "File exists"
	exit
fi
if [ ! -e "${folder_path}" ]; then
	mkdir "${folder_path}"
fi

config=$(realpath "${dirname}/${basename}/config")
if [ ! -e "$config/proc" ]; then
	mkdir "$config"
	set_config script_version ${version} "$config/proc"
	set_config file_version ${version_code} "$config/proc"
	set_config file_size ${filesize} "$config/proc"
	set_config file_name $(basename "${filepath}") "$config/proc"
else
	source "$config/proc"
	if [ -e "$config/proc0" ]; then proc=0; fi
	if [ -e "$config/proc1" ]; then proc=1; fi
	if [ -e "$config/proc2" ]; then proc=2; fi
	if [ -e "$config/proc3" ]; then proc=3; fi
	echo "Continue the incomplete split process (proc=${proc})"
fi
set_config proc_start $(date +%s) "$config/proc"

if [ ! -e "$config/proc1" ]; then
	proc=0
	set_config proc0_start $(date +%s) "$config/proc0"
	echo "Start generating md5sum for original file (proc=0) ..."
	md5sum -b "${basename}${ext}" >> "${folder_path}/checksum.md5"
	set_config proc0_end $(date +%s) "$config/proc0"
fi

cd "${folder_path}"
if [ ! -e "$config/proc2" ]; then
	proc=1
	set_config proc1_start $(date +%s) "$config/proc1"
	echo "Start spliting $filepath (proc=1, chunk_size=${chunk_size}) ..."
	split "${dirname}/${basename}${ext}" -b ${chunk_size} -a 3 --numeric-suffixes=1 --verbose "./chunk.dat."
	set_config proc1_end $(date +%s) "$config/proc1"
fi

if [ ! -e "$config/proc3" ]; then
	proc=2
	if [ ! -e "$config/proc2" ]; then
		set_config proc2_start $(date +%s) "$config/proc2"
		set_config chunk_id 0 "$config/proc2"
	else
		source "$config/proc2"
	fi
	echo "Start generating md5sum for each chunk (proc=2) ..."
	for i in chunk.dat.*; do
		if [ ${i##*.} -ge ${chunk_id} ]; then
			set_config chunk_id ${i##*.} "$config/proc2"
			echo "Generating md5sum for chunks (chunk_id=${chunk_id}) ..."
			md5sum -b ${i} >> ./chunks.md5
		fi
	done
	rm -f "$config/proc2"
	touch "$config/proc3"
	set_config proc2_start $proc2_start "$config/proc2"
	set_config proc2_end $(date +%s) "$config/proc2"
	set_config chunk_count ${chunk_id} "$config/proc2"
fi

if [ $? = 0 ]; then
	proc=3
	cd "$dir"
	set_config proc_end $(date +%s) "$config/proc"
	cat "$config/proc" "$config/proc1" "$config/proc2" > "${folder_path}/conf"
	rmdir "$config"
	echo "File Spilt"
else
	echo "Failed to split file"
	rmdir "${folder_path}"
	exit 1
fi
