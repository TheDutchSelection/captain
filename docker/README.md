# Captain Docker Images
## Discoverer
Is responsible for writing out environment files from Etcd values.
## Iptables Rules Writer
Is responsible for writing rules for Iptables based on Etcd values.
## Publisher
Is responsible for publishing values to Etcd
## Pull Messenger
Decides if a new image should be pulled from a given image, based on Etcd values.
## Restart Orchestrator
This image runs on a Etcd host and monitors all need_restart values and sets restart values accordingly.
## Services Base
A base for the other captain images.
## Value Setter
Sets specific values to Etcd.
## Watcher
Watches a specific key in Etcd to get a specific value.
