# kachery-daemon api

The following verbs are defined by the kachery daemon api:

## Files

These verbs describe the interface to add or retrieve files from the
file data store. The daemon will store files on a filesystem to
which it has access (as referred to by the `$KACHERY_STORAGE_DIR`
environment variable). Loading a file into kachery means making it
available in the kachery-storage filesystem, while retrieving a file
from other nodes entails copying it from the shared cloud
storage bucket into the kachery-storage filesystem.

### probe

### stats

### storeFile

### linkFile

### downloadFileData

### store

### loadFile

## Feeds

### feed/createFeed

### feed/deleteFeed

### feed/getFeedId

### feed/appendMessages

### feed/getNumLocalMessages

### feed/getFeedInfo

### feed/watchForNewMessages

## Mutables

*Mutables* represent a key-value store within this particular instance
of the daemon. They are not shared with other nodes [IS THAT TRUE?] and
are expected to contain a small amount of ephemeral data. Examples
would be a human-readable alias for channels or feeds; the alias is
useful to the human interacting with the node, but need not be globally
unique, because it isn't shared with the entire kachery network.

### mutable/get

### mutable/set

## Tasks

*Tasks* are user-defined python code which has been allowed to be
executed on kachery node compute resources. The basic use case is
to cache the results of expensive pure-function computations, but
the same mechanism provides hooks for applications which either
depend on or alter external state. See [tasks](./tasks.md) for more
details.

### task/registerTaskFunctions

### task/updateTaskStatus

### task/createSignedTaskResultUploadUrl

### task/requestTask

### task/waitForTaskResult
