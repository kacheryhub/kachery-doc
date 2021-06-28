# kachery-client documentation

**QUERY: HOW IS CONFIGURATION SET? WHAT'S UP WITH THE PROBE STUFF?**

## How to set up a kachery-client instance

Setting up a kachery-client instance is straightforward. We recommend that
all installation take place in a conda environment or other virtual environment,
to ensure minimal issues with dependencies and upgrades; please ensure a python
version of 3.8 or above.

After activating the virtual environment, install [numpy](https://numpy.org/)
and the `kachery-client` package, both of which are available on
[pypi](https://pypi.org/)

(SET UP ENVIRONMENT VARIABLES? WHAT'S THE MINIMUM CONFIGURATION REQUIREMENT?)

You can now access the kachery network via the command-line client.

Full example:

```bash
conda create --name kachery-client-env python=3.8
conda activate kachery-client-env
pip install --upgrade numpy kachery-client
```

### System requirements

[DO WE NEED A KACHERY STORAGE DIRECTORY LOCALLY?]

### Config file

**QUERY: I don't know how this works** need to look into
**WHERE DOES THE NODE ID COME FROM?** When is it checked against the connected node?

## kachery-client commands

kachery-client can be used over the command line to interact with
files stored in the kachery network. The following commands are
defined:

* `cat-file SHA1-URI`: Prompts the attached node to place a copy of the file identified by
`SHA1-URI` into the kachery storage directory. Once the file is in place, `cat-file` then
prints its contents to the terminal.

  For instance,

  > `kachery-client cat-file sha1://f728d5bf1118a8c6e2dfee7c99efb0256246d1d3/studysets.json`
  
  will (assuming the client is connected to a node which belongs to a channel sharing
[spikeforest](https://spikeforest.flatironinstitute.org) data) display a JSON file describing the
set of recordings in that project.

* `load-file SHA1-URI`: As with `cat-file`, this prompts the node to obtain a copy of the file. However,
instead of displaying its contents to the screen, it prints the full local filesystem path to
where the file can be found.
  
  > `kachery-client load-file sha1://f728d5bf1118a8c6e2dfee7c99efb0256246d1d3/studysets.json`
  
  would print some variation on
`/KACHERY/STORAGE/DIRECTORY/sha1/f7/28/d5/f728d5bf1118a8c6e2dfee7c99efb0256246d1d3`, while

  > ``cat `kachery-client load-file sha1://f728d5bf1118a8c6e2dfee7c99efb0256246d1d3/studysets.json` ``

  (capturing the returned file path with backticks) will send the local filesystem location of the
studysets.json file to the `cat` command, thus resulting in the exact same output as the
`kachery-client cat-file` command above.
* `store-file LOCAL-FILE`: This causes kachery to make a copy of the file located at `LOCAL-FILE`
and place it in the kachery storage directory. It then prints the resulting SHA1 URL (derived from
hashing the file) to the terminal. This SHA1 URL can then be shared with other users of the kachery network
so that they can request it to be copied to cloud storage for their use.
* `link-file LOCAL-FILE`: As with `store-file`, this makes a file from the local filesystem accessible
to the kachery node. However, instead of making a copy, this creates a soft [??] link within the
kachery storage directory. This avoids having to duplicate the file contents, but comes with the usual
restrictions on links: the source file and the link must be on the same file system, and any changes to
the original file will cause corresponding changes to the linked version. NOTE: this latter property
is potentially very problematic for a content-accessible data store, like kachery; if the original
file is changed, its hashed contents will no longer match the SHA1 where it is located, making it
appear invalid. As such, `link-file` should only be used for files that will not be modified further.
* `generate-node-id`: Generates a new node ID and configures the client to expect to connect
to a node with this ID. **MORE INFO NEEDED HERE**
* `version`: Prints the version number, then exits.

## Node vs Client

The distinction between a *node* and a *client* can
potentially be unclear, in that many of a node's
operations are similar to those a client would carry
out in a client-server architecture. The key distinction
is that a *client* is an instance of `kachery-client`,
while a *node* is an instance of `kachery-daemon`. Moreover:

* Nodes talk to the rest of the nodes in the network as peers;
each client only communicates with its main node.
* Information exchange is conducted through nodes. Clients
never directly upload anything to the network.
* Nodes are members of channels; the client application is
essentially unaware of the existence of kachery channels.
* The client cannot communicate, even with a cloud
storage cache, without a connection to a running daemon/node.
(The client offline mode is only for retrieving data from the
local filesystem--and thus for retrieving files; you cannot
access feeds or mutables otherwise.)

Essentially, the node is aware of itself as part of a community
of other nodes; to the client, its one node is the whole world.

## Client-Node Communication

In order to interact with the kachery network, a client
needs to have access to a node. The node can run on the
same machine as the client, or the client can be configured
to connect with a remote node--for instance in a setup where
a lab uses one central machine as a node and the researchers
have a client running on their individual workstations or
laptops.

For setups where the client is local to the node, XYZ
configuration is needed.

To configure a client to communicate with a remote node,
ABC.

### Offline Mode

A kachery client can be placed in "offline mode" by setting
the environment variable `KACHERY_OFFLINE_STORAGE_DIR` to
a valid path on the client's filesystem. If this environment
variable is set, the kachery client will not attempt to
contact a node, but will only retrieve files from the
offline storage directory (which acts as a local cache).

Note that the value of `KACHERY_OFFLINE_STORAGE_DIR` is
not checked for validity; if it is set to an invalid
path (or one which the user running `kachery-client`
cannot read) then the client will be in offline mode
but will not be able to retrieve any files.

## Environment variables governing kachery client

* `KACHERY_STORAGE_DIR`: If set, this defines the directory in
which the client will look for files locally before attempting
to obtain them from the node. QUERY: The environment variable
will be honored over the config file.
* `KACHERY_DAEMON_PORT`: If set, this variable will define an
alternate port to use when connecting to the kachery daemon (node).
* `KACHERY_DAEMON_HOST`: If set, this variable will define the
host on which to look for the node. If not set, the daemon
is assumed to exist on localhost (i.e. the node is assumed
to be running on the same machine as the client). **CONFIRM**
* `KACHERY_TEMP_DIR`: If set, temporary files will be stored in
this directory.
* `KACHERY_KEEP_TEMP_FILES`: When this variable is set to 1,
the kachery client will not attempt to clear out temporary files.
* `KACHERY_OFFLINE_STORAGE_DIR`: If set, puts the client in
offline mode, in which it will not attempt to connect to a
node. The value of the variable should be the path to an
offline storage directory.
