sclp
====

[Click here to go straight to the instructions...](BUILD.md).

**Sustainable Computer Lab Project**

Our goal is to design a low cost, sustainable computer lab for use in developing countries by non profit organizations. Requirements for the project include:

* Low cost.
* Offers local applications when disconnected from the internet (connectivity is poor in many places it will be used).
* Works well connected to unreliable utilities.
* Durable for hot / humid climates and unconditioned spaces (no moving parts, fans, etc).
* Requires very little local administration, and can be remotely maintained by our team (when Internet is available).

In addition, the lab should provide features that are expected from most computer labs:

* Server hosted home directories and centralized user database (students can login from any workstation).
* Full suite of productivity software.
* Access to cloud based tools and email (Google Education).
* Internet access (when available).


**Workstation Hardware** 

To minimize cost, reduce mechanical failure (fans and spinning drives), and work when the power fails, we have opted to use the Acer C720 Chromebook as our workstation platform. It offers some unique advantages:

* $199
* 16GB of built-in flash.
* Respectable amount of processor and RAM.
* Built in battery (up to six hours).

However, the Chromebook OS depends heavily on the internet (has limited offline use), and isn't really designed for multiple users.

**Software**

Our team decided that the best alternative for an operating system on the Chromebook is Edubuntu. Based on Ubuntu Desktop 14.04, Edubuntu offers several advantages:

* Again, low cost.
* Pre-loaded with educational software.
* Pre-loaded with productivity tools (Libre Office).
* Capable of working on the Chromebook (well, mostly).
 
In addition to using the Edubuntu software, students will be able to access Google Education cloud apps and email through the Chrome browser installed on each workstation.

**Server**

In addition to workstations, our goal is to provide a small server that provides:

* Centralized student login (LDAP).
* Home folder storage (NFS).
* Central software image for workstations to load (NFS Root).

**Server Hardware**

To design a server that will run reliably in this environment, we turned to the industrial computer experts at Logic Supply (www.logicsupply.com). The server they have designed features:

* Dual core i5 Haswell processor (2.4ghz) with a custom fanless heatpipe design (no fans).
* 16GB RAM.
* Dual SSD drives (configured in RAID 1 for redundancy).
* Sealed industrial enclosure.
* DC power in with wide voltage input (to be backed up by a UPS).

**Network**

Workstations will be connected to the server via a Cisco 24 port gigabit switch and ASIX USB 3.0 gigabit controller.
 

***

Much of the project revolves around making Edubuntu run on the Chromebook hardware, loaded from the server via NFS. Instructions to do this are located [here](BUILD.md).

Questions? Email jagould2012 -at- gmail .com
