# loki-ci-logs-collector
Deployment and collection of logs through loki

## How to deploy it

```sh
$ oc apply -f manifests
```


## How to collect the logs

1. port forward to a loki instance:
   ```sh
   oc port-forward loki-0 3100:3100
   ```

2. collect the logs:
   ```sh
   $ ./collect.sh
   ```

## How to query loki

1. `export LOKI_ADDR=http://localhost:3100` (don't forget to port forward)
1. `logcli labels` to see all labels (https://github.com/grafana/loki/blob/master/docs/getting-started/logcli.md)
1. `logcli labels container_name` to get a list of all values for container_name label
1. `logcli query '{container_name="machine-api-operator"}'` to get logs of machine-api-operator
1. `logcli query` has `--limit` and `--since` options to control how many log lines and since get listed

## Known issues

- In order to get all logs, loki storage needs to be ready before promtail starts uploading tails.
  Thus, all promtail pods have init container part that waits until the second loki instances is ready.
  You might need to point the ready check for the last instance in case you want to increase number
  of stateful set instances (defaults to 2).
- If loki storage gets completely deleted and re-created again, promtail will not re-uploading all
  the log lines but only the latest. In order to get all the logs again (resp. those that are still
  available inside nodes), one needs to delete all loki-promtail DS instances, delete all /run/promtail/positions.yaml
  on each node and re-create DS instances. This way, all the logs get collected again. However, loki
  storage will contain duplicates.

## Credit

Manifests originate from https://github.com/brancz/loki-jsonnet.
In addition, the following bits are added:
- loki-promtail init container checking readiness of loki
- pvc for all loki stateful instances
- adding privileged SSC so promtail instances can run in OpenShift
