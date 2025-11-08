try() {
    "$@"
}

catch() {
    curl -m 10 --retry 5 $HEALTHCHECKS_URL/fail
    info "*************** An error occurred while executing: $@ ***************"
    borg list || true
    borg info || true
    info "Starting docker containers"
    docker compose --project-directory $PROJECT_DIR up -d
    exit 1
}

try_command() {
    try "$@" || catch "$@"
}

info() {
    printf "\n%s %s\n\n" "$( date )" "$*"
    curl -m 10 --retry 5 --data-raw "$*" $HEALTHCHECKS_URL/log
}

trap catch INT TERM
