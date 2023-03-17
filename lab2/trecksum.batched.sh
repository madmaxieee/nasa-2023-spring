#! /usr/bin/env bash
TREE_RESULT_FILE=$(mktemp)

tree -f ${1} > ${TREE_RESULT_FILE}

line_count=$(wc -l ${TREE_RESULT_FILE} | cut -d ' ' -f 1)

batch_size=200

for ((i=1; i<=${line_count}; i+=${batch_size})); do
  lines=$(sed -n "${i},$((i+${batch_size}-1))p" ${TREE_RESULT_FILE})

  # get the paths from the lines
  paths=$(echo "${lines}" | tac | grep -oP "(?<=[└├]── )\S+\$")

  SED_COMMANDS=()

  for path in ${paths}; do
    if [[ -f ${path} ]]; then
      SUM="$(sha1sum ${path} | cut -d ' ' -f 1)"
      SED_COMMANDS+=("s|${path}|$(basename ${path}) ${SUM}|;")
    else
      SED_COMMANDS+=("s|${path}|$(basename ${path})|;")
    fi
  done

  echo "${lines}" | sed -f <(echo "${SED_COMMANDS[@]}")
done
