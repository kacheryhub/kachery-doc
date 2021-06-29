# kachery

Kachery is a software suite which facilitates sharing data for scientific or technical research.

## What it does

The kachery software suite facilitates sharing three types of data:

* **Files** are data files, of any size. Files over 20 MiB will be broken into
smaller pieces for transfer and caching.

* **Feeds** are *append-only* logs, which operate like a digital
[lab notebook](https://en.wikipedia.org/wiki/Lab_notebook) or
[ledger](https://en.wikipedia.org/wiki/Ledger). Because such a feed is append-only
and signed, it presents a reliable history of actions taken by any agent; and
because it is complete, it offers a single source of truth from which the current
state of any system built on kachery can be reconstructed just by replaying the
log. For more details, consult the [feeds documentation](./feeds.md).

* **Tasks** are operations acting on files or feeds in the system. The system
supports three basic types of tasks:
  * *Pure calculation tasks* are pure functions in the
  [computational](https://en.wikipedia.org/wiki/Pure_function)
  or [mathematical](https://en.wikipedia.org/wiki/Function_(mathematics)) sense.
  kachery provides a deterministic unique identifier for the combination
  of a pure function and the arguments it was called with, and maps that identifier to
  the result of the computation which is cached.
  This eliminates the need for duplicate calculations,
  which is particularly useful for computationally intensive processes.
  * *Queries* are tasks whose result depends on some external state (such as
  looking up a configuration value in local storage). Because external systems can
  change, a query task should be rerun on each request, if possible.
  However, the result
  of a query task is still loaded into the kachery cache: this allows transfer of data between nodes, as well as providing a fallback result if the external resource
  that would be queried is not available.
  * *Actions* are tasks which change the state of some resource, for example appending to a feed. Action tasks do not return any
  substantive result, only the success or failure of the task. (TODO: do we guarantee each action is only run once?)

For more details, consult the [tasks documentation](./tasks.md).

These three types of data, collectively called *information* in these pages,
are stored in a distributed fashion among the users of the network. The documentation
[discusses the kachery storage model in detail](./storage.md).

Additionally, kachery supports permissions that [restrict access to data and compute resources](./security.md).
