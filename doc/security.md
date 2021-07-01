# Security Model for kachery

The primary objective of kachery is to make scientific data available. Therefore, while there are mechanisms for restricting access to kachery data, the security model for kachery is generally aimed at preventing abuse rather than keeping data private. Nevertheless, nobody can ever access any data on the kachery network unless they have access to the appropriate URI strings (content hashes or feed IDs). So the most reliable way to keep data files private is to simply keep the content hashes private. Conversely, making data public is largely a matter of making content URIs and feed IDs public.

## Permissions

Permissions are assigned through kacheryhub, on a per-channel
basis. The owner of each named kachery channel assigns permissions to
individual [nodes](./node.md). The possible permissions are:

* Request Files
* Provide Files
* Request Feeds
* Provide Feeds
* Request Tasks
* Provide Tasks

A node which lacks "request" permissions for a given information
type *cannot* solicit other nodes to provide missing data; it is
restricted to only the data that is already present in the
cloud storage cache. (Note that this information may change from
time to time due to files being evicted from cache.)

A node without "provide" permissions for a given information type
*cannot* upload data into the cloud storage cache, and cannot even
see requests coming from other nodes.

Each permission on a named kachery channel implies a certain set of
access permissions to the pub-sub communication bands. See
[the documentation on node-node communications](./node.md#coordinating_communications)
for details.

Permissions cannot be forced on a node unilaterally. The node's owner
must specify what permissions the node requests on
each channel to which it is joined. Ultimately, the actual permissions
will be the intersection of the permission lists: nodes have only
those permissions which have been both requested by the node owner
and granted by the channel owner.

Permissions are granted to a combination of the *node*
(identified by a node key) and its *owner* (identified by the federated
authentication acccount provider, e.g. a Google account). Both parts
are required in order to run a node. This mitigates several possible
attack vectors, demonstrated by a malicious user *Mal* and a permitted
user *Justine*. (Note that the `--label` parameter is a cosmetic identifier
and has no functional significance.)

* *False flag node*: Mal might try to create a new node
in Justine's name:
  > `$ kachery-daemon-start --label justines_node --owner justine@gmail.com`
  
  However, each instance of the node has its own identifier,
  so this command would create a new node different from any
  Justine already had. The new node would then
  need to be joined to the target channel; but it would not be possible to
  configure the new node without logging in to kacheryhub using Justine's
  actual Google credentials.

* *Node stealing*: Suppose Mal has shell access on the machine where Justine's
existing, configured node is run. Starting the node with Mal as owner:
  > `$ kachery-daemon-start --label justines_node --owner mal@gmail.com`

  will not result in compromise, because the node with Mal as owner has a
  separate permission configuration from the node with Justine as owner.

* *Unsupervised startup*: In fact, even if Mal has shell access and attempts
to start the node by passing Justine's Google credentials, this still will not
result in compromise: Mal cannot start Justine's actual node
without using the node's private key, which is kept secure in Justine's key store.

A few remaining vulnerabilities may occur in the event of carelessness or
misconfiguration:

* Channel owners with potentially sensitive information should be cautious
about granting permissions. While Mal cannot start a fake node using Justine's
actual Google credentials, it would still be possible for Mal to create a
similar-sounding account--e.g. `just1ne@gmail.com`--and create a node using
this account. Channel administrators hosting sensitive data
should be aware of this kind of impersonation and not grant new node permissions
without first making separate contact with the node owner to confirm.
In addition to exercising caution, it may be advisable to establish
a policy of granting access only to nodes owned by institutionally managed accounts,
since these are harder to create maliciously.

* [Channel permissions do not apply to the local file store](./storage.md#Local-data-storage-access).
If Mal has access to the filesystem where Justine's `$KACHERY_STORAGE_DIR` resides,
it may be possible to navigate to files of interest without going through
the kachery system. To mitigate this possibility, it is advisable to use a
[service account](https://unix.stackexchange.com/questions/314725/what-is-the-difference-between-user-and-service-account)
to run the kachery daemon when running on a shared system, and to ensure
that the `$KACHERY_STORAGE_DIR` directory is owned by & readable only to
that service account.

## Uploads

The cloud storage cache is a (paid) resource which should be owned by the
channel owner. However, to allow semi-decentralized data sharing among peers,
the kachery network must permit other nodes--which are likely owned by
other parties--to write to cloud storage. This is accomplished by means of
*[signed upload URLs](https://cloud.google.com/storage/docs/access-control/signed-urls)*
which act something like a prepaid mailing label for files. When a node wishes to
upload a file to the cloud storage cache, it requests a pre-signed URL
from kacheryhub. This is a URL for a specified file name and size which
allows upload to a specific cloud storage location. An entity that knows this
URL can make an HTTP PUT request to it in order to upload a file to the cloud.

## Channel owner stored credentials

kacheryhub manages access to the various resources owned by the channel
owner: specifically, the cloud storage cache and the Ably pub-sub bands.
In order to provide nodes with access, kacheryhub needs to store
these credentials and provide limited-access tokens upon
appropriately validated request.

In order to create upload URLs, kacheryhub needs to use the
*channel owner's cloud storage provider access credentials*. These should
have been registered at the time the channel was created.

kacheryhub also requires the Ably API key to provide pub-sub band
access tokens to nodes. To interact with other nodes, a node requests
the appropriate subscribe and publish permissions from kacheryhub.
The kacheryhub server acts as an authentication/authorization server;
it verifies the identify of the node-owner pair (using signature verification)
and, if the node checks out, it uses the Ably API key of the channel owner
to provide the node with temporary access tokens to the pub-sub bands.
(These expire after around 30 minutes and must be renewed at that time. This is managed internally by the kachery libraries.)

## Feeds

Because kachery file storage is content-addressable, files are essentially
self-verifying: the file name is the cryptographic hash, which can
be readily checked by anyone who obtains the file.

Feeds, however, will grow over their lifetimes, and so require a different
mechanism for verification. This is accomplished by public-key cryptography.
Each feed ID is a public key, whose private counterpart is kept by the node
which owns the feed. Each message appended to the feed must be signed
by the feed owner's private key. This signature is checked by any
requesting node when the feed's data is downloaded.

Having a unique owner node also makes feeds different from other
types of information shared over the kachery network. Any node that
has a file can legitimately upload it, regardless of who
created it; but only the owner node can provide a
canonical version of a feed. While the owning node may accept
new messages into a subfeed that come from other nodes, those
new feed entries have to be approved by being signed by the
owning node.

## Caveats

* Permissions are assigned on a per-node basis, not a per-file basis.
The assumption is that all files (/feeds/tasks) shared on a channel
are of the same sensitivity and should have the same access rights. Nevertheless, nobody can access files without knowing the corresponding URI strings. Therefore, access can be managed to some extend by restricting access to these URIs.

* In particular, there is no distinction in the
permission system between a node being allowed to upload files that were
originally provided by other nodes (and perhaps have fallen out of the
cloud cache), and that node being allowed to provide new files for which
it is the original source.

* As described in the documentation for running nodes, it is possible
to configure a node so that remote clients can connect to it. (This allows,
for instance, a lab's members to use a single central node to talk with the
wider network, accessing the shared node through clients on their individual
workstations.) This greatly simplifies the administrative burden for both
channel owners and individual labs, but it does mean that any individual
who can connect to a node will have the full set of permissions granted to that node.
Ultimately, any system must contend with this in some fashion--any person
with access to privileged files could potentially choose to share them with
others--but to avoid accidents, it is important that the owners of trusted nodes
are informed and responsible parties who can be expected to allow access to
their nodes appropriately.

* Files are not flagged with the channel they came from. So, if channel A
is configured to share its cloud storage cache with channel B,
then a node with access to channel A could conceivably retrieve files associated
with channel B in certain limited circumstances. To avoid this issue, channel
owners should be careful about sharing one cloud storage space between multiple channels.

* The pre-signed URL for file upload includes the name of the storage object and size of the file to
be uploaded. Since kachery is a content-addressable
storage system, the name of the storage object will contain the hash of its contents.
Files can be verified by confirming that the file hashes out to the value indicated
by its name.
However, because the cloud storage cache has no attached processing, there is no
mechanism for verifying this property at upload time in the cache itself: the cloud
storage cache cannot provide any guarantees about file contents.
Files downloaded from the cloud storage cache using the kachery client libraries are always hash-verified (an exception is thrown if the hash is not as expected).
A malicious actor could potentially upload invalid or mislabeled data
to the cloud cache; this would not be caught until the data was downloaded
by other nodes. To mitigate this possibility, again, ensure that permissions
are only granted to trustworthy nodes with responsible owners.
