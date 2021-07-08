# Limiting the size of the storage cache

You can configure the local kachery storage to have a maximum allowable size.

Create a `kachery.yaml` in your kachery storage directory (by default, `$HOME/kachery-storage`) with the following content:

```yaml
maxCacheSizeGiB: 100
```

where you can replace `100` by the desired size limit in GiB.

The kachery daemon will monitor the size of kachery storage. If it exceeds the limit, then it will selectively move old files to the `sha1-trash` subdirectory of the kachery storage directory. It will prefer to keep files that were accessed recently, and it will also prefer to keep smaller files.

Periodically, you can manually remove the contents of `sha1-trash`.