#!/bin/bash

# Rebases all git repositories under the specified directory

USR=$(whoami)

function print_usage {
cat << _EOF

Rebases all git directories under the specified folder

Usage: rebase_all.sh DIR

Options:
    -h,--help:   shows this message
    -u,--user:   gerrit user. If not specified, then $(whoami) is used

Example:

    ./rebase_all.sh $HOME/git/github

_EOF
}

while [[ $# -gt 1 ]]
do
    key="$1"
    case $key in
    -h|--help)
        print_usage
        exit 1
        ;;
    -u|--user)
        USR="$2"
        shift
        shift
        ;;
    esac
done

DIR=$1

echo "Rebasing all repositories under $DIR"

pushd $DIR> /dev/null

for item in $(find . -type d)
do
    #echo "Checking directory $d"
    if [ -d "${item}/.git" ]; then
        echo "======> Directory $item is a git directory. Rebasing..."
        pushd $item > /dev/null
        git pull --rebase
        popd > /dev/null
    fi
    
done

popd > /dev/null
