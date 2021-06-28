# Sharing data between workstations using Python

The easiest way to share data using kachery is via the [kachery-client](https://github.com/kacheryhub/kachery-client) Python package. After starting a [kachery daemon](https://github.com/kacheryhub/kachery-daemon) on your local computer, you can store data to the kachery network as in the following examples.

## Static content (files)

```python
import kachery_client as kc

# You need to be running a kachery daemon.
# If you want to share these data with remote
# computers, then your kachery node must be
# configured to provide files on some channel,
# and the remote computers must be configured
# to request files on that channel.

# Store some text
uri = kc.store_text('some-random-text')
print(uri)
# Output: sha1://6af826b3d648ccba6b4bbe58e93e22add640d728/file.txt

# Later on retrieve the text by its content URI
txt = kc.load_text('sha1://6af826b3d648ccba6b4bbe58e93e22add640d728/file.txt')
print(txt)
# Output: some-random-text

# Similarly, you can store/share json-able Python dicts,
# numpy arrays, or pickle-able Python objects
import numpy as np
uri_dict = kc.store_json({'a': [1, 2, {'b': 3}]})
uri_npy = kc.store_npy(np.ones((10, 20)))
uri_pkl = kc.store_pkl({'x': np.zeros((30, 40))})

# And retrieve then at a later time
X_dict = kc.load_json(uri_dict)
X_npy = kc.load_npy(uri_npy)
X_pkl = kc.load_pkl(uri_pkl)
```

Those URIs can also be used to retrieve the data on a remote computer, provided that the remote machine is also running a kachery daemon, the local and remote nodes belong to a [common channel](./channel.md), and the local and remote nodes are configured on that channel to provide and request files, respectively.

```python
import kachery_client as kc

# Run this on a remote machine.

# You need to be running a kachery daemon,
# and your kachery node must be configured
# to request files on the channel containing
# the file.

txt = kc.load_text('sha1://6af826b3d648ccba6b4bbe58e93e22add640d728/file.txt')
print(txt)
# Output: some-random-text
```

## Feeds

```python
from typing import List, Set
import kachery_client as kc

# You need to be running a kachery daemon.
# If you want to share these data with remote
# computers, then your kachery node must be
# configured to provide feeds on some channel,
# and the remote computers must be configured
# to request feeds on that channel.

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

N = 100
primes = prime_sieve(N)
for i, p in enumerate(primes):
    subfeed.append_message({
        'p': p,
        'n': i + 1
    })

print(f'Found {len(primes)} prime numbers less than {N}')
print(subfeed.uri)

# Output:
# Found 25 prime numbers less than 100
# feed://c21cfca1b54ba841a7cbf35685b5a62db73ed16b7c3f50f2fa1f9e1fce9b9cef/primes
```

Later on, retrieve the messages either on the same node, or on a different node that has access:

```python
import kachery_client as kc

# You need to be running a kachery daemon,
# and your kachery node must be configured
# to request feeds on the channel containing
# the feed.

subfeed = kc.load_subfeed('feed://c21cfca1b54ba841a7cbf35685b5a62db73ed16b7c3f50f2fa1f9e1fce9b9cef/primes')
messages = subfeed.get_next_messages()
for msg in messages:
    print(f'Prime {msg["n"]}: {msg["p"]}')

# Output:
# Prime 1: 2
# Prime 2: 3
# Prime 3: 5
# ...
# Prime 25: 97
```

See [feeds](./feeds.md) for more information.

## Tasks

It is also possible to share processing results, or the outputs of pure calculation results, between nodes, and to request that tasks be run on remote nodes.

See [tasks](./tasks.md) for more information.