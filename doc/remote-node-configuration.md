# Sharing a Node

The [kachery network](./doc/network.md) is a network of peer *nodes*, which are running instances of the
kachery daemon software. However, users don't interact with the daemon directly to share data. Instead,
[as discussed in the kachery-client documentation](./doc/client-howto.md#node-vs-client),
the user issues commands to the node through a client.

In the basic installation, the daemon and the client run on the same machine, so the user never notices
the distinction. However, the kachery system supports a shared-node configuration which is appropriate for particularly
close collaborators--such as members of the same lab--who already have access to a common storage
resource that can be appropriately used on the kachery network. In the right circumstances, this
setup can reduce overall data storage use and the number of administrative tasks required.

## Requirements

The basic requirement for a shared-node configuration is that the shared node be running on a file system
that all client users are permitted to read.

* Client users need to be able to mount the shared node's storage directory into their filesystems (e.g. as an NFS mount).
* Client users need to belong to an access group that can be given read access to the shared storage directory.
* Clients need to be able to send network traffic to the shared node (which may require e.g. a VPN).
* Latency for reading the shared storage must be acceptable.

In addition, every user with client access to the node will act as that node when interacting with the
wider kachery network. They will use the node's [permissions](./doc/security.md) on every channel it belongs to.
So allowing access to a shared node requires trusting the client users not to behave inappropriately (whether through
malice or negligence).

## Advantages and Disadvantages

### Advantages

* A shared node uses the same storage for all clients, reducing overall storage use.
* Clients can avoid the need to install the daemon software locally.
* Channel permissions are easier to administer, since only the shared node needs to be added to channels.
* Only one node needs to be upgraded when new versions of the daemon software are released.

### Disadvantages

* The shared node is a single point of failure: if it becomes inaccessible, no client can use it.
* Storage use is reduced, but less redundancy means less resilience against data loss.
* Channel administration becomes more complicated when different clients would want to use different channels:
  * The shared node must belong to all the channels used by any client.
  * Clients must be disciplined about specifying channels for their actions (e.g. use the `--upload-to-channel` parameter for `kachery-load` commands).
* Mounting a non-local filesystem may introduce latency in file access.
* Clients won't have local versions of their files, so if they cannot mount the shared storage, they won't have file access. (This can present challenges for offline work.)

## How-to

### Setting up the shared daemon

* Install a kachery daemon on the shared resource, following the same [procedure used for individual nodes](./doc/hostKacheryNode.md), with these alterations:
  * Make sure the daemon's `KACHERY_STORAGE_DIR` is readable by all intended client users
  * When launching the daemon, use the `--auth-group` parameter to indicate that this group will have access to the daemon.
* So, assuming the client users' accounts all belong to the `clientusers` group, you would need to:
```bash
$ chgrp clientusers $KACHERY_STORAGE_DIR
$ kachery-daemon-start --label <WHATEVER YOU CHOOSE> --owner <YOUR GOOGLE ACCOUNT ID> --auth-group clientusers
```
* Optionally, you may wish to specify a non-default port for the daemon using the `KACHERY_DAEMON_PORT` environment variable (the default is 20431).
* Use kacheryhub to configure the node's channel permissions, including [creating a new channel, if needed](./doc/createKacheryChannel.md).

### Setting up the client machines

Client machines can be configured to use a remote daemon just by setting a few environment variables.

* Ensure the client is not actually attempting to communicate with a local node.
* Activate a Python virtual environment, if desired.
* Install the `kachery-client` python module using [the client installation instructions](https://github.com/kacheryhub/kachery-client/blob/main/README.md)
* Set the `KACHERY_DAEMON_PORT` and `KACHERY_DAEMON_HOST` environment variables to the port and hostname of your shared node.
  * If this is set correctly, `nc -vz $KACHERY_DAEMON_HOST $KACHERY_DAEMON_PORT` should succeed.
* Mount the shared kachery storage directory on your local filesystem.
* Set the `KACHERY_STORAGE_DIR` on the client machine to match the location where the shared storage directory is mounted.
* Client commands should now work properly--share some files!

Here is a fully worked example, assuming the shared node is available at `kacherybox` port 20499:
```bash
$ conda create --name kachery-client-env python=3.8
[...]
$ conda activate kachery-client-env
(kachery-client-env) $ pip install kachery-client numpy
[...]
(kachery-client-env) $ export KACHERY_DAEMON_HOST=kacherybox
(kachery-client-env) $ export KACHERY_DAEMON_PORT=20499
(kachery-client-env) $ nc -vz $KACHERY_DAEMON_HOST $KACHERY_DAEMON_PORT
Connection to kacherybox 20499 port [tcp/*] succeeded!
(kachery-client-env) $ mkdir -p /home/myuser/shared-kachery-storage
(kachery-client-env) $ mount /network/shared/kachery/storage/dir /home/myuser/shared-kachery-storage
(kachery-client-env) $ export KACHERY_STORAGE_DIR=/home/myuser/shared-kachery-storage
(kachery-client-env) $ kachery-cat sha1://A-VALID-SHA1-URI
File Contents
(kachery-client-env) $ 
```
