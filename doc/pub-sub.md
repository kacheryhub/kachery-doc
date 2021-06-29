# publish-subscribe communications model

## What is a publish-subscribe model?

As part of the *mediated peer-to-peer* design of kachery,
[nodes](https://github.com/kacheryhub/kachery-doc/blob/main/doc/node.md)
communicate with each other through a
[publish-subscribe service](https://ably.com/).
This is an implementation of the
[publish-subscribe message passing model](https://en.wikipedia.org/wiki/Publish%E2%80%93subscribe_pattern).
In this model, entities that want to communicate with each other
(in kachery, the nodes) can communicate in a loosely coupled way
that does not depend on each node knowing how to find its
peers. Instead of direct connections from one node to another,
communications are made to a central service, which is then
responsible for distributing the messages to all intended
recipients.

In this model, entities that wish to communicate with other nodes
register with a central broker. That broker provides
communication bands with two functions: an entity can **publish**
messages to the band, and can **subscribe** to be informed of
new messages which other entities publish. The broker
is responsible for collecting all messages published to a band,
and passing them on to all entities which are subscribed to it.
The broker can also determine which entities are permitted
to publish or subscribe, and even filter messages based
on their contents or other criteria (if desired).

## How does kachery use the pub-sub model?

As discussed in the documentation on
[node-node communications](https://github.com/kacheryhub/kachery-doc/blob/main/doc/node.md#communications),
nodes communicate with each other for two reasons: they can
either request information from, or offer to provide information to,
other peers on the kachery network. The Ably pub-sub service acts
as the broker that receives and dispatches messages. Every kachery channel
(every community of nodes) is provided with six pub-sub channels (that is, six
communication bands). These correspond to channels where nodes can request
or provide the three types of kachery data. Nodes with "request" permissions
are able to publish on a *request* channel and subscribe to responses on the
*provide* channel; while nodes with "provide" permissions are subscribed to
the *request* channel and post updates to the *provide* channel.

## Why not use direct node-to-node communication?

The alternative to a publish-subscribe model is for nodes
to communicate directly. Direct node-to-node communication does
avoid the dependency on a central message distribution service. However,
direct communication suffers from poor scaling in theory, and
poor reliability in practice due to infrastructure challenges.

If every node needs to communicate directly with every other node,
the result is a [complete graph](https://en.wikipedia.org/wiki/Complete_graph).
Unfortunately, in such a structure, the number of node-to-node connections
(the edges in the graph) grows in proportion to the square of the number of
nodes: two nodes need one edge, three nodes need three edges; but five
nodes already require 10 direct node-to-node links. This rapidly becomes
unmanageable, since nodes need to keep track of an ever-increasing number
of peers, and network traffic soon becomes dominated just by the coordination
messages the nodes use to ensure they can still locate their peers.

These problems can be mitigated somewhat by relaxing the assumption that
the set of nodes will be fully connected, effectively breaking the
graph of nodes into [cliques](https://en.wikipedia.org/wiki/Clique_(graph_theory)).
However, this comes at the expense of reduced performance, as information from
distant nodes may have to go over several hops before it can reach the
party requesting it. If done improperly, some nodes may wind up completely
or partially isolated, with little access to other parts of the network.
Moreover, since each cluster in the graph has relatively
few connections to the other clusters, the network as a whole develops
potential bottlenecks that can become critical points of failure. Eventually
it becomes more robust to have a single very reliable point of failure
than a handful of critical points which are individually more vulnerable.

Moreover, there are practical concerns related to peer-to-peer
communications over commodity networks. Most nodes on a strictly
peer-to-peer network do not have control over their network
configurations: users of home networks are subject to the rules of their
ISPs, which frequently view any peer-to-peer data transfer with suspicion and
usually do not provide consistent IP addresses (necessitating
continuous keep-alive chatter); and users in institutions must contend
with network adminstrators' choices about firewalling, which can present
a wide range of of barriers to communication.

The centralized publish-subscribe model thus solves both problems:
the challenge of keeping track of all peer nodes can be delegated to
only the central pub-sub server, greatly reducing the burden on the individual peers.
And nodes can communicate with the central publish-subscribe
provider with very little custom configuration, using primarily outbound
HTTP requests, which are allowed on the vast majority of networks.
