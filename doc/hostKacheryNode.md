# How to host a kachery node

Most of the action in the kachery network involves communication between
[nodes](https://github.com/kacheryhub/kachery-doc/blob/main/doc/node.md). These are the network peers that exchange information
and maintain offline storage in the content-addressable database; nodes
may also optionally be the owners of [feeds](https://github.com/kacheryhub/kachery-doc/blob/main/doc/feeds.md) or provide
[task execution resources](https://github.com/kacheryhub/kachery-doc/blob/main/doc/tasks.md).

A kachery node can be hosted on anything from a modest user machine
(such as a laptop) to a large shared lab resource with abundant
network-attached storage. A straightforward model is to run
a node on your individual workstation or laptop.

You can host a kachery node by running a kachery daemon on your computer. Once the daemon is running, you can register the node on kacheryhub and configure the node using the web interface.

## Requirements

Tested on Linux, should also work on macOS and Windows Subsystem for Linux

* Python >=3.8
* NumPy
* Nodejs >=12 (available on conda-forge; see below)

To interact with the kachery network, you will also need a free Google account for authentication with kacheryhub.

## Installation using Conda

We highly recommend using Conda or another virtual-environment provider
when setting up your node, for ease of updates and to avoid potential
version conflict issues.

The basic setup looks like this:

```bash
conda create --name kachery-node-env python=3.8
conda activate kachery-node-env

conda install -c conda-forge nodejs

# On MacOS, if the above command does not give you nodejs >= 12:
# conda install nodejs -c conda-forge --repodata-fn=repodata.json

# install numpy
pip install numpy

# Install/update kachery-daemon
pip install --upgrade kachery-daemon

# You may also choose to install kachery-client, if you intend
# to use the same virtual environment for all kachery interactions.
pip install --upgrade kachery-client
```

## Installation without conda

It is also possible to install without conda. Just make sure that the above requirements are met on your system, and then `pip install --upgrade kachery-daemon` as above.

## Running the daemon

Ensure you are in the correct conda environment, then:

```bash
# Start the daemon
kachery-daemon-start --label <WHATEVER YOU CHOOSE> --owner <YOUR GOOGLE ACCOUNT ID>
# The label flag can have any value: it will be visible on kacheryhub, so it should be
# appropriate for public use, but it need not be unique.
# The owner flag should be passed a full Google account address, e.g.:
# --owner sergey.brin@google.com
```

Leave this running, and in another terminal window, use:
> `kachery-daemon-info`
to print the node ID of the running node.

You may find it convenient to use [tmux](https://github.com/tmux/tmux/wiki)
for terminal session management, instead of opening additional terminal
windows.

## Configuring on kacheryhub

Log in to kacheryhub with the same google account you passed for the
`--owner` flag when starting
the daemon, then click the `Register a new node` button and follow the
instructions on screen to register your node.

You can now click on your node ID to join channels. Indicate the roles
you would like to perform, and inform the channel owner (through another
means of communication) of your name and node id. Once you've been authorized,
you can start using the client commands discussed in the
[kachery-client documentation](https://github.com/kacheryhub/kachery-doc/blob/main/doc/client-howto.md).

Other more advanced options are available, such as specifying listen ports (see below).

## Advanced configuration

[Limiting the size of the storage cache](https://github.com/kacheryhub/kachery-doc/blob/main/doc/cache-size-limit.md)

Environment variables for the daemon

* `KACHERY_STORAGE_DIR` **(optional)** - Refers to an existing directory on your local computer. This is where kachery stores all of your cached files. If not set, files will be stored in the default location: `$HOME/kachery-storage`.
* `KACHERY_DAEMON_PORT` **(optional)** - Port that the daemon will listen on. If not provided, a default port will be used.

Environment variables for the client

* `KACHERY_DAEMON_PORT` **(optional)** - Port for connecting to the daemon (should match the above)
* `KACHERY_DAEMON_HOST` **(optional)** - Host for connecting to the daemon
* `KACHERY_TEMP_DIR` **(optional)** - Existing directory where temporary files are stored - not the same as `KACHERY_STORAGE_DIR`.
