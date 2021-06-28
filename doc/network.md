# kachery network

![Kachery network](https://docs.google.com/drawings/d/e/2PACX-1vQUnokzwrFHdIO-LjloBjHGbOHE7uaLEh9frzx-WrJbn_z0lIScFhyNWCBYZfj6ofjNHRoJbzjJbFlS/pub?w=960&h=720)

The kachery network is organized into nodes and channels, and each node may belong to one or more channels configured with particular roles.

* A **[node](./node.md)** is usually a running instance of the [kachery daemon](https://github.com/kacheryhub/kachery-daemon) software: think of it as a computer
whose user would like to send or receive files. But a web app or other cloud-deployed entity can also serve as a kachery node. Each node has a unique node ID (the public part of a public/private key pair), an owner ID, and a channel membership configuration. Communication and data transfer on the network takes
place between nodes via channels.

* A **[channel](./channel.md)** defines a community of nodes that exchange files: the channel has
a unique identifier/name and a particular owner who can control access to it. It also
defines associated cloud storage and pub-sub communication resources which allow caching of files and task results and facilitate data transfer and interaction between nodes.

* **[kacheryhub](./hub.md)** is the central website where a user
can create or manage channels, configure nodes, and where a channel owner
can control which nodes have permission to connect to the channel
and what actions they are allowed to take in the channel. This site also acts as a *federated authentication provider* for granting on-demand access to nodes for cloud resources associated with channels.

* **[Storage buckets](./storage-bucket.md)** are cloud resources associated with channels and are used as both a cache and as a [bus](https://en.wikipedia.org/wiki/Bus_(computing))
over which data is transferred between nodes (nodes do not interact directly with each other). For now kachery exclusively uses
[Google Cloud Storage Buckets](https://cloud.google.com/storage/docs/creating-buckets)), but in the future it will be possible to use AWS S3 buckets or other custom object storage solutions.

* **[Publish/subscribe services](./pub-sub.md)** are used for low-latency communication between nodes. Much the same as nodes use a cloud storage
bucket to transfer files, they also communicate requests and status messages
through shared publish/subscribe (pub-sub) message channels. This is presently implemented
through [Ably](https://ably.com/pub-sub-messaging). A node requesting
a file will send a message to the corresponding pub-sub channel,
and nodes with file-uploading permissions listen for requests and respond by uploading
the file to the cloud storage space.

* **[Python scripts](./sharing-data.md)** on a workstation running a node daemon use the `kachery-client` Python package to interact with the network through the daemon. Scripts can request to load data objects (e.g. Numpy arrays or picked Python objects), files, feeds, or task results, which are downloaded from the channel and loaded into Python variables. Scripts can also store files or results to the local kachery storage, which then makes those data available to other authorized nodes on the network (provided that the URIs are known to the other nodes).

* One or more **[task backends](./tasks.md)** can be run on a workstation node in order to make computations or actions available to other authorized nodes in the kachery network (usually a web app node). In order for a remote node to request that a task be run, it must have task-requesting permissionn on a channel one which the task-running node has the task-providing configuration.

* Files and feeds are always stored first in **[local node storage](./local-node-storage.md)** and are only uploaded to a channel if and when that file is requested by an authorized node.

See also:

* [Kachery security model](./security.md)

