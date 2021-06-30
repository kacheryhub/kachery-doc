# Cloud storage

As discussed in the
[kachery-specific documentation on cloud storage buckets](https://github.com/kacheryhub/kachery-doc/blob/main/doc/storage-bucket.md),
cloud storage is a type of managed remote file storage provided by specialized
cloud storage providers. While its function is very similar to convetional
storage technologies, it has some important differences.

The following briefly discusses the evolution of conventional file storage,
and highlights the ways in which the cloud storage paradigm differs.

## Conventional file storage systems

### Local storage

The most basic and familiar model of data storage for most people
is a *local hard drive* attached
to a computer. The hard drive records a series of bits, which collectively
represent the data to be stored. The data to be recorded for any one purpose is
usually much smaller than the storage capacity of the hard drive, however.
Thus, there must be a structure
so that the system knows where one record ends and another one begins. The solution
is a *filesystem*: rules for how to organize data into
discrete data records (files), which are stored alongside
*metadata* that describes the data contents. Among other uses, the metadata
organizes the files into a directory hierarchy, allows naming of files,
tracks modification history and access control, and records the
ways a single file is split over several non-contiguous disk regions.

At its base, the filesystem offers a means
of interacting with a piece of storage hardware. Even as the structure
grows more complex (such as a filesystem with several disks mounted at
different mount points), conventional systems have
preserved the assumption of a hierarchy of files which is tightly coupled
to the arrangement of file contents on disk. For example,
without introducing logical volume management, a user could
mount a particular hard drive to `/home/User/MyCatPhotos` in the hierarchy,
but could not mount multiple hard drives to this same directory path.

A key feature of this structure is that it lends itself to interactive
use: the operating system finds files by reading the indexing metadata,
which is present alongside the actual data on the drive. This process
(on the part of the operating system)
naturally maps to the user being able to do the same thing--to browse files,
adjust their logical hierarchy or groupings, or tweak the
physical layout of the data on the drive.

The local-hard-drive model is convenient and minimally expensive, but hardware
failures (among other issues) can put data at risk, and files are only available
where they have been specifically copied. Keeping different systems in sync
is also a challenge--enough that many specialized
tools (like [rsync](https://en.wikipedia.org/wiki/Rsync)) are available
to users in order to facilitate it.

In short, the drawbacks of local storage are *file system reliability* due
to hardware failure, and *data availability* & *data synchronization* among
different machines.

### Remote file systems

*Remote [file servers](https://en.wikipedia.org/wiki/File_server)*,
such as an [FTP](https://en.wikipedia.org/wiki/File_Transfer_Protocol) server or a
[Network-Attached Storage](https://en.wikipedia.org/wiki/Network-attached_storage)
device, are an attempt to solve these issues:

* Centralizing file storage makes it easier to ensure files are backed up consistently;
there's only one machine to worry about.

* If files can be shared over a network, they are much more available than if they only
reside on one drive.

* Assuming users are diligent about storing changes in the central server, and that multiple
users do not need to alter the same file at once, data synchronization is manageable.

Ultimately, these systems extend the local file system
concept onto more sophisticated hardware and network architectures. In particular, they
still tend to imagine a hierarchy of files and directories, where organizational data
is stored alongside content records, as the appropriate system to allow access to
specific hardware.

Remote systems also create their own challenges for high availability and efficiency:

* Hardware still fails and needs to be replaced. Unless backups are continuous, there
is a risk of data loss.

* Central hardware is a single point of failure: even if data is not lost, file systems
may be unavailable while equipment is replaced. Seamless
[failover](https://en.wikipedia.org/wiki/Failover) to a backup system is hard, and even
having a second system at all requires additional expense.
Improved hardware strategies and abstraction, such as the use of
[RAID](https://en.wikipedia.org/wiki/RAID) and
[virtualization](https://en.wikipedia.org/wiki/Virtualization), can mitigate this, but
require increased cost and complexity.

* Centralized hardware can suffer from network latency, either continuously (due to
transferring large files) or periodically (during spikes in demand).

* Unless demand is constant, a system that can handle the peaks will wind up largely
unused during off-peak.

* User choices can still present challenges for data synchronization.

### Logical volumes

Requiring a direct one-to-one correspondence (or "tight coupling") between filesystems and
hard disk resources has several drawbacks. It limits the flexibility of file organization,
makes it challenging to store files which are large relative to the capacity of
individual disks, and provides no support for redundancy at the system level.

Solutions such as [logical volumes](https://en.wikipedia.org/wiki/Logical_volume_management)
(and  [storage virtualization](https://en.wikipedia.org/wiki/Storage_virtualization) more
generally) attempt to solve this problem by providing an additional layer of software
between the base operating system and the storage media. This software layer
takes on the responsibility of managing hardware so that an array of disks can appear
to the rest of the operating system like one large disk, enabling internal data distribution
(RAID), splitting directories (or even individual files) across multiple drives (sharding),
failure tolerance (hotswapping hardware replacement) and live resizing of resource allocations.
Ultimately, though, the logical volume system still works within the paradigm of conventional
hierarchical file systems, extending it onto new hardware configurations: to users, rather
than the administrators managing the system, the hierarchical structure remains in place,
and the logical volume looks and acts like a physical one.

## How cloud storage differs

Cloud storage can be considered an extension of the benefits of remote file systems and
logical volume management: the goal is to provide increased availability and reliability
by storing files so that they are accessible from anywhere over a network (in this case,
the Internet) and to decouple file storage from hardware management. But cloud storage
takes these trends even further, to completely abstract away file hierarchies and
structured storage.

The key distinction is actually in the *filesystem*. As discussed above, the filesystem
evolved as a solution for how to use specific hardware. It provides rules for the organization
of data on a hard disk, so that the operating system can understand it; and the internal
structures of this organization naturally promote hierarchical arrangement of records and
the idea of a file's location relative to other files.

Cloud storage does not attempt to reproduce this paradigm. Instead of starting with the
question of how to organize hard drives, cloud storage
begins with the goal of storing files (and abstracts away any consideration of
hardware implementation). This is line with the cloud computing paradigm generally,
which separates the functionality provided by computer resources--such as
running computations or storing data--from the specific hardware used to provide those functions.
Instead, the cloud paradigm offers *pools* of resources, with users using
the amount that is needed, regardless of where the resources come from physically.
It is the cloud provider's role to distribute the entire collection of user needs
efficiently across the available physical systems that provide the resources.

From the user perspective, this means one no longer stores a particular file on a drive (even
a logical/virtual one composed of multiple different hard drives)--one simply sends
the file over the Internet to the cloud storage provider, who makes sure it is accessible
through a [Uniform Resource Identifier](https://en.wikipedia.org/wiki/Uniform_Resource_Identifier).
The file itself has no necessary hierarchical relationship to any other file, and the
cloud provider is free to store it via whatever means are convenient and efficient. The
*collection* of files as a whole no longer has hierarchical internal structure, nor really
any structure at all that the user need be concerned with. This necessitates a new set
of rules for accessing the files--usually through a web API which identifies files by
URI as discrete units, rather than operating-system calls treating them as block device data streams.

### Advantage of cloud storage

Successful cloud providers can reduce costs through economies of scale, and
implement best practices internally, reducing the users' need for local administration
expertise. But vendors of conventional remote storage solutions have done the
same for many years--centralizing expertise, outsourcing hardware administration, and
even renting portions of shared servers all have a long history and are still available
today at a wide range of price points.

The big advantage of the cloud model is *scalability*: users can be provided with
resource pools of whatever size is needed to accommodate their current needs, and
their share of the resource pool can expand and contract as their needs do. This
avoids the "peak scaling" problem mentioned above, and can lead to more efficient
use of hardware resources, since hardware capacity can be allocated to different
users as it is needed, rather than overprovisioned and kept in reserve to deal
with peak demand.

### Disadvantages of cloud storage

Cloud storage shares many of the challenges of remote file storage generally.
Entrusting files to a third party (whether a cloud or a conventional storage
provider) and using shared hardware resources always has security implications.
Distributing files over a network is always slower than direct local links,
and always carries risks of bandwidth or network availability issues.

Two drawbacks are more specific to cloud storage:

* The URI-oriented file storage paradigm may require software design changes.

* Cost savings depend on making use of scalability: per-unit prices are often
higher than those available from conventional providers (and often vary from
moment to moment based on demand from other customers). If one user's demand
turns out to be largely static, instant scaling offers less benefit, and the
pricing structure can even make cloud solutions more expensive than hardware
provisioned statically, whether internally owned or leased by a conventional
provider.
