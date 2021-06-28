# Feeds

A kachery feed is a collection of append-only logs called subfeeds, and is writeable by one and only one kachery node. Unlike kachery files, which are referred to by [content URIs](./content-uris.md), and are guaranteed never to change, subfeeds are meant to grow over time, and therefore cannot be referenced by their content. Instead they are referenced by a feed URI of the form:

```
feed://d83129c270a87995917e26eb3cea504d2431681fe66cc3bfd02083ef7bfaecdb/primes
```

The 64-character hex string in this URI is the feed ID and represents a public signing key generated using the [Ed25519](https://en.wikipedia.org/wiki/EdDSA) algorithm. The corresponding private key is stored internally on the node that created the feed and is kept a secret. In order to be considered valid, messages in this feed must be signed using the private key. The authenticity of the messages may subsequently be verified by any node using the public key. As long as the private key is not compromised (and the writer node obeys the rules of kachery feeds), we can trust that this feed URI points to a single well-defined collection of messages.

The name "primes" at the end of this URI refers to a subfeed, which in this case is an append-only log of prime number records. Right now it contains all 168 prime numbers less than 1000 in sequence, but in the future it may contain more records. Unless the secret key is compromised, it is guaranteed that the first 168 records of this feed will always remain the same.

The above feed was created using the follow script:

```python
from typing import List, Set
import kachery_client as kc

def prime_sieve(n: int):
    is_composite: Set[int] = set()
    primes: List[int] = []
    for j in range(2, n + 1):
        if not j in is_composite:
            primes.append(j)
            for k in range(j * j, n + 1, j):
                is_composite.add(k)
    return primes

feed = kc.create_feed()
subfeed = feed.load_subfeed('primes')

N = 1000
primes = prime_sieve(N)
for i, p in enumerate(primes):
    subfeed.append_message({
        'p': p,
        'n': i + 1
    })

print(f'Found {len(primes)} prime numbers less than {N}')
print(subfeed.uri)

# Output:
# Found 168 prime numbers less than 1000
# feed://d83129c270a87995917e26eb3cea504d2431681fe66cc3bfd02083ef7bfaecdb/primes
```

To retrieve these messages on the same node or on a different node with access, run the following:

```python
import kachery_client as kc

subfeed = kc.load_subfeed('feed://d83129c270a87995917e26eb3cea504d2431681fe66cc3bfd02083ef7bfaecdb/primes')
messages = subfeed.get_next_messages()
for msg in messages:
    print(f'Prime {msg["n"]}: {msg["p"]}')

# Output:
# Prime 1: 2
# Prime 2: 3
# Prime 3: 5
# ...
# Prime 168: 997
```

## Examples of feeds

Feeds provide
a permanent public record of any process that generates information with
a natural chronological ordering. Examples include data collected in a series, the
path of values in parameters of a machine learning model, the curation
actions applied to a data set by a lab researcher, a series of financial
transactions, the set of placements of opened windows in a user interface, etc.
The types of data that fall into this category are very broad.

In addition to tracking the history of a process, feeds are very useful for
ensuring reproducibility in states between different systems. Because
the subfeed acts as a ledger that (when used properly) records every transition
from the initial state to the current state, a remote machine can be synced
to match the state of the feed originator simply by replaying the steps recorded
in a subfeed. Moreover, because every message added to a subfeed needs to be signed
and added by the node that owns it, feeds automatically generate a canonical
ordering for potentially-ambiguous items.

### How are feeds different from files?

Since [kachery files are stored in a content-addressable way](./content-uris.md), they can only
be retrieved if the file signature (SHA-1 URI) is known. However, feeds are
meant to grow (until finalized)--if their content were known and fixed, they
would just be files! Instead, as described in the example above, each feed is assigned a unique identifier, which
is also the [public part of a public-private keypair](./security.md#Feeds). The
node which owns the feed also keeps the private key, and signs each message which
is officially added to the feed.

Feeds are also distinct from kachery files in that a feed has a specific
owner node. Files are content-addressable, and thus there is no hierarchy by
which one node's copy would be preferred over another node's--it doesn't matter
who contributed the file originally, only what the file contains. For feeds,
the node that owns the feed is the authoritative source of its contents, and the only entity that is allowed to append new messages.

Finally, because the messages added to an append-only log within a feed have an inherent ordering (and
earlier messages are immutable), a node requesting feed data can request the
messages after a specific point in time or can monitor new additions in real
time. These actions would not make sense in the context of a regular kachery file.

## Feed Structure

As shown in the above example, each feed is a collection of *subfeeds*, which organize the messages appended to the
feed. Messages are always associated with a specific subfeed, rather than the
feed as a whole, even if the feed has only one subfeed.
Each subfeed has its own name (a key used to refer to the subfeed within the feed).
On local storage, feeds, subfeeds, and messages are all stored in a SQL database. However, when shared between nodes, subfeed messages are stored as individual objects in a storage bucket.

## Feed Security

As discussed in the [security model](./security.md#Feeds), each feed is owned by
a specific node which is the sole authority over its contents. The owner node
retains the private key corresponding to the public key represented by the
feed ID, and signs every new message appended to the feed. All nodes which
obtain feed data can verify its authenticity by checking this signature.

While the owner node is the sole author of feed contents, a feed owner can authorize other nodes to submit message to a subfeed via [action tasks](./tasks.md). The
[SortingView](https://github.com/magland/sortingview) electrophysiology
visualization application uses this approach to allow multiple researchers
to collaborate and contribute their curation actions to a common lab record.