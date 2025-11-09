# BorgBackup Systemd Service and Timer

Configuration files for setting up an automated backup system using BorgBackup, managed by systemd.

## Files Overview

### `borgbackup.service`
This systemd service is responsible for executing the backup script. It is configured as a `oneshot` service, meaning it runs the specified script once per activation.

### `borgbackup.timer`
This systemd timer schedules the `borgbackup.service` to run at a specific time.

## Setup Instructions

1. **Place the Files**:
  ```bash
  cp borgbackup.* /etc/systemd/system/
  ```

2. **Edit the Script Path in Service File**:
  Open `/etc/systemd/system/borgbackup.service` and modify the `WorkingDirectory` line to point to your actual backup script location.

3. **Enable and Start the Timer**:
  Run the following commands to enable and start the timer:
  ```bash
  systemctl daemon-reload
  systemctl enable --now borgbackup.timer
  ```

4. **Verify the Timer**:
  Check the status of the timer to ensure it is active:
  ```bash
  systemctl status borgbackup.timer
```

5. **Test the Service**:
  Manually trigger the service to verify the backup script runs correctly:
  ```bash
  systemctl start borgbackup.service
  ```

6. **Check Logs**:
  View logs for the service and timer using `journalctl`:
  ```bash
  journalctl -u borgbackup.service
  journalctl -u borgbackup.timer
  ```

## Notes

- Modify the `WorkingDirectory` path in `borgbackup.service` to point to your actual backup script location.
- Ensure the backup script (`automated_backups.sh`) is executable and properly configured.
- Adjust the `OnCalendar` directive in `borgbackup.timer` if a different schedule is required.

For more information on systemd timers, refer to the [systemd.timer documentation](https://www.freedesktop.org/software/systemd/man/systemd.timer.html).
