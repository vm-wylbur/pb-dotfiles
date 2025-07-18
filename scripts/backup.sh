#!/bin/bash

# based on https://blog.interlinked.org/tutorials/rsync_time_machine.html
# PB, 2018-10-10
# adapted for petunia, henwen, porky
#
# configurable backup disk names
# backup_disk_names="archives-2019"
backup_disk_names="backup"
local_machine_name="porky"

datestr=$(date "+%Y-%m-%dT%H_%M_%S")

backup_home="${HOME}"
rsync_opts="--archive --one-file-system --hard-links --delete "
rsync_opts+="--delete-excluded --safe-links --partial --progress "
rsync_opts+="--relative --stats"

# check for specific volume mounted anywhere.
backup_mntd=$(ls -1 /Volumes/ | egrep "${backup_disk_names}")
if [ -z "$backup_mntd" ] ; then
    echo "there is no backup disk mounted"
    exit 1
fi

backup_path="/Volumes/${backup_mntd}/${local_machine_name}-backups"
if [ ! -d "$backup_path" ]; then
    mkdir -p "$backup_path"
fi

logfile="$HOME/var/log/backup-${datestr}.log"
backup_excludes="${backup_home}/dotfiles/share/backup-excludes"

backup_current="${backup_path}/current"
backup_final="${backup_path}/back-${datestr}"
dirs_to_backup="${backup_home}"

## this was a bad idea, looking for the incomplete.
existing_incompletes=$(find ${backup_path} -maxdepth 1 -name 'incomplete_back-*')
if [[ "$existing_incompletes" ]] ; then
    backup_incomplete=$(echo "$existing_incompletes" | gsort | tail -n1)
    echo "using existing incomplete backup: ${backup_incomplete}"
else
    backup_incomplete="$backup_path/incomplete_back-${datestr}/"
fi

if [ -n "${backup_current}" ]; then
    link_dest="${backup_current}"
else
    link_dest=""
fi

# todo: ignore error 24 bc that's just filesystem churn.

echo "Backing up to tmp, will be ${backup_final}"
set -o xtrace
rsync $rsync_opts \
      --link-dest="${link_dest}" \
      --exclude-from="${backup_excludes}" \
      ${HOME} ${backup_incomplete}

exitcode=$?
set +x
echo "finished rsync with exit code=$exitcode"

if [ $exitcode -eq 0 ]  || [ $exitcode -eq 24 ] ; then
  mv "${backup_incomplete}" "${backup_final}" \
    && rm -f "${backup_current}" \
    && ln -sf "${backup_final}" "${backup_current}" \
    && rm -rf "${backup_path}/incomplete_back-*" \
    && echo "back done: ${backup_final}"
else
    echo "backup FAILED."
fi


# TODO: if successful add rm -rf "${backup_path}/incomplete_back-*"
# done.
