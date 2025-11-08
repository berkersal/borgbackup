#!/bin/bash
set -e
set -x

if [ -z "$1" ];
then
    echo "No argument supplied"
    exit 1
fi

export PROJECT_DIR="$1"
export PROJECT_NAME=$(basename "$PROJECT_DIR")
export BORG_KEY_FILE="$PROJECT_DIR/borg.keyfile"

. backup_default_env.sh
. "$PROJECT_DIR/backup_env.sh"

required_vars=(BORG_REPO BORG_PASSPHRASE FOLDERS_TO_BACKUP BORG_REMOTE_PATH HEALTHCHECKS_URL)  
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "Error: Required environment variable $var is not set."
        exit 1
    fi
done

FOLDERS_TO_BACKUP_FULL_PATHS=()
for f in "${FOLDERS_TO_BACKUP[@]}"; do
    if [[ "$f" == /* ]]; then
        FOLDERS_TO_BACKUP_FULL_PATHS+=("$f")
    else
        FOLDERS_TO_BACKUP_FULL_PATHS+=("${PROJECT_DIR%/}/$f")  # strip trailing slash from PREFIX, if any
    fi
done

. helpers.sh

curl -m 10 --retry 5 $HEALTHCHECKS_URL/start

info "Stopping docker containers in $PROJECT_NAME"
try_command docker compose --project-directory $PROJECT_DIR down

# Backup the most important directories into an archive named after the date
info "Starting backup of $PROJECT_NAME to $BORG_REPO"
try_command                             \
    borg create                         \
        --verbose                       \
        --filter AME                    \
        --list                          \
        --stats                         \
        --show-rc                       \
        --show-version                  \
        --compression auto,zstd,10      \
        --exclude-caches                \
                                        \
        ::'{now}'                       \
                                        \
        "${FOLDERS_TO_BACKUP_FULL_PATHS[@]}"


# Use the `prune` subcommand to maintain 7 daily, 4 weekly, 6 monthly and 1 yearly archives.
info "Pruning repository of $PROJECT_NAME"
try_command                             \
    borg prune                          \
        --list                          \
        --show-rc                       \
        --keep-daily    7               \
        --keep-weekly   4               \
        --keep-monthly  6               \
        --keep-yearly   1


# actually free repo disk space by compacting segments
info "Compacting repository of $PROJECT_NAME"
try_command borg compact                \
        --show-rc

info "Current status of $PROJECT_NAME backup"
try_command borg list
try_command borg info

info "Starting docker containers in $PROJECT_NAME"
try_command docker compose --project-directory $PROJECT_DIR up -d

curl -m 10 --retry 5 $HEALTHCHECKS_URL
