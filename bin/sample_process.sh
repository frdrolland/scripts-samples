#!/bin/bash
# ==========================================================================================
# @File: sample_process.sh
#       Sample script to manage start/stop/status of a daemon process
#
# ==========================================================================================

script_file=$(basename $0)
script_dir=$(readlink -f $(dirname $0))
execution_dir=$PWD

if [ -f ${script_dir}/_commons.sh ]; then
  . ${script_dir}/_commons.sh
else
  echo "[FATAL] Missing script ${script_dir}/_commons.sh - exiting"
  exit 2  
fi

# ==========================================================================================
#
# Functions
#
# ==========================================================================================

# Show command-line help, then exit
#
function Usage() {
  echo "Usage: $0 [-h|--help]" >&2 
  exit ${STD_RETCODE_ERROR}
}

# ================================================================================
# cmd_start: start the application
# ================================================================================
function cmd_start() {
  log_warning "cmt_start function is not implemented yet"
  return ${STD_RETCODE_NOTIMPLEMENTED};
}

# ================================================================================
# cmd_checkconfig: checks application configuration and exit
# ================================================================================
function cmd_checkconfig() {
  log_warning "cmd_checkconfig function is not implemented yet"
  return ${STD_RETCODE_NOTIMPLEMENTED};
}

# ================================================================================
# cmd_status: get status of the application
# ================================================================================
function cmd_status() {
  log_warning "cmd_status function is not implemented yet"
  return ${STD_RETCODE_NOTIMPLEMENTED};
}

# ================================================================================
# cmd_stop: stops the application
# ================================================================================
function cmd_stop() {
  log_warning "cmd_stop function is not implemented yet"
  return ${STD_RETCODE_NOTIMPLEMENTED};
}

# ================================================================================
# Command-line argument parsing  
# ================================================================================
# read the options
TEMPOPT=`getopt -o hp: --long help,pid-file: -n '$0' -- "$@"`
eval set -- "$TEMPOPT"
# extract options and their arguments into variables.
while true ; do
    case "$1" in
        -h|--help) 
          Usage; 
          shift;;
        -p|--pid-file)
            case "$2" in
                "") shift 2 ;;
                *) PID_FILE=$2 ; shift 2 ;;
            esac ;;
        \?)
          echo "Invalid option: -$OPTARG" >&2
          Usage;
          ;;
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done

ini_logfile;

COMMAND=$1
log_debug "COMMAND = $COMMAND"
log_debug "PID_FILE = $PID_FILE"

if [ -z $COMMAND ]; then
	echo "Missing argument <command>"
	Usage;
fi

case $COMMAND in
	"start")
		cmd_start;
		;;
	"check-config")
		cmd_checkconfig;
		;;
	"status")
    exec_crit_cmd cmd_env;
		cmd_status;
		;;
	"stop")
		cmd_stop;
		;;
	"env")
		cmd_env;
		;;
	*)
		echo "Invalid command $COMMAND"
		Usage;
		;;
esac

ret=$?
if [ ! -z "$ret" ]; then
  log_error "Exiting with error code : $ret"
  exit $ret
fi

# Default return code
exit ${STD_RETCODE_OK}
