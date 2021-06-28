# kachery storage design

The purpose of the kachery system is to facilitate transferring data
between network peers. kachery achieves this purpose by
providing a universally consistent name for each record stored in the
system, and storing these records in a
hierarchy of *caches* of varying size and
accessibility at different component parts of the network.
(It is this hierarchy of caches that gives kachery its name.)

In this page, the term "file" is used to refer specifically to the
[content-addressable information type](./Overview.md#What-It-Does) within
kachery. The term "record" will be used when referring to a file on a
filesystem (which could store any of the three types of information).

## Content-Addressable Storage

Storing and retrieving information consistently across different systems
requires a consistent reference for each record. kachery
provides this through *content-addressable storage*: files are stored
in the kachery system according to a directory structure based on the
SHA1 hash of the file's contents.

Because files are content-addressable, their official location will change whenever
their content changes. It is advisable not to store
files in kachery if they are expected to undergo frequent changes. Store files when
they've reached their final form.

### Feeds

Unlike files, *feeds* are intended to grow. In order to provide each feed with a
consistent location, feeds are identified by an arbitrary character string (which
is actually the public part of a
[public-private key pair](https://en.wikipedia.org/wiki/Public-key_cryptography)).
The node which owns the feed stores the corresponding private key, and uses
it to sign each message that is approved to be added to the feed. See the
[documentation on feeds](./feeds.md) and on the
[feed signature security model](./feeds.md#Feeds) for more details.

### Tasks

Similarly, tasks cannot be stored according to their content: the 'content' would
be the result of evaluating the function, and if we had that,
there would be no need to run the task! Instead, tasks are identified
by a fingerprint composed of the registered task name and the parameters
passed to it (in JSON-serialized format). For more information, see the
[documentation on tasks](./tasks.md).

## Storage Hierarchy

There are two types of cache in a typical kachery use case: a shared
short-term cache, and individual caches local to each node.

The cloud storage cache is a short- to moderate-term cache which is used
to share information between nodes. Individual nodes
transfer data by uploading it to this storage space. For reasons of economy,
this space is expected to have limited capacity (relative to the complete set
of information available on the channel) and some information will be cleared out
of this cache when appropriate. However, it provides ready access to all nodes
for any information that is still in the cache,
even if the original provider of the information is not presently online.

In addition to the shared cache, each node needs local storage: this is where data goes
when the user has added local information to kachery, and where data retrieved
from the kachery network is stored. Because this storage is part of a filesystem
on user-owned hardware, it can be scaled cheaply and information can be
stored for as long as desired. The kachery network will never cycle information
out of local cache unless directed by the user.

### Organization of data within local storage

The root of the information records stored in any particular kachery node's
cache is the directory identified by the `KACHERY_STORAGE_DIR` environment
variable. (If this is not set, it defaults to a directory named
`kachery-storage` in the home directory of the user running the
`kachery-daemon` process on the node.)

This directory stores configuration information, and also stores each of the
three information types separately:

* **Files** follow the content-addressability rules: they are stored according
to the value of the SHA1 fingerprint of the file's contents. These files are
stored in the `sha1` subdirectory of `$KACHERY_STORAGE_DIR`.

  For example, the file
  [studysets.json](https://github.com/flatironinstitute/spikeforest_recordings/blob/master/recordings/studysets),
  a JSON file which describes the recordings in
  [SpikeForest](http://spikeforest.flatironinstitute.org/), is stored in kachery
  with the URI:

  > `sha1://f728d5bf1118a8c6e2dfee7c99efb0256246d1d3/studysets.json`
  
  This URI, with the `sha1://` prefix, is used to retrieve the data when making
  requests through the [kachery client](./client-howto.md). The URI preserves the
  name of the originally stored file (`studysets.json`), as well as the `sha1`
  hash of its contents (`f728d5...`).
  
  On any system where the file is stored, the actual file will be stored within the
  local kachery storage directory under the path:

  > `sha1/f7/28/d5/f728d5bf1118a8c6e2dfee7c99efb0256246d1d3`

  The first three pairs of hexadecimal characters in the hash are used to create a
  three-level directory tree, which distributes the stored files across the
  filesystem and avoids storing unduly large numbers of files within any single directory.

* **Feeds** are stored in a relational database, `feeds.db`, within the
`$KACHERY_STORAGE_DIR` directory.

* Finally, **task results** are not stored in local storage at all (although they
may be available in the cloud storage cache). In general, nodes that supply task
results are expected to use an alternative caching mechanism (such as a
[hither job cache](https://github.com/flatironinstitute/hither#job-cache)) to
avoid repeating calculations, while a node requesting a task result will
not cache that result locally. In the cloud storage cache, each task result
is cached according to a key formed from the task ID and the specific parameters.

### Local data storage access

Local kachery storage is located on the filesystem of the host running the
node (both local disk and network-attached storage are supported). Access will be governed
by the host operating system/filesystem permissions. Because the filesystem
is not aware of kachery network channels, channel permissions will not be
enforced at this level. This is unlikely to matter locally for the vast majority of
use cases, since we assume that a system user with access to the kachery store
via the filesystem would also have access to the client command line. However,
a node with membership in multiple channels could potentially share files from
one channel with nodes from another channel:

> Suppose Node X has `REQUEST-FILE`
permission on Channel A and `PROVIDE-FILE` permission on Channel B. Node Y has
`REQUEST-FILE` permission on Channel B and requests file `SHA1://12345`,
which Node X has already downloaded from a source on Channel A. The store does
not track the channel-of-origin of this file, so Node X would provide the file
to Node Y.

For data to be compromised in this manner, a user of Node Y
would have to know the SHA1 of the desired file, and
suspect that there are nodes on the channel which are also members of another
channel where this file is shared. This is unlikely, but possible.

To mitigate this risk, it is important for node owners to be responsible about
the channels they join.

### Organization of data on the cloud resource

Unlike the node- or client-local caches, cloud storage systems are different from
conventional filesystems in that they
[do not typically have a concept of directories](https://cloud.google.com/storage/docs/folders).
Instead, objects are referred to solely by URL. Fortunately, this maps perfectly with
the content-addressable design of kachery, in which every record is assigned a unique
URL identifier anyway.

In short, the data on the cloud storage cache has no particular organization, but
the kachery system is not concerned with this in any way.

### Splitting files into pages

To improve the speed and robustness of data transfer, records (with any kind of information)
over a threshold size are split into multiple chunks, or *pages*, of 20 million bytes each.
These are stored as discrete
units within the kachery storage hierarchy. The overall data record includes a *manifest*
that tells kachery how to put the pieces back together. With this design, it is possible
to transfer a record through multiple simultaneous connections, and easy to resume an interrupted
partial download with minimal need for redundant downloading. This process is
transparent to the kachery user.
