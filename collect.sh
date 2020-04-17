#!/bin/sh

function queue() {
  local TARGET="${1}"
  shift
  local LIVE="$(jobs | wc -l)"
  while [[ "${LIVE}" -ge 50 ]]; do
    sleep 1
    LIVE="$(jobs | wc -l)"
  done
  echo "${@}"
  "${@}" | cut -d' ' -f6- | tac >"${TARGET}" &
}

rm -rf logs
mkdir -p logs

export LOKI_ADDR=http://localhost:3100
for filename in $(logcli labels filename); do
  # /var/log/pods/openshift-sdn_sdn-pstzd_34bbaea8-15dc-4d2b-8cfc-5d1631450605/install-cni-plugins/0.log
  logfile=$(echo ${filename#/var/log/pods/} | tr "/" "_")
  # 2020-04-16T18:23:30+02:00 {} 2020-04-16T16:23:29.778263432+00:00 stderr F I0416 16:23:29.778201       1 sync.go:53] Synced up all machine-api-controller components
  queue logs/${logfile} logcli query "{filename=\"${filename}\"}" -q --limit=10000000 --since=48h
done

LIVE="$(jobs | wc -l)"
while [[ "${LIVE}" -ge 1 ]]; do
  sleep 1
  LIVE="$(jobs | wc -l)"
done

tar -czf logs.tar.gz logs
