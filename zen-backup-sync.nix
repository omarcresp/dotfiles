{ config, pkgs, lib, ... }:

let
  backupDir = "$HOME/.zen";
  remoteUrl = "s3://nixos-jackcres-backups/zen-backup";
  gpgKey = "YOUR_GPG_KEY_ID";
  logFile = "/var/log/zen-backup.log";

  backupScript = pkgs.writeScriptBin "backup-zen" ''
    #!/usr/bin/env bash
    set -euo pipefail

    BACKUP_DIR="${backupDir}"
    REMOTE_URL="${remoteUrl}"
    GPG_KEY="${gpgKey}"
    LOG_FILE="${logFile}"

    echo "============================================" >> "$LOG_FILE"
    echo "Starting Zen backup at $(date)" >> "$LOG_FILE"

    # Check network connectivity
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
      echo "Network is unreachable. Exiting." >> "$LOG_FILE"
      exit 1
    fi

    # Perform backup with error handling
    if ! ${pkgs.duplicity}/bin/duplicity \
      --encrypt-key "$GPG_KEY" \
      --full-if-older-than 1M \
      --asynchronous-upload \
      --log-file "$LOG_FILE" \
      "$BACKUP_DIR" "$REMOTE_URL"; then
      echo "Backup failed. Check $LOG_FILE for details." >&2
      exit 1
    fi

    # Clean up old backups
    ${pkgs.duplicity}/bin/duplicity remove-older-than 1M --force "$REMOTE_URL"

    echo "Zen backup completed successfully at $(date)" >> "$LOG_FILE"
  '';

  restoreScript = pkgs.writeScriptBin "restore-zen" ''
    #!/usr/bin/e${remoteUrl}
    set -euo ${gpgKey}

    LOG_FILE="${logFile}"
    BACKUP_DIR="${backupDir}"
    REMOTE_URL="${remoteUrl}"

    echo "============================================" >> "$LOG_FILE"
    echo "Starting Zen restore at $(date)" >> "$LOG_FILE"

    # Check network connectivity
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
      echo "Network is unreachable. Exiting." >> "$LOG_FILE"
      exit 1
    fi

    # Perform restore with error handling
    if ! ${pkgs.duplicity}/bin/duplicity \
      --encrypt-key "$GPG_KEY" \
      restore \
      --log-file "$LOG_FILE" \
      "$REMOTE_URL" "$BACKUP_DIR"; then
      echo "Restore failed. Check $LOG_FILE for details." >&2
      exit 1
    fi

    echo "Zen restore completed successfully at $(date)" >> "$LOG_FILE"
  '';

  syncScript = pkgs.writeScriptBin "sync-zen" ''
    #!/usr/bin/env bash
    set -euo pipefail

    SYNC_DIR="${backupDir}"
    REMOTE_URL="${remoteUrl}"
    LOG_FILE="${logFile}"

    echo "============================================" >> "$LOG_FILE"
    echo "Starting Zen sync at $(date)" >> "$LOG_FILE"

    # Check network connectivity
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
      echo "Network is unreachable. Exiting." >> "$LOG_FILE"
      exit 1
    fi

    # Perform sync with error handling and conflict resolution
    if ! ${pkgs.rclone}/bin/rclone sync \
      --update \
      --use-server-modtime \
      --log-file "$LOG_FILE" \
      --log-level INFO \
      --transfers 4 \
      --checkers 8 \
      --contimeout 60s \
      --timeout 300s \
      --retries 3 \
      --low-level-retries 10 \
      "$SYNC_DIR" "$REMOTE_URL"; then
      echo "Sync failed. Check $LOG_FILE for details." >&2
      exit 1
    fi

    echo "Zen sync completed successfully at $(date)" >> "$LOG_FILE"
  '';

  notifyScript = pkgs.writeScriptBin "notify-zen" ''
    #!/usr/bin/env bash
    set -euo pipefail

    OPERATION="$1"
    STATUS="$2"
    LOG_FILE="$3"

    ${pkgs.libnotify}/bin/notify-send \
      -u normal \
      "Zen $OPERATION" \
      "$STATUS. Check $LOG_FILE for details."
  '';

in
{
  home.packages = with pkgs; [
    duplicity
    rclone
    backupScript
    restoreScript
    syncScript
    notifyScript
  ];

  # Backup job
  systemd.user.services.zen-backup = {
    Unit = {
      Description = "Backup Zen folder";
      After = "network-online.target";
      Wants = "network-online.target";
    };
    Service = {
      ExecStart = "${backupScript}/bin/backup-zen";
      ExecStopPost = "${notifyScript}/bin/notify-zen 'Backup' '$EXIT_STATUS' '${logFile}'";
      Environment = [
        "PATH=${lib.makeBinPath [ pkgs.duplicity pkgs.coreutils pkgs.inetutils ]}"
      ];
      IOSchedulingClass = "idle";
      CPUSchedulingPolicy = "idle";
      Restart = "on-failure";
      RestartSec = "10m";
    };
  };

  systemd.user.timers.zen-backup = {
    Unit = {
      Description = "Timer for Zen folder backup";
    };
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  # Sync job
  systemd.user.services.zen-sync = {
    Unit = {
      Description = "Sync Zen folder";
      After = "network-online.target";
      Wants = "network-online.target";
    };
    Service = {
      ExecStart = "${syncScript}/bin/sync-zen";
      ExecStopPost = "${notifyScript}/bin/notify-zen 'Sync' '$EXIT_STATUS' '${logFile}'";
      Environment = [
        "PATH=${lib.makeBinPath [ pkgs.rclone pkgs.coreutils pkgs.inetutils ]}"
      ];
      IOSchedulingClass = "idle";
      CPUSchedulingPolicy = "idle";
      Restart = "on-failure";
      RestartSec = "5m";
    };
  };

  systemd.user.timers.zen-sync = {
    Unit = {
      Description = "Timer for Zen folder sync";
    };
    Timer = {
      OnCalendar = "hourly";
      Persistent = true;
      RandomizedDelaySec = "5m";
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  # Log/var/log/zen-*.log
  services.logrotate = {
    enable = true;
    settings = {
      "${logFile}" = {
        rotate = 7;
        weekly = true;
        compress = true;
        delaycompress = true;
        missingok = true;
        notifempty = true;
      };
    };
  };
}