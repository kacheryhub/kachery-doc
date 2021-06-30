# Cloud storage buckets and kachery

## What is cloud storage?

[Cloud storage](https://en.wikipedia.org/wiki/Cloud_storage) is a type of
non-user-owned, remote data storage. Cloud storage is distinct from other
models of file storage because it completely abstracts away the conventional
[filesystem](https://en.wikipedia.org/wiki/File_system) model: the user of
a cloud storage tool does not need to worry about the mechanics of how files
are stored on disk by the storage provider, or where a file is located in a
hierarchy. Instead, files are accessed by a unique identifier, or through
tagging and querying functionality.

Benefits of cloud storage include very low risk of data loss (due to highly
resourced providers keeping extensive backups), low downtime (since providers
maintain highly redundant systems with failover), and wide geographic availability
of stored information (since the files are accessible over the Internet). On the other
hand, data resilience and security depend on choosing a reputable cloud storage
provider, and local Internet service may limit file availability and access speed.

For a more general introduction to cloud storage concepts, conventional storage
modalities, and how they differ, please see the
[background on cloud storage](https://github.com/kacheryhub/kachery-doc/blob/main/doc/cloud-storage-background.md)

## How does kachery use cloud storage?

With the mediated peer-to-peer design, kachery nodes do not transfer data
directly with each other. Instead, they use cloud storage as a common ground
where data can be deposited by providers and collected by requesters. Because
all data in kachery has a universal locator, nodes requesting data can check
the cloud storage cache and download data from it directly if the data is
already present. If the data is not present, the nodes will follow the
[request process](https://github.com/kacheryhub/kachery-doc/blob/main/doc/node.md#communications)
described in the documentation on nodes.

### Reading from cloud storage

A client requesting data from a channel already knows where the channel cloud
storage is located (as part of the channel information). Moreover, records stored
on the channel cloud storage are organized in the same way as files in the
local kachery store--the storage location is determined by the SHA1 fingerprint
(for files), feed ID (for feeds), or task ID and parameter fingerprint (for tasks).
So, if a node has enough information to make a request, it can immediately
compute the URI where the needed data would be stored in the cloud storage cache.

[TODO: NEED AN EXAMPLE OF A URI]

[QUERY: IS THERE ANY ACCESS RESTRICTION FOR DONWLOAD, OR COULD A LEAKED URI LEAK FILES?]

[QUERY: I'm assuming everything is findable from the SHA1, but what about the manifest?]

So, the first step for any node that wants to download data from a channel is
to check the cloud storage and see if the data is available. If it is, it is
downloaded directly.

If the data is not available, the requesting node will ask for it through the
request process linked above. Once the data has been uploaded by a provider,
the provider will notify the requester of the URI where the uploaded data can be found.

### Writing to cloud storage

Uploading to the cloud storage cache is somewhat more complex, because of the
need to restrict access.

In order to upload files to cloud storage, a kachery node with `provide`
permissions identifies the files that need to be transferred and communicates
their names, sizes, and fingerprints to kacheryhub. The kacheryhub system then
uses the channel owner's stored credentials for the cloud storage bucket to
generate a
[signed upload URI](https://cloud.google.com/storage/docs/access-control/signed-urls),
which is essentially a timed bearer token that allows anyone to use the URI to
upload a file to a particular location. The node providing the file initiates
an HTTP POST request using this URI, which begins a resumable transfer
of the requested file.

When the file has been loaded into the cache, the providing node can share its
resource URI with the requesting node, which can then download it through the
usual process.

## Requirements

kachery makes use of cloud storage as a centrally accessible cache which allows
nodes to transfer data. To serve this role effectively, the cloud storage cache
for a channel should be large enough to store several of the largest files expected
to be shared on the channel, without needing to evict the highest-demand files
from the cache; while remaining significantly
smaller than the total amount of data expected to be available in the channel
(including all files, feeds, and task results).
Cloud storage providers typically charge for the amount of storage used and
the amount of data transferred in and out of storage. The system will be both
most performant and most cost-efficient if the maximum storage allocation is
scaled to balance the space used with the need to re-upload data that has been
evicted from the cache.

At present, the only supported cloud storage provider is
[Google Cloud Storage](https://cloud.google.com/storage). This is expected to
change as development continues. Any supported cloud provider must allow users
to create storage buckets, make data public, and allow the bucket owner to
export keys which can be used to generate signed upload URIs,
so that other nodes can add files to the bucket.
