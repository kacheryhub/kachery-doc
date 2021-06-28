# kachery Storage Design

The purpose of the kachery system is to facilitate transferring data
between network peers. kachery achieves this purpose by
providing a universally consistent name for each record stored in the
system, and storing these records in a sophisticated
hierarchy of *caches* of varying size and
accessibility at several different levels in the tool.

(Incidentally, this hierarchy of caches is what gives kachery its name!)

In this page, the term "file" is used to refer specifically to the
[content-addressable information type](./Overview.md#What-It-Does) within
kachery. The term "record" will be used when referring to a file on a
filesystem (which could store any of the three types of information).

## Content-Addressable Storage

Storing and retrieving information consistently across different systems
requires a consistent reference for each record. At its heart, kachery
provides this through *content-addressable storage*: files are stored
in the kachery system according to a directory structure based on the
SHA1 hash of the file's contents.

Because files are content-addressable, their official location will change whenever
their content changes. This can be a convenient, if very inefficient, means of creating
a change log for files; however, more realistically it is advisable not to store
files in kachery if they are expected to undergo frequent changes. Store files when
they've reached their final form.

### Feeds

Unlike files, *feeds* are supposed to change. In order to provide each feed with a
consistent location, feeds are identified by an arbitrary character string (which
is actually the public part of a
[public-private key pair](https://en.wikipedia.org/wiki/Public-key_cryptography)).
The node which owns the feed stores the corresponding private key, and uses
it to sign each message that is approved to be added to the feed. See the
[documentation on feeds](./feeds.md) and on the
[feed signature security model](./feeds.md#Feeds) for more details.

### Tasks

Similarly, tasks cannot be stored according to their content: if we had the
content, there would be no need to run the task! Instead, tasks are identified
by a fingerprint composed of the registered task name and the parameters
passed to it (in JSON-serialized format). For more information, see the
[documentation on tasks](./tasks.md).

## Storage Hierarchy

Depending on configuration, there are up to three different caches per node in a
typical kachery use case.

First is the shortest-term cache, the cloud storage cache. Individual nodes
transfer data by uploading it to this storage space. For reasons of economy,
this space is expected to be limited and some information will be cleared out
of this cache when appropriate; however, it provides ready access to all nodes,
even if the original provider of the information is not presently online.

Second, each node is expected to have local storage: this is where data goes
when the user has added local information to kachery, and where data retrieved
from the kachery network is stored. Because this storage is part of a filesystem
on user-owned hardware, it can be scaled cheaply and information can be
stored for as long as desired.

Finally, in the event that the kachery client is running on a separate
machine from the kachery server, the client machine can also be configured
with a local cache. This cache will be used when the client is in "offline"
mode (not connected to a node). **AS WELL AS XYZ?**

### Organization of data within local storage

The root of the information records stored in any particular kachery node's
cache is the directory identified by the `KACHERY_STORAGE_DIR` environment
variable. (If this is not set, it defaults to a directory named
`kachery-storage` in the home directory of whatever user is running the
`kachery-daemon` process on the node.)

Within this directory, there are separate subdirectories for configuration,
as well as for each of the different information types.

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

* **Feeds** are stored according to their Feed ID within the `feeds` subdirectory
of `$KACHERY_STORAGE_DIR`. This directory has its own three-level hierarchy of
two-hexadecimal-character subdirectories. The full feed ID is used as the name of
a directory here, and that directory contains a `subfeeds` directory which has
a further three-level hierarchy, at the base of which are the messages for each
subfeed. (See
[the documentation on feeds](feeds.md) for more information about feeds and subfeeds.)
Finally, within the subfeed directory, messages are stored in a record called `messages`.

  As an example, the subfeed:
  > `b28b7af69320201d1cf206ebf28373980add1451`

  belonging to the feed:
  > `021791fd201ac1e4e5efd3cc461ff8fda03bba130ffb7d48e7be94b7860bbc1c`

  has its messages documented in a record at:
  > `$KACHERY_STORAGE_DIR/feeds/02/17/91/021791fd[...]bbc1c/subfeeds/b2/8b/7a/b28b7a[...]d1451/messages`

  (where ellipses have been added for readability--the full hex strings are used in the actual system).

* Finally, **task results** are stored in `$KACHERY_STORAGE_DIR/job-cache` with a similar
three-level two-hex-character directory structure. Tasks are keyed according to a fingerprint
derived from the task name and its (serialized) parameters.

### Local data storage access

Local kachery storage is located on the file system of the host running the
node (or network-attached storage suitably mounted). Access will be governed
by the host operating system/file system permissions. Because the file system
is not aware of kachery network channels, channel permissions will not be
enforced at this level. This is unlikely to matter locally for the vast majority of
use cases, since we assume that a system user with access to the kachery store
via the file system would also have access to the client command line. However,
a node with membership in multiple channels could potentially share files from
one channel with nodes from another channel:

> Suppose Node X has `REQUEST-FILE`
permission on Channel A and `PROVIDE-FILE` permission on Channel B. Node Y has
`REQUEST-FILE` permission on Channel B and requests file `SHA1://12345`,
which Node X has already downloaded from a source on Channel A. The store does
not track the channel-of-origin of this file, so Node X would provide the file
to Node Y.

For this to work, a user of Node Y has to know the SHA1 of the desired file, and
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

### Splitting Files into Pages

To improve the speed and robustness of data transfer, records (with any kind of information)
over a threshold size are split into multiple chunks, or *pages*, which are stored as discrete
units within the kachery storage hierarchy. The overall data record includes a *manifest*
that tells kachery how to put the pieces back together. With this design, it is possible
to transfer a record through multiple simultaneous connections, and easy to resume an interrupted
partial download with minimal need for redundant downloading. This process is
transparent to the kachery user.

At present, the threshold size is 20 MB, but **IS THERE A SETTING OR CUSTOMIZATION OR ANYTHING?**
