# kachery use cases

## Share files and Python data objects between workstations

If you want to send and receive files via kachery, you (or your administrator, for shared setups)
will need to install and run [kachery-daemon](./kacheryhub-markdown/hostKacheryNode.md) on the machine that you intend to be the
host of the node.
You will also need to use [kacheryhub.org](https://kacheryhub.org) to connect your new node to the channel you'd
like to use to share data.

Once this is done, [install kachery-client](./client-howto.md) and you'll be ready to start!

See [sharing data between workstations using Python](./sharing-data.md)

## Host a web application

The largest use of kachery is as a library to facilitate other applications, such as
web applications; see our [section on building projects that make use of kachery](./building.md).