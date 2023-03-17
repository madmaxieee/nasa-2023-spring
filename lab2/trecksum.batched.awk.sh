#! /usr/bin/env bash
TREE_RESULT_FILE=$(mktemp)
SHA1SUM_FILE=$(mktemp)
SED_COMMAND_FILE=$(mktemp)

tree -f ${1} > ${TREE_RESULT_FILE}

line_count=$(wc -l ${TREE_RESULT_FILE} | cut -d ' ' -f 1)

batch_size=200

for ((i=1; i<=${line_count}; i+=${batch_size})); do
  lines=$(sed -n "${i},$((i+${batch_size}-1))p" ${TREE_RESULT_FILE})

  # get the paths from the lines
  paths=$(echo "${lines}" | tac | grep -oP "(?<=[└├]── )\S+\$")

  sha1sum ${paths} > ${SHA1SUM_FILE} 2> /dev/null
  awk '{
    basename = gensub(/.*\/(.*)/, "\\1", "g", $2)
    print "s|" $2 "|" basename " " $1 "|;"
  }' ${SHA1SUM_FILE} > ${SED_COMMAND_FILE}

  SED_COMMANDS=()
  for path in ${paths}; do
    if [[ -d ${path} ]]; then
      SED_COMMANDS+=("s|${path}|$(basename ${path})|;")
    fi
  done

  # write the command to a tmp file
  echo "${SED_COMMANDS[@]}" | tr ' ' '\n' >> ${SED_COMMAND_FILE}

  echo "${lines}" | sed -f ${SED_COMMAND_FILE}
done
