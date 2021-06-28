# Local node storage

Kachery [files](./content-uris.md) and [feeds](./feeds.md) are first stored locally and are uploaded to the [kachery network](./network.md) only when requested by another [node](./node.md) with the appropriate access permissions.

For example, when we run the following script,

```python
import kachery_client as kc

uri = kc.store_text('example-text')
print(uri)
# Outputs: sha1://5e8fe2d0b1e93be61186fda5a9021ceb89b07326/file.txt
```

a text file is stored locally at:

```bash
# Note: if KACHERY_STORAGE_DIR is not set at the time the kachery daemon is run, the default path ~/kachery-storage will be used
$KACHERY_STORAGE_DIR/sha1/5e/8f/e2/5e8fe2d0b1e93be61186fda5a9021ceb89b07326
```

and will only be uploaded to the cloud only if (a) this file is requested by another node who belongs to some channel `C`, (b) the remote node is configured to request files on `C`, and (c) our node is configured to provide files on `C`.

Similarly, any feeds we create locally will first be stored in a local SQLite database at:

```bash
$KACHERY_STORAGE_DIR/feeds.db
```

and will only be uploaded to the cloud if another authorized node requests the feed on a channel, and we are configured to provide feeds on that channel.

