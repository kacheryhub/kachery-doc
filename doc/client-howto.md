# kachery-client

[kachery-client](https://github.com/kacheryhub/kachery-client) is the Python package used on a workstation to interact with the local kachery storage and the larger kachery network.

## Installation and setup

See the [installation instructions](https://github.com/kacheryhub/kachery-client/blob/main/README.md).
## kachery-client commands

kachery-client can be used over the command line to interact with
files stored locally and in the kachery network. The following commands are
defined:

* `kachery-cat <SHA1-URI>`: Prompts the attached node to place a copy of the file identified by
`SHA1-URI` into the kachery storage directory. Once the file is in place, it then
prints its contents to the terminal.

  For instance,

  > `kachery-cat sha1://f728d5bf1118a8c6e2dfee7c99efb0256246d1d3/studysets.json`
  
  will (assuming the client is connected to a node which belongs to a channel sharing
[spikeforest](https://spikeforest.flatironinstitute.org) data) display a JSON file describing the
set of recordings in that project.

* `kachery-load <SHA1-URI>`: As with `kachery-cat`, this prompts the node to obtain a copy of the file. However,
instead of displaying its contents to the screen, it prints the full local filesystem path to
where the file can be found.
  
  > `kachery-load sha1://f728d5bf1118a8c6e2dfee7c99efb0256246d1d3/studysets.json`
  
  would print some variation on
`/KACHERY/STORAGE/DIRECTORY/sha1/f7/28/d5/f728d5bf1118a8c6e2dfee7c99efb0256246d1d3`, while

  > ``cat `kachery-load sha1://f728d5bf1118a8c6e2dfee7c99efb0256246d1d3/studysets.json` ``

  (capturing the returned file path with backticks) will send the local filesystem location of the
studysets.json file to the `cat` command, thus resulting in the exact same output as the
`kachery-cat` command above.
* `kachery-store <LOCAL-FILE>`: This causes kachery to make a copy of the file located at `LOCAL-FILE`
and place it in the kachery storage directory. It then prints the resulting SHA1 URI (derived from
hashing the file) to the terminal. This SHA1 URI can then be shared with other users of the kachery network
so that they can request it to be copied to cloud storage for their use.
* `kachery-link <LOCAL-FILE>`: As with `kachery-store`, this makes a file from the local filesystem accessible
to the kachery node. However, instead of making a copy, this creates a link within the
kachery storage directory. This avoids having to duplicate the file contents, but comes with the usual
restrictions on links: the source file and the link must be on the same file system, and any changes to
the original file will cause corresponding changes to the linked version. NOTE: If the original
file is changed, its hashed contents will no longer match the SHA1 where it is located, kachery will detect the change invalidate the link. As such, `link-file` should only be used for files that will not be modified further.
* `kachery-client version`: Prints the version number, then exits.

## Python usage

```python
import kachery_client as kc
import numpy as np

# Store/load a kachery file
uri_file = kc.store_file('/tmp/file.dat')
local_path = kc.load_file(uri_file)

# Store/load text
uri_text = kc.store_text('random-string')
txt = kc.load_text(uri_text)

# Store/load json-able Python object
uri_json = kc.store_json({'a': ['random', {'ob': 'ject'}]})
x = kc.load_json(uri_json)

# Store/load numpy array
uri_npy = kc.store_npy(np.ones((20, 30)))
y = kc.load_npy(uri_npy)

# Store/load pickle-able Python object
uri_pkl = kc.store_pkl({'a': np.ones((20, 30))})
y = kc.load_pkl(uri_pkl)

# Create a new feed and load a subfeed
f = kc.create_feed()
sf = f.load_subfeed('subfeed-name')

# Append messages
sf.append_message({'message': 1})
sf.append_messages([{'message': 2}, {'message': 3}])

# Get feed/subfeed uri
uri_f = f.uri
uri_sf = sf.uri

# Load a subfeed from uri and read messages
sf2 = kc.load_subfeed(uri_sf)
messages = sf2.get_next_messages()

# Load a feed from uri
f2 = kc.load_feed(uri_f)
sf3 = f2.load_subfeed('subfeed-name')
messages2 = sf3.get_next_messages()

# Get/set local-only mutables
kc.set('key1', {'value': 1})
y = kc.get('key1')
```

## Node vs Client

The distinction between a *node* and a *client* can
potentially be unclear, in that many of a node's
operations are similar to those a client would carry
out in a client-server architecture. The key distinction
is that a *client* is an instance of `kachery-client`,
while a *node* corresponds to a running `kachery-daemon`. Moreover:

* Nodes talk to the rest of the nodes in the network as peers;
each client only communicates with its main node.
* Information exchange is conducted through nodes. Clients
never directly upload anything to the network.
* Nodes are members of channels; the client application is
essentially unaware of the existence of kachery channels (except when requesting or providing tasks).
* The client cannot communicate, even with a cloud
storage cache, without a connection to a running daemon/node.
(The client offline mode is only for retrieving data from the
local filesystem--and thus for retrieving files; you cannot
access feeds or mutables otherwise.)

Essentially, the node is aware of itself as part of a community
of other nodes; to the client, its one node is the whole world.

## Client-Node Communication

In order to interact with the kachery network, a client
needs to have access to a node (running daemon). The daemon can run on the
same machine as the client, or the client can be configured
to connect with a remote node--for instance in a setup where
a lab uses one central machine as a node and the researchers
have a client running on their individual workstations or
laptops.

TODO: describe the configuration neeeded in these two cases.

### Offline Mode

A kachery client can be placed in "offline mode" by setting
the environment variable `KACHERY_OFFLINE_STORAGE_DIR` to
a valid path on the client's filesystem. If this environment
variable is set, the kachery client will not attempt to
contact a node, but will only retrieve files from the
offline storage directory (which acts as a local cache).
In this mode, the client will not be able to interact
with feeds, and will not be able to request or provide
tasks.

Note that the value of `KACHERY_OFFLINE_STORAGE_DIR` is
not checked for validity; if it is set to an invalid
path (or one which the user running `kachery-client`
cannot read) then the client will be in offline mode
but will not be able to retrieve any files.

## Environment variables governing kachery client

* `KACHERY_STORAGE_DIR`: If set, this defines the directory in
which the client will look for files locally before attempting
to obtain them from the node. It must coincide with the $KACHERY_STORAGE_DIR
for the running daemon. If the daemon is running on a different
computer it is okay if the literal value of $KACHERY_STORAGE_DIR
is different as long as it is referring to the same underlying
directory.
* `KACHERY_DAEMON_PORT`: If set, this variable will define an
alternate port to use when connecting to the kachery daemon (node).
* `KACHERY_DAEMON_HOST`: If set, this variable will define the
host on which to look for the node. If not set, the daemon
is assumed to exist on localhost (i.e. the node is assumed
to be running on the same machine as the client).
* `KACHERY_TEMP_DIR`: If set, temporary files will be stored in
this directory. Otherwise, a default location (`/tmp/kachery-tmp` or `$KACHERY_OFFLINE_STORAGE_DIR/kachery-tmp`) will be used.
* `KACHERY_KEEP_TEMP_FILES`: When this variable is set to 1,
the kachery client will not attempt to clear out temporary files.
This can be useful for developers when debugging.
* `KACHERY_OFFLINE_STORAGE_DIR`: If set, puts the client in
offline mode, in which it will not attempt to connect to a
node. The value of the variable should be the path to an
offline storage directory.
