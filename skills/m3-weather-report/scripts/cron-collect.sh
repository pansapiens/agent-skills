#!/bin/bash
# Warm the weather-report cache from a cron job OUTSIDE M3.
#
# M3 itself has no usable scheduler for this: crontab is refused by PAM and
# SLURM's scrontab is disabled cluster-wide. So the recurring half lives on a
# machine you control -- a workstation, a VM, a lab server -- and reaches in over
# ssh. This script is what that machine's crontab calls.
#
# It does not run the collection over the ssh connection. It submits an sbatch
# job and returns, because collection is a few minutes of database querying and
# login nodes are shared. A dropped connection then costs nothing.
#
# Install on the EXTERNAL machine:
#
#   ssh-keygen -t ed25519 -f ~/.ssh/m3-weather -N ''      # no passphrase: cron cannot type one
#   ssh-copy-id -i ~/.ssh/m3-weather.pub you@m3.massive.org.au
#   crontab -e
#     M3_USER=you
#     M3_PROJECT=/fs04/scratch2/df22/you/m3-weather-report
#     17 6 * * *  /path/to/cron-collect.sh >>~/m3-weather-cron.log 2>&1
#
# Run it once by hand first. A cron job that has never worked interactively is
# just a silent failure on a schedule.

set -euo pipefail

M3_USER="${M3_USER:?set M3_USER to your M3 (HPC ID) username}"
M3_HOST="${M3_HOST:-m3.massive.org.au}"
M3_KEY="${M3_KEY:-${HOME}/.ssh/m3-weather}"
M3_PROJECT="${M3_PROJECT:?set M3_PROJECT to the report checkout on M3}"
M3_ACCOUNT="${M3_ACCOUNT:-df22}"
M3_PARTITION="${M3_PARTITION:-genomics}"
M3_QOS="${M3_QOS:-genomics}"
PERIOD="${PERIOD:-daily}"
# Absolute, so an unattended run cannot start a second book somewhere else and
# hand everybody a new pseudonym. This file holds real names: keep it 0600.
M3_PSEUDONYMS="${M3_PSEUDONYMS:-${M3_PROJECT}/pseudonyms.toml}"

# Cron's environment is not your shell's. Fail loudly here rather than three
# weeks later when someone notices the cache stopped.
[ -r "${M3_KEY}" ] || { echo "no readable ssh key at ${M3_KEY}" >&2; exit 1; }

# Collecting yesterday-to-now rather than a clean midnight boundary keeps today's
# partial day in the cache too; collect.py refetches the current day every run
# because it is still changing.
#
# The digest runs straight after, purely so the pseudonym book keeps up: anyone
# new to the cluster gets their handle minted on the day they appear rather than
# whenever somebody next writes a bulletin. --names anon is the default, but it
# is stated here because this is the unattended path and the one place where
# getting it wrong would put real names into a file nobody was watching.
ssh -i "${M3_KEY}" -o BatchMode=yes -o StrictHostKeyChecking=accept-new \
    "${M3_USER}@${M3_HOST}" \
    "sbatch --parsable \
        --job-name=m3-weather-collect \
        --account=${M3_ACCOUNT} \
        --partition=${M3_PARTITION} \
        --qos=${M3_QOS} \
        --ntasks=1 --cpus-per-task=1 --mem=4G --time=0-00:30 \
        --output=${M3_PROJECT}/cache/collect-%j.out \
        --wrap 'set -euo pipefail
            cd ${M3_PROJECT}
            PERIOD_DIR=\$(.venv/bin/python \
                .agents/skills/m3-weather-report/scripts/collect.py \
                --period ${PERIOD} --ending now --cache-dir cache | tail -1)
            .venv/bin/python \
                .agents/skills/m3-weather-report/scripts/digest.py \
                \"\${PERIOD_DIR}\" --names anon --pseudonyms ${M3_PSEUDONYMS}'"
