# Ephemeral mode

It is also possible to load kachery files directly from a channel without creating a node or running a daemon.

> :warning: This applies only to files that are already stored in the channel's cloud bucket. See below for instructions on uploading a file to a channel bucket.

From the command line:

```bash
# These commands do not require a running daemon
kachery-load <URI> --ephemeral-channel <CHANNEL>
kachery-cat <URI> --ephemeral-channel <CHANNEL>
```

From Python:

```python
import kachery_client as kc
kec = kc.EphemeralClient(channel='CHANNEL') # fill in the desired channel

# These commands do not require a running daemon
a = kec.load_file(uri)
b = kec.load_text(uri)
c = kec.load_json(uri)
d = kec.load_npy(uri)
e = kec.load_pkl(uri)
```

In order to be loaded in ephemeral mode, files must already be stored in the channel's cloud bucket. To get a file into the cloud bucket, you can either load the file in normal mode from a remote node, or you can explicitly upload a file to a channel using:

```bash
kachery-store [file] --upload-to-channel CHANNEL
```

Or from python

```python
import kachery_client as kc

kc.upload_file(path_or_uri)
```

The upload commands require a running daemon and a node with permission to provide files to the channel.
