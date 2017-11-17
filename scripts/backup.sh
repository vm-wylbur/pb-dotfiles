#!/bin/bash

# based on https://blog.interlinked.org/tutorials/rsync_time_machine.html
# PB, 2016-03-12T19:01
# adapted for petunia
#
# configurable backup disk names: these are names you give the disk when
# you format it.
backup_disk_names="backup-buffer|archives|working-archives|archvies-2018"
local_machine_name="petunia"

backup_home="${HOME}"
rsync_opts="--archive --one-file-system --hard-links --delete "
rsync_opts="${rsync_opts} --delete-excluded --safe-links --partial --progress"
rsync_opts="${rsync_opts} --relative"

# check for specific volume mounted anywhere.
backup_mntd=$(ls -1 /Volumes/ | egrep "${backup_disk_names}")
if [ -z "$backup_mntd" ] ; then
    echo "there is no backup disk mounted"
    exit 1
fi

pbhome="/Users/pball/"
backup_path="/Volumes/${backup_mntd}/${local_machine_name}-backups"
if [ ! -d "$backup_path" ]; then
    mkdir -p "$backup_path"
fi

datestr=`date "+%Y-%m-%dT%H_%M_%S"`
backup_excludes="${backup_home}/dotfiles/bash/backup-excludes"
backup_current="${backup_path}/current"
backup_final="${backup_path}/back-${datestr}"
dirs_to_backup="${backup_home}"

## this was a bad idea, looking for the incomplete.
existing_incompletes=$(gfind ${backup_path} -maxdepth 1 -name 'incomplete_back-*')
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
rsync $rsync_opts \
      --link-dest="${link_dest}" \
      --exclude-from="${backup_excludes}" \
      ${backup_home} \
      ${backup_incomplete}

if [ $? -eq 0 ]  || [ $? -eq 24 ] ; then
    mv "${backup_incomplete}" "${backup_final}" \
	&& rm -f "${backup_current}" \
	&& ln -sf "${backup_final}" "${backup_current}" \
	&& rm -rf "${backup_path}/incomplete_back-*" \
	&& echo "back done: ${backup_final}"
else
    echo "backup FAILED."
fi


# TODO: if successful add rm -rf "${backup_path}/incomplete_back-*"
