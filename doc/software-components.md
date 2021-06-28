# kachery comprises the following software components

* [kacheryhub](https://www.kacheryhub.org/) is a unique, centralized site, but its
[source code](https://github.com/kacheryhub/kacheryhub) is publicly available.

* [kachery-daemon](https://github.com/kacheryhub/kachery-daemon) is the software that
basic nodes run. It defines communication between the components of the kachery network,
as well as managing the local file store, and access to any defined computational resources.

* [kachery-client](https://github.com/kacheryhub/kachery-client) is a Python client
for interacting with a node. (The node may be a separate process running on the same
machine, or could be on a shared resource which multiple users might connect to.)
It also provides a command-line user interface to request or share files,
retrieve messages from feeds, etc. See documentation on
[setting up and using the kachery-client](./client-howto.md)

* kachery-js and kachery-react are typescript libraries for interacting with the kachery network from a web app. 
For instance, in the [sortingview](https://github.com/magland/sortingview)
tool, the web server running the labbox
software takes the place of a command-line client. These projects are not yet separated out into reusable libraries.