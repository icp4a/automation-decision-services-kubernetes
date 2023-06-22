# Must Gather

This directory contains various scripts to be used in the Must Gather context.

## Prerequisites

- You must have kubectl command line installed
- Connected to your cluster and appropriate project/namespace selected

## Available scripts

### Gather all ###

Execute the `./gather.sh` command to gather all details from the cluster where ADS is installed into a `tar.gz` file that can be sent to the IBM support team.

See `./gather.sh -h` to read the usage details of this command.  You can limit the amount of logs gathered with the `-s` option.  It is recommanded to use the `-d` option to specify a dedicated work directory for the command.

### Troubleshoot common ADS issues

Execute the `./troubleshoot_common_causes.sh` command to investigate across various known issues that may affect ADS services

This will search inside the project for:
 - dependent services in a bad status
 - issues with ADS pods

### Get Designer Ticket ID information

Search for all tickets, execute `./get_ticket_id.sh`
Search for a ticket `1d43f3f4-02c0-40f8-82de-eb3379360efc` , execute `./get_ticket_id.sh 1d43f3f4-02c0-40f8-82de-eb3379360efc`.

Use the `-d` option to search in logs gathered by the `gather.sh` script instead of connecting to a Kubernetes cluster directly.

For each found ticket-id, you will find a **correlationId** information that will be useful to investigate the requests across various services:

`For further logs, search with correlationId=fa81eeb1d50c5e95239b93982352655f`

When executed on a given ticket-id, you also have extra information related to pod in which we found it like:

`Found ticket id in pod/ads-ads-rest-api-6488d8f7cf-kwjzf`

If you want the script to automatically search for correlationId value in all ADS pods, add the `-v` flag as following `./get_ticket_id.sh -v`

NB: this command save all information related to the ticket in /tmp/ads/<ticket_id>.log (you can specify an output directory with -o parameter)

Ex: `./get_ticket_id.sh -v -o "/my/directory/for/ads_logs"`

### Get Runtime Incident ID information

Search for all incidents, execute `./get_incident_id.sh`
Search for an incident `8997c356-c42c-462f-a43a-9feefe5d2bec` , execute `./get_ticket_id.sh 8997c356-c42c-462f-a43a-9feefe5d2bec`

Use the `-d` option to search in logs gathered by the `gather.sh` script instead of connecting to a Kubernetes cluster directly.

By default, incident also saved in /tmp/ads/<incident_id>.log

### json2log

The ADS pods produce logs in the `json` format.  This can be hard to read when reading these logs
directly with the `kubectl logs`.  The `json2log` command is a tool that converts the `json` log lines into a more human-readable format.

Usage:

`kubectl logs -l app.kubernetes.io/name=ads-rest-api -c rest-api | ./json2log`

This command requires Python 3.