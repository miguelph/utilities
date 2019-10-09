#!/bin/bash

# The purpose of this script is to clone all child repos of a given parent
# "parent" is defined by a prefix.
# Note that previously cloned repository will be ignored.
# Set the "ENV_GERRIT_SERVER" environment variable (or harcode it here)

if [[ -z "${ENV_GERRIT_SERVER}" ]]; then
    echo "You have to set ENV_GERRIT_SERVER env var to point to your gerrit server"
    exit 1
fi

USR=$(whoami)
DRY_RUN="false"
TARGET_DIR="$(pwd)"
GERRIT_SERVER="${ENV_GERRIT_SERVER}|-gerrit.acme.com"

function print_usage {
cat << _EOF

List and clones all repositories from a parent repo

Usage: clone_sub_repos.sh [options] PREFIX

Options:
  -h,--help:   shows this message
  -s,--show:   kind of dry-run, only shows, doesnt clone.
  -d,--dir:    target directory. If not spec, then $pwd is used.
  -u,--user:   gerrit user. If not specified, then $(whoami) is used
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
    -s|--only-show)
        DRY_RUN="true"
        shift
        ;;
    -d|--dir)
        TARGET_DIR="$2"
        shift
        shift
        ;;
    -u|--user)
        USR="$2"
        shift
        shift
        ;;
    esac
done

PREFIX=$1

REPO_LIST=$(ssh -p 29418 $USR@$GERRIT_SERVER gerrit ls-projects --prefix "$PREFIX")

echo "Cloning repos that start with $PREFIX in $TARGET_DIR using user $USR"

pushd $TARGET_DIR> /dev/null

for repo in $REPO_LIST
do
    repo_name="$(basename $repo)"
    repo_path="$(dirname $repo)"
    if [ -d "${repo}/.git" ]; then
        echo "======> Repo $repo is already cloned. Skipping..."
        continue
    fi
    echo "Cloning repo $repo in path $repo_path"
    mkdir -p $repo_path
    pushd $repo_path > /dev/null
    if [[ "${DRY_RUN}" == "false" ]]; then
        git clone ssh://$USR@$GERRIT_SERVER:29418/$repo \
            && scp -p -P 29418 $USR@$GERRIT_SERVER:hooks/commit-msg $repo_name/.git/hooks/
    fi
    popd > /dev/null
    echo
done

popd > /dev/null
