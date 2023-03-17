#! /usr/bin/env bash

file_num=0
dir_num=1

tracksum(){
	local name="$1"
	local root="$2"
	local prefix="$3"

	local target_name=${root}/${name}
	if [[ -d ${target_name} ]]; then
		local files=($(ls ${target_name} | LC_ALL=C sort))
		for idx in $(seq 1 ${#files[@]}); do
			local file=${files[idx-1]}
			if [[ idx -ne ${#files[@]} ]]; then
				if [[ -f ${target_name}/${file} ]]; then
					checksum=($(sha1sum ${target_name}/${file}))
					printf "%s├── %s %s\n" "${prefix}" "${file}" "${checksum[0]}"
					file_num=$((${file_num}+1))
				else
					printf "%s├── %s\n" "${prefix}" "${file}"
					dir_num=$((${dir_num}+1))
				fi
				tracksum ${file} ${target_name} "${prefix}│   "
			else
				if [[ -f ${target_name}/${file} ]]; then
					checksum=($(sha1sum ${target_name}/${file}))
					printf "%s└── %s %s\n" "${prefix}" "${file}" "${checksum[0]}"
					file_num=$((${file_num}+1))
				else
					printf "%s└── %s\n" "${prefix}" "${file}"
					dir_num=$((${dir_num}+1))
				fi
				tracksum ${file} ${target_name} "${prefix}    "
			fi
		done
	fi
}

echo ${1}
tracksum ${1} "." "" 

echo
dir_postfix="directories"
if [[ ${dir_num} -eq "1" ]]; then
	dir_postfix="directory"
fi
file_postfix="files"
if [[ ${file_num} -eq "1" ]]; then
	file_postfix="file"
fi

echo ${dir_num} ${dir_postfix}, ${file_num} ${file_postfix}

