#!/bin/bash
set -eu

# Global variable to track if any errors are found.
export FOUND_ERROR=0

# Global termianl color variables.
export RED GREEN WHITE
RED="$(tput -Txterm-256color setaf 1)"
GREEN="$(tput -Txterm-256color setaf 2)"
WHITE="$(tput -Txterm-256color setaf 7)"

# Global variables for what test to run.
export TEST_SHFMT=0 TEST_SHELLCHECK=0
export BIN_SHFMT="shfmt"
export BIN_SHELLCHECK="shellcheck"

# Check that script dependency exists.
if which "${BIN_SHFMT}" >/dev/null; then
  TEST_SHFMT=1
else
  # We don't force install any packages here because we don't want to disrupt
  # the existing environment.
  echo "${BIN_SHFMT} not found in PATH"
fi
if which "${BIN_SHELLCHECK}" >/dev/null; then
  TEST_SHELLCHECK=1
else
  # We don't force install any packages here because we don't want to disrupt
  # the existing environment.
  echo "${BIN_SHELLCHECK} not found in PATH"
fi

# If no TEST_* variables set, we have nothing to test! ERROR out.
if [[ ${TEST_SHFMT} -ne 1 ]] && [[ ${TEST_SHELLCHECK} -ne 1 ]]; then
  echo "ERROR: can't find ${BIN_SHFMT} or ${BIN_SHELLCHECK}, nothing to test."
  exit 1
fi

##############################
# Output helper functions.
##############################
output_filename() {
  local filename=${1}
  echo -n "[$(date -u '+%H:%M:%S.%N')] ${filename} ... "
}
output_error() {
  local TEST_TYPE=${1}
  # Color output for ERROR.
  echo "${RED}${TEST_TYPE} ERROR${WHITE}"
}
output_pass() {
  local TEST_TYPE=${1}
  # Color output for PASS.
  echo "${GREEN}${TEST_TYPE} PASS${WHITE}"
}
output_event() {
  local TEST_EVENT=${1}
  echo -e "\tTEST ${TEST_EVENT} - $(date -u '+%Y-%m-%d %H:%M:%S.%N %Z%z')"
}

##############################
test_shfmt() {
  local TEST_TYPE="${BIN_SHFMT}"
  # This test uses shfmt to test whitespace and formatting of scripts.
  local filename="${1}"
  output_filename "${filename}"
  # shfmt -l will show the filename if there is an error, and no output
  # if it passes. '-i 2' is to set indent to use 2 spaces.
  if "${BIN_SHFMT}" -i 2 -l "${filename}" | grep "${filename}" >/dev/null; then
    output_error "${TEST_TYPE}"
    FOUND_ERROR=1
  else
    output_pass "${TEST_TYPE}"
  fi
}

##############################
test_shellcheck() {
  local TEST_TYPE="${BIN_SHELLCHECK}"
  # This test uses shellcheck to check logic and attempt to find errors.
  local filename="${1}"
  output_filename "${filename}"
  SHELLCHECK_OPTS="--color=always --exclude=SC2230"
  if ! "${BIN_SHELLCHECK}" ${SHELLCHECK_OPTS} "${filename}" >/dev/null; then
    output_error "${TEST_TYPE}"
    # - Use awk to add spaces before the output to make it human readable.
    "${BIN_SHELLCHECK}" ${SHELLCHECK_OPTS} "${filename}" |
      awk '{print "\t"$0}' ||
      true
    FOUND_ERROR=1
  else
    output_pass "${TEST_TYPE}"
  fi
}

##############################
# Main
##############################
echo "######################################################################"
output_event "START"
echo "${BIN_SHFMT} version: $(${BIN_SHFMT} -version)"
echo "${BIN_SHELLCHECK} version: $(${BIN_SHELLCHECK} --version |
  awk '{print "\t"$0}')"
# - Find scripts ending in .sh
# - Use 'for' loop, because 'while' loop won't use global scope for FOUND_ERROR
for filename in $(find . -type f | sort); do
  # Only test Bourne-Again shell scripts.
  if file "${filename}" | grep 'Bourne-Again shell script' >/dev/null; then
    if [[ ${TEST_SHFMT} -eq 1 ]]; then
      test_shfmt "${filename}"
    fi
    if [[ ${TEST_SHELLCHECK} -eq 1 ]]; then
      test_shellcheck "${filename}"
    fi
  fi
done
output_event "END"
echo "######################################################################"

# If global error found.
if [[ ${FOUND_ERROR} -eq 1 ]]; then
  # Cause script to exit 1 if 'set -e' was set.
  false
fi
