BorgBackup Automation Scripts

This repository contains a set of scripts designed to automate the process of creating, managing, and monitoring backups using [BorgBackup](https://borgbackup.readthedocs.io/). These scripts ensure reliable backups, handle errors gracefully, and integrate with health check services for monitoring.

---

## Overview

The scripts in this repository automate the following tasks:
- Backing up specified directories to a Borg repository.
- Managing backup retention policies (e.g., daily, weekly, monthly, yearly).
- Compacting the repository to free up disk space.
- Stopping and restarting Docker containers during the backup process.
- Logging backup operations and sending status updates to a health check service.

---

## Scripts

### 1. `automated_backups.sh`
This script orchestrates the backup process for multiple directories. It:
- Reads the list of directories to back up from the `DIRECTORIES_TO_BACKUP` environment variable.
- Invokes the `backup.sh` script for each directory.
- Logs the results of each backup operation.
- Sends status updates to a health check service.

### 2. `backup.sh`
This script performs the backup for a single directory. It:
- Stops Docker containers associated with the project.
- Creates a Borg archive for the specified directory.
- Prunes old backups based on retention policies.
- Compacts the Borg repository to free up space.
- Restarts Docker containers after the backup is complete.
- Sends status updates to a health check service.

### 3. `helpers.sh`
This script provides utility functions for logging, error handling, and executing commands safely. Key functions include:
- `try_command`: Executes a command and handles errors.
- `info`: Logs informational messages and sends them to the health check service.

---

## Environment Variables

The scripts rely on several environment variables for configuration. These include:

### Global Variables (used in `automated_backups.sh`):
- `DIRECTORIES_TO_BACKUP`: An array of directories to back up.
- `HEALTHCHECKS_URL`: The URL of the health check service for general backup job.

### Per-Project Variables (used in `backup.sh`):
- `BORG_REPO`: The Borg repository URL.
- `BORG_PASSPHRASE`: The passphrase for the Borg repository.
- `FOLDERS_TO_BACKUP`: An array of folders within the project to back up.
- `BORG_REMOTE_PATH`: The remote path for Borg.
- `HEALTHCHECKS_URL`: The URL of the health check service for the project.

---

## Usage

1. **Set Up Environment Variables**:
   - Create an `automated_backup_env.sh` file for global backup job variables.
   - Create a `backup_default_env.sh` file for default backup variables.
   - Create a `backup_env.sh` file in each project directory for project-specific variables.

2. **Run the Automated Backup**:
   ```bash
   ./automated_backups.sh
   ```

3. **Check Logs**:
   - Logs are stored in the `./logs` directory, organized by project and log type (`info` or `debug`).

---

## Logging and Monitoring

- **Logs**:
  - Informational logs are stored in `./logs/<project_name>/info/`.
  - Debug logs are stored in `./logs/<project_name>/debug/`.

- **Health Checks**:
  - The scripts send status updates to the health check service at various stages:
    - Start of the backup.
    - Completion of each backup (success or failure).
    - Final status (all backups completed or some failed).

---

## Error Handling

- If an error occurs during the backup process:
  - The `catch` function logs the error and sends a failure status to the health check service.
  - Docker containers are restarted to ensure the server remains operational.

- The `try_command` function ensures that commands are executed safely, and any failures are handled gracefully.

---

## Dependencies

- [BorgBackup](https://borgbackup.readthedocs.io/)
- `curl` for sending health check updates.
- Docker for managing project containers.
