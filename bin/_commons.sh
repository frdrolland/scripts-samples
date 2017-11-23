#!/bin/bash
# ==========================================================================================
# @File: _commons.sh
#       Defines functions / variables to use in script files.
#
# Usage:
#       In a Bash shell file, call this script as shown below :
#  script_dir=$(readlink -f $(dirname $0))
#  if [ -f ${script_dir}/_commons.sh ]; then
#    . ${script_dir}/_commons.sh
#  else
#    "[FATAL] Missing script ${script_dir}/_commons.sh - exiting"
#    exit 2
#  fi
#
# ==========================================================================================

script_basename=$(basename $0)
script_basename_noext=${script_basename%%.*}

if [ -z "${execution_dir}" ]; then
  execution_dir=${PWD}
fi
if [ -z "${log_dir}" ]; then
  log_dir=${execution_dir}
fi
if [ -z "${log_file}" ]; then
  log_file=${log_dir}/$script_basename_noext.log
fi
if [ -z "${log_keep_days}" ]; then
  # By default, keep log files for 20 days
  log_keep_days=20
fi
if [ -z "${logs_retention}" ]; then
  # By default, keep log files for 20 days
  logs_retention=20
fi

# ================================================================================
#
# Constants
#
# ================================================================================

# Return code as expected in our standards
STD_RETCODE_OK=0
STD_RETCODE_ANYERROR=1
STD_RETCODE_NOTIMPLEMENTED=2

# ================================================================================
#
# Logging functions
#
# ================================================================================
# Init the log file
function ini_logfile() {
  if [ -z "${log_file}" ]; then
    return 0;
  fi
  if [ -f ${log_file} ]; then
    newlogfile="$log_file.$(date +'%Y%m%d-%H%M%S').gz"
    log_info "archive : ${log_file} => ${newlogfile}";
    mv ${log_file} $newlogfile 
  fi
  purge_logfiles;
}

# Purge old log files
function purge_logfiles() {
  if [ -z "${log_file}" ]; then
    log_warning "log_file variable not set: cannot purge old log files"
    return 0;
  fi
#  for fic in $(find ${log_dir} -mtime +${logs_retention} -regex "${log_file}.*.gz"); do
#  for fic in $(find ${log_dir} -mtime +1 -regex "${log_file}.*.gz"); do
  for fic in $(find ${log_dir} -mtime +1 -regex "${log_file}.*.gz"); do
    log_info "delete: file $fic"
    rm $fic
  done
}

# Prints a debug message on stdout
function log_debug () {
  if [[ 1 -ne "$quiet" && 1 -eq "$verbose" ]]; then
    echo "$(date "+%Y-%m-%d %H:%M:%S") [debug] $1"
  fi
}

# Prints an information message on stdout
function log_info () {
  if [[ 1 -ne "$quiet" ]]; then
    echo "$(date "+%Y-%m-%d %H:%M:%S") [info] $1"
  fi
}

# Prints a warning code/message on stdout
function log_warning () {
  echo "$(date "+%Y-%m-%d %H:%M:%S") [warn] $1"
}

# Prints a fatal error code/message on stderr
function log_error () {
  echo "$(date "+%Y-%m-%d %H:%M:%S") [error] $1" >&2
}

# Prints a fatal error code/message on stderr, then exits
function log_critical () {
  if [[ 1 -ne "$quiet" ]]; then
    echo "$(date "+%Y-%m-%d %H:%M:%S") [fatal] [BLD-$1] $2" >&2
  fi
  if [ 1 -eq "$#" ]; then
    exit -1
  fi
  exit $1
}

# ================================================================================
#
# Miscellaneous
#
# ================================================================================

# Check return code end exit if != 0
#
function check_retcode_critical () {
  ret=$?
  if [ $ret -ne 0 ]; then
    #last=$(history | tail -2 | head -1  | sed -e 's/[0-9](.*)//')
    log_critical 999 "$1 returned $ret"
  fi
}

# ================================================================================
# Checks a return code: if != 0, then exit with an error message
# First argument MUST be $?
# Second argument is an error message
# ================================================================================
function check_return_code() {
  if [ -z "$1" ]; then
    log_critical "check_return_code MUST be called with at least 1 argument"
  fi
  if [ -z "$2" ]; then
    log_critical "Previous command return code: $1" $1
  else
    log_critical "$2" "$1"
  fi
}

# ================================================================================
#
# Environment check
#
# ================================================================================

# ================================================================================
# Checks that JAVA_HOME variable is correctly set 
# ================================================================================
function check_java_home() {
	if [ ! -x "$JAVA_HOME/bin/java" ]; then
    log_critical "Cannot execute JVM ($JAVA_HOME/bin/java)"
  fi
}

# ================================================================================
# Checks that 'classpath' variable is correctly set 
# ================================================================================
function check_classpath() {
	if [ -z "$classpath" ]; then
    log_critical "'classpath' variable MUST be set"
  else
    log_trace "classpath  = $classpath"
  fi
}

# ================================================================================
# Shows some informations about current environnment  
# ================================================================================
function cmd_env() {
	log_info "JAVA_HOME : $JAVA_HOME";
	$JAVA_HOME/bin/java -version
}

# ================================================================================
# Execute a critical command and :
#     1) log output (stdout and stderr) to log file
#     2) exit in case of error
# ================================================================================
function exec_crit_cmd() {
  cmd=$1
  if [ -z "$cmd" ]; then
    log_error "exec_crit_cmd called without parameter"
  else
    log_debug "exec: $cmd"
    $cmd >> ${log_file} 2>&1
  fi
}

# ================================================================================
#
# I/O operations
#
# ================================================================================

# Safely remove directory : fails if directory path is empty or "/"
function safe_remove_dir() {
  param=$(echo "$1" | sed 's/[[:space:]]//g')
  if [[ -z "$param" || "" == "$param" ]]; then
    log_critical 21 "Missing function call parameter : a directory path MUST be provided"
  fi
#  if [[ "/" == "$param" ]]; then
#    log_critical 22 "Bad function call parameter : removing directory \"$param\" is forbidden"
#  fi
  if [[ "." == "$param" || ".." == "$param" ]]; then
    log_critical 22 "Bad function call parameter : removing directory \"$param\" is forbidden"
  fi
  if [[ "$param" =~ ^(\.)?\/$ ]]; then
    log_critical 23 "Bad function call parameter : removing directory \"$param\" is forbidden"
  fi
  check_regex="^\/[a-zA-Z0-9\-\_\.]+$"
  if [[ "$param" =~ $check_regex ]]; then
    log_critical 24 "Bad function call parameter : removing directory \"$param\" is forbidden"
  fi
  rm -rf ${param}
  log_debug "removed ${param}"
}


# ================================================================================
#
# Common code executed when include this script
#
# ================================================================================

# Check variables
if [ -z "$APP_BASE" ]; then
  log_warning "[warning] APP_BASE environment variable not set: will use $PWD"
  APP_BASE=${PWD}
fi

if [ ! -z "${quiet}" ] && { [ "1" = "${quiet}" ] || [ "y" = "${quiet}" ] || [ "Y" = "${quiet}" ]; } then
  quiet=1;
else
  quiet=0;
fi

if [ ! -z "${verbose}" ] && { [ "1" = "${verbose}" ] || [ "y" = "${verbose}" ] || [ "Y" = "${verbose}" ]; } then
  verbose=1;
else
  verbose=0;
fi
