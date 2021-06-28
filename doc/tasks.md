# Tasks

The main function of tasks in kachery is to provide a caching mechanism for expensive
computations--the "pure-calculation" task type. However, the task mechanism also provides
a convenient hook to allow kachery nodes or compute resources to execute python
code written by researchers. Thus two additional types of task are supported:
"query" tasks which depend on state that is not present in their arguments, and
the "action" tasks which modify state outside the kachery system.

## Example

Exposition below will assume the following code (`backend.py`) is being run on a
machine that is meant to execute kachery tasks.

```python
#!/usr/bin/env python3

import kachery_client as kc
import hither2 as hi

@kc.taskfunction('echo_immediate.2', type='pure-calculation')
def echo_immediate(*, a: str) -> str:
    return f'a is {a}'

@hi.function('echo_hither_fn', '1')
def echo_hither_fn(*, b: str) -> str:
    return f'b is {b}'

@kc.taskfunction('echo_hither_task.1', type='pure-calculation')
def echo_hither_task(*, b: str) -> hi.Job:
    job = hi.Job(echo_hither_fn, {'b': b})
    return job

def main():
    kc.run_task_backend(
        channels=['my_channel'],
        task_function_ids=[
            'echo_immediate.2',
            'echo_hither_task.1'
        ]
    )

if __name__ == '__main__':
    main()
```

Suppose an instance of `backend.py` received a request for the task `echo_immediate.2`
with parameter `{'a': "hello world"}`. The `run_task_backend` function looks up
the `echo_immediate.2` ID and executes the corresponding python function `echo_immediate`,
returning the value `hello world`. This result is then cached; so if any
future node wants to request the value of function ID `echo_immediate.2` with
parameter "hello world", the *requesting node* would check the cache first, find
the result, and be able to sidestep the entire task request.
However, a request for `echo_immediate.2` with `{'a': 'goodbye}'` would
not be in cache, and would require `echo_immediate` to be run again.

The above example also demonstrates the use of a hither function for asynchronous
execution. A request for `echo_hither_task.1`
with the value `{'b': 'hello world'}` causes the `echo_hither_task` python
function to be called. That task returns a hither Job, which is an asynchronous
deferred processing token that may be executed in a container and/or on a remote
resource or cluster node.
While the Job is processing, the task backend started by `backend.py` will
publish status updates on the `PROVIDE-TASK` pub-sub channel. Once
processing is complete, the return value of the Job will be placed in the kachery cache,
so nodes subsequently requesting `echo_hither_task.1` with the same `{'b': 'hello world'}`
parameter can retrieve the reslt from the cache without invoking the task system or
re-running either `echo_hither_task` or the `echo_hither_fn` hither function it wraps.
(Note that hither itself can also be configured with an independent local job cache,
so that even if the result of a particular kachery task is cycled out of the
kachery cache, re-running the hither Job can still avoid repeating a long-running
computation.)

## Task Execution

Tasks are executed by a *task backend*. The task backend is a persistent service
provided by the `kachery-client` package, and is a distinct process from the
daemon node provided by `kachery-daemon` (although they will usually be run on the
same machine). A task backend is initiated when a user-defined script makes a
call to `kc.run_task_backend` and will terminate when that script is terminated.

### Task Backend-to-Node Communication

In the example above, the task backend is initiated by running `backend.py`.
This process must have a connection [DESCRIBE HOW] to a node that is on the channel
`my_channel`, as declared in the `run_task_backend` call. The task backend
connects to the node by making a long-running HTTP [VERB ?] request with a list of the
registered function IDs; thus the node immediately knows what tasks are available,
and can request any of them to be run by responding to the HTTP request with the
desired task ID and parameters. When the task backend receives a request to execute
a task, it simply calls the corresponding python function.

Thus, the task backend communicates only with one node; most of the distributed
interactions take place at the level of node-to-node communication.

### Node-to-Node Communication

Each node with active "Provide Task" permissions on a channel must be connected
to a task backend in order to run tasks successfully. The "Provide Task" permission
grants "publish" (write) access to the `PROVIDE-TASK` pub-sub channel, and "subscribe"
(read) access to the `REQUEST-TASK` channel (see the reference on
[node-to-node communications](./node.md#communications)).

When a node ("**Requester**") wishes to run a task, the following occurs:

* **Requester** generates a deterministic unique ID **ID** based on the task ID and the
arguments to be passed.
* **Requester** checks the cloud storage cache for an entry matching this **ID**. If
found, **Requester** uses this cached value, and no further action is needed. (This system
will function even if there are no active nodes on the channel with "Provide Task" permissions.)
* If the value is not cached:
  * **Requester** publishes a request with the task ID and parameters on the `REQUEST-TASK`
  pub-sub channel for the kachery channel.
  * Every node ("**Provider**") with active "Provide Task" permissions on the kachery channel
  is subscribed to the `REQUEST-TASK` pub-sub channel, and thus notified of the request.
  * Each **Provider** checks whether its task backend provides the requested task.
  * **Provider** nodes that don't recognize the task do nothing.
  [ED: SHOULD THEY PUBLISH SOMETHING EXPLICIT TO `PROVIDE-TASK`?]
  * Each **Provider** node with a matching registered task ID instructs its task backend
  to call the corresponding python function (and provides it the parameter list
  from **Requester**). Each **Provider** publishes its status on the `PROVIDE-TASK` channel,
  so that **Requester** can fetch the results from the cloud cache once they are available.
  * For tasks implemented as hither functions, the **Provider** will publish Job status
  updates to the `PROVIDE-TASK` pub-sub channel, as well as the final results.

The exact contents of any particular task is up to the task implementer. However,
executing a task is a blocking call, so for anything
long-running, it is advisable to use [hither](https://github.com/flatironinstitute/hither)
or another means of executing the task asynchronously, to prevent the task backend from
hanging for an unacceptable length of time.

This description applies to "pure-calculation"-type tasks. The other two task
types are handled slightly differently:

* In the case of "query"-type tasks, **Requester** will make the request on the
`REQUEST-TASK` channel first, and only use cached results if new ones cannot be obtained.
* In the case of "action"-type tasks, the cache is skipped entirely, as these tasks are
intended to modify external state. [QUERY: DO WE NEED A "RUN-ONCE-ONLY" FEATURE?]

## Registering Tasks

*Tasks* are a mechanism to run user-defined python code. However, the system does not allow
arbitrary code execution: a task backend will only run tasks which the implementer has
explicitly registered through the `task_function_ids` parameter of `run_task_backend`.

To be registered, a python function must also be decorated with the `@taskfunction` decorator.
This decorator takes a unique identifier for the task function, as well as a type (one
of "pure-calculation", "query", or "action".) Registered functions should take only `kwargs`
parameters. Moreover, they can only accept parameters that are JSON-serializable: either
basic types, or a few others with explicit serialization support (e.g. Numpy arrays). In no event
should a task function be passed executable code: parameters come from an arbitrary node on the
network, and (permissions/authorization notwithstanding) they should be considered untrusted
inputs that need to be sanitized before being used on secured systems.

## Task Permissions

The "Request Task" and "Provide Task" permissions govern task access on a channel. Nodes can
request task results if granted "Request Task" access, which will also allow *publish* rights
on the channel's `REQUEST-TASK` pub-sub channel and *subscribe* rights on the channel's
`PROVIDE-TASK` pub-sub channel. Nodes can provide task results if granted "Provide Task" access,
which provides complementary pub-sub rights (*subscribe* on `REQUEST-TASK` and *publish* on
`PROVIDE-TASK`).

Because of this structure, task requests are inherently associated with a specific channel.
However, in the event that multiple channels share a single cloud storage cache, a node could
conceivably retrieve task results from a different channel; so it is advisable not to share
cloud storage caches between channels.

Permission is currently granular at the node level, not the task level. A node that can
request task execution is allowed to request any task registered with the backend.

## Task Results

Results of "pure-calculation" or "query" tasks will be written to the cloud storage cache.
"Action"-type tasks only return success or failure, which will be communicated over the
pub-sub channel.

In the event that the python function backing a task request returns a hither Job, the
task backend will automatically write the Job result to the cloud cache on Job completion.
If the hither Job fails, [WHAT HAPPENS?]

## Caveats

### Channel-Storage Interactions

[IS THIS TRUE?]
Any task request must specify which channel it wants the response from. However, a node
looking for task results will potentially look at every cloud storage it is aware of,
not only the storage associated with the channel on which the request was made. While it
is extremely unlikely that two sets of unrelated job results would have the same fingerprint,
in specific circumstances it might be possible for a node to obtain or share results from a
different channel where it might not have the same permissions.

### Race conditions for task execution

In the current design, task provider nodes do not interact with each other. This could
potentially lead to multiple nodes attempting to execute the same task simultaneously
on different backends, which is potentially inefficient for computationally intensive
tasks (and could be problematic for action-type tasks).

There can also be an issue with multiple provider nodes uploading data to the same
file location on the cloud bucket, if multiple providers' instances of the task finish
at different rates.
