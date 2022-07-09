#!/bin/bash
LOG_FOLDER=./logs/
#helper functions ====================
<<com
    log_info: This function will print all the arguments passed to it by appending [INFO] to it.
    cmd: info "Checking the files."
    # prints
    [INFO] Checking the files.
    Expects one argument.
com
log_info(){
    echo "[INFO]-[$(date +%Y-%m-%dT%H:%M:%S)]:$2" >> "${LOG_FOLDER}$1"
}

<<com
    log_fatal: This function will print all the arguments passed to it by appending [FATAL] to it. 
    fatal "Something wrong happened."
    # prints
    [FATAL] Something wrong happened.
    Expects one argument.(message)
    In addition to printing it will also make the script exit with non-zero code.
com
log_fatal(){
    msg="[FATAL]: $1"
    echo "$msg"
    exit 2
}

log_fatal_write(){
    #matches every file except those containing a dot
    file_name=$(ls logs | grep -v \\.)
    msg="[FATAL]-[$(date +%Y-%m-%dT%H:%M:%S)]:$1"
    echo "$msg"
    echo "$msg" >> "${LOG_FOLDER}$file_name"
    exit 3
}
<<com
    check_user_is_root: Check if we are running as root, if yes then call fatal with a message 
    # prints
    [FATAL] This script must be run as a non-root user.
com
check_user_is_root(){
    if [[ $EUID -eq 0 ]]; then
        log_fatal "This script must be run as a non-root user."
    fi
}

<<com
    check_logs_directory_exists: Check if the logs directory exist, 
    # prints
    [FATAL]  The 'logs' directory is not present.
    In addition to printing it will also make the script exit with non-zero code.
com
check_logs_directory_exists(){
    if [ ! -d ./logs ]
        then log_fatal "The 'logs' directory is not present."
    fi
}

<<com
    check_correct_arguments: Check if any arguments are provided to it. 
    fatal "Something wrong happened."
    # prints
    [FATAL] Needs at least one argument, can be gen, rotate, or clean..
    In addition to printing it will also make the script exit with non-zero code.
com

check_correct_arguments(){
    
    if [[ $# -eq 0 ]]; then
        log_fatal_write "Needs at least one argument, can be gen, rotate, or clean."
    fi

    # echo "$@ $# $1 $2"

    if [[ "$1" = "gen" && $# -eq 3 ]]; then
        shift;
        generate_logs $@
    elif [[ "$1" = "clean" && $# -eq 2 ]]; then
        shift;
        clean_logs $@
    elif [[ "$1" = "rotate" && $# -eq 3 ]]; then
        shift;
        rotate_logs $@
    else
        log_fatal_write "Needs filename and threshhold
            e.g. gen <file_name> <threshold>
            e.g. rotate <file_name> <threshold> or 
            e.g. clean <threshold>"
    fi
}

#sub commands:==========
generate_logs(){
    for (( i=0; i<$2; i++ ))
    do
        log_info $1 "The quick brown fox jumps over the lazy dog." 
    done
}


<<comm
    clean_logs: This will delete the old logs from logs directory, and always keep n log files in the directory.
    function takes arguments: threshold.
    1. Check the total number of log files in the logs directory.
    2. If it is greater than threshold, then delete the old files one by one till we have files equal to the threshold.
comm
clean_logs(){
    file_count=$(ls -tr "${LOG_FOLDER}" | wc -l)

    if [[ $file_count -gt $1 ]]; then
        delete_count=$(($file_count-$1))
        files=$(ls -tr ${LOG_FOLDER} | head -n $delete_count)
        for file in $files; do
            rm "${LOG_FOLDER}${file}"
        done
    fi 
}

<<comm
    rotate_logs function takes arguments: file-name, threshold.
    If the 'file-name' has more than threshold lines:
    1. Rename 'file-name' to file-name-<timestamp>. For example: earth-log will become earth-log-1656400728.
    2. Add an info message: "The 'file-name' has been renamed to 'new name'."

comm
rotate_logs(){
    if [[ $2 -lt $(cat "${LOG_FOLDER}$1" | wc -l) ]]; then
        new_name="$1.$(date +%N)"
        cp "${LOG_FOLDER}$1" "${LOG_FOLDER}$new_name"
        rm "${LOG_FOLDER}$1"
        log_info $1 "The '$1' has been renamed to '$new_name'."
    fi
    # echo "rotate :$@"

}

#sub commands end==========
do_operate(){
    check_user_is_root
    check_logs_directory_exists
    check_correct_arguments $@
}
#======================================

do_operate $@