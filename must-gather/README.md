# MustGather

This directory contains scripts to collect information for troubleshooting problems and providing support.

## Prerequisites

The kubectl command line tool must be installed and configured to access to your cluster and project/namespace that you selected.

## Available scripts

### Gathering all information ###

Run the `./gather.sh` command to collect detailed information from the cluster where Automation Decision Services is installed into a `tar.gz` file. This file can be sent to the IBM support team.

See `./gather.sh -h` to check how to use this command.  You can limit the amount of logs gathered with the `-s` option.  

> Note: It is recommanded to use the `-d` option to specify a dedicated work directory for the command.

### Troubleshooting common issues for Automation Decision Services

Run the `./troubleshoot_common_causes.sh` command to investigate various known issues that might affect Automation Decision Services.

This command searches the project for:
 - dependent services in a bad status
 - issues with Automation Decision Services pods

### Getting Decision Designer ticket IDs and information

To find ticket IDs for all tickets, run the following script:

`./get_ticket_id.sh`

To find a ticket ID for a specific ticket, for example `1d43f3f4-02c0-40f8-82de-eb3379360efc`, run the script as shown below:

`./get_ticket_id.sh 1d43f3f4-02c0-40f8-82de-eb3379360efc`.

Use the `-d` option to search in the logs that are gathered by the `gather.sh` script, instead of connecting to a Kubernetes cluster directly.

For each ticket ID, you can find a **correlationId** that is useful for investigating the requests across various services:

`For further logs, search with correlationId=fa81eeb1d50c5e95239b93982352655f`

When you run the script with a specific ticket ID, you can also have extra information related to a pod:

`Found ticket id in pod/ads-ads-rest-api-6488d8f7cf-kwjzf`

If you want the script to automatically search for a value of **correlationId** in all Automation Decision Services pods, add the `-v` flag:

`./get_ticket_id.sh -v`.

This command saves all information related to the ticket in /tmp/ads/<ticket_id>.log. 
You can specify an output directory with the -o parameter.

For example: 

`./get_ticket_id.sh -v -o "/my/directory/for/ads_logs"`

### Getting decision runtime incident IDs and information

To find incident IDs for all incidents, run the following script:

`./get_incident_id.sh`

To find an incident ID for a specific incident, for example `8997c356-c42c-462f-a43a-9feefe5d2bec`, run the script as shown below:

`./get_ticket_id.sh 8997c356-c42c-462f-a43a-9feefe5d2bec`

Use the `-d` option to search in the logs that are gathered by the `gather.sh` script, instead of connecting to a Kubernetes cluster directly.

By default, the incident is also saved in /tmp/ads/<incident_id>.log

### Using the json2log command

The Automation Decision Services pods produce logs in the `json` format.  It might not be easy to read these logs that are produced by the `kubectl logs` command.

The `json2log` command is a tool that converts the `json` log lines into a more human-readable format. This command requires Python 3.
Here's how you can run the command:

`kubectl logs -l app.kubernetes.io/name=ads-rest-api -c rest-api | ./json2log`

