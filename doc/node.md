# kachery Nodes

A *node* is the basic unit of the kachery network: a long-running program that
communicates with other nodes across different *channels* and can potentially
request data or operations from other nodes on the channel or contribute its own.
The basic example is a running instance of the `kachery-daemon` package.

*For practical information on running a kachery node, including a step-by-step tutorial,
see the [instructions on running a kachery node](./node-howto.md).*

## Communications

The kachery network is designed as a mediated peer-to-peer information sharing tool
with a centralized communication channel structure.
It is *peer to peer* in the sense that there is no central repository
of data which acts as the sole provider of files: any node with permission can
offer new files to the collective, without requiring centralized approval on
a per-file basis. However, it is *mediated* in that nodes do not communicate directly
with each other, and are not required to track how to find other individual nodes;
file transfer is accomplished through a cloud storage cache that acts as a set of
organized cubbies for information drops, while node-to-node coordinating communications
take place over a
[publish-subscribe system](https://en.wikipedia.org/wiki/Publish-subscribe_pattern)
(currently built on [Ably](https://ably.com/pub-sub-messaging)). TODO: mention how channels play a role in communication.

### Data transfer

Nodes in the kachery network do not communicate directly with each other. Instead, nodes
transfer information (files or feeds) between one another through cloud storage caches that are provided by kachery channels.
If a node requests information that is not already present in the cloud storage cache,
a node on the same channel which has the information can transfer it by copying it into the cache and using
the pub-sub system to inform the requester that it is now available in the cache. (Of
course, if the information is already in the cache, the requester can find it without
any interaction with other nodes whatsoever.)

Write access to the cloud storage cache is tightly controlled by the channel that owns the cache: in order to write,
a node needs authorization from the channel to write a file with a particular name and size. This
process is described in greater detail, including some limitations, in the
[security model documentation on uploads](./security.md#Uploads).

### Coordinating communications

The node-to-node communication channels correspond to the six types of
[channel permissions](./security.md#Permissions): each node can be granted
permission on a channel to *request* or *provide* data of the three different types:
*files*, *feeds*, and *tasks*. Thus, for each named channel on kacheryhub,
there are six pub-sub channels:

* Request File
* Provide File
* Request Feed
* Provide Feed
* Request Task
* Provide Task

Each of these channels can have both a "publish" and a "subscribe" permission.
Publish permission allows the node to write new messages to the pub-sub channel,
while an active subscription causes the node to be notified whenever new
messages are published to the pub-sub channel.

Granting a node permissions for a particular action on a named kachery
channel automatically grants permissions on the corresponding pub-sub
channel that will allow it to fulfill that role. These permissions
have a complementary distribution: to request a type of information,
a node needs to be able to publish to the request channel and be subscribed
to updates from the provide channel; by contrast, to provide information,
a node must be notified of new messages on the request channel, and able
to publish updates to the "providing files" channel.

The following table illustrates the pub-sub channel permissions corresponding
to the "Request File" and "Provide File" permissions:

| Permission   | Request Files channel | Provide Files channel |
|--------------|-----------------------|-----------------------|
| Request File | Publish allowed       | Subscribed            |
| Provide File | Subscribed            | Publish allowed       |

Permissions to request or provide feeds or tasks are similar.

When a node *requests* information, it publishes the request to the
corresponding "Request" pub-sub channel. All nodes in the kachery channel with the corresponding
*provide* permission for that information are then notified of the new
request by their subscription. A node which can satisfy the request
will publish a response to the "Provide" pub-sub channel; the requesting node
sees this notification and knows that its request will be satisfied.
The provider node continues to publish updates during the retrieval
process, and will publish a "completion" notification after all data
is available in the cloud storage cache. The requesting node is
notified by subscription that the data transfer to the cache is complete,
and then begins downloading the requested data from the cloud storage cache.

Feeds are somewhat unique, because feeds are owned by a particular node:
nodes that do not own the feed will not upload feed data to the cloud
storage, even if they possess feed data which is more recent than what is
in the cloud cache. This may be changed in a future version.
