#! /usr/bin/env bash

TREE_RESULT_FILE=$(mktemp)
SED_COMMAND_FILE=$(mktemp)

tree -f ${1} > ${TREE_RESULT_FILE}

# reverse the order of the paths so files nested in directories are processed first
# so that the direcotry names in the file names are not replaced when processing directories
PATHS=$(tac "${TREE_RESULT_FILE}" | grep -oP "(?<=── )\S+\$")
SED_COMMAND=""

for path in ${PATHS}; do
  if [[ -f ${path} ]]; then
    SUM="$(sha1sum ${path} | cut -d ' ' -f 1)"
    SED_COMMAND="${SED_COMMAND}s|${path}|$(basename ${path}) ${SUM}|;"
  else
    SED_COMMAND="${SED_COMMAND}s|${path}|$(basename ${path})|;"
  fi
done

# write the command to a tmp file
echo ${SED_COMMAND} > ${SED_COMMAND_FILE}

sed -f ${SED_COMMAND_FILE} ${TREE_RESULT_FILE}
