sclp - build
====

***
**WARNING - these instructions are incomplete at this time. Feel free to follow along as we update them, but when you get to the end, you wont have a working system. This warning will be removed when the instructions are complete.**
***

**Introduction**

This step-by-step guide walks you through building the SCLP server and Chromebook boot image from scratch.

**Prerequisites**

This guide assumes you are starting with a server, with two network cards, and a fresh installation of Ubuntu 14.04 Server (not Edubuntu - that comes later).

**Setup the Network**

First, we set the servers network cards. First, edit the interfaces file.

	sudo nano /etc/network/interfaces
	
With the following settings:

	auto lo
	iface lo inet loopback

	auto eth0
	iface eth0 inet dhcp

	auto eth1
	iface eth1 inet static
	address 192.168.100.254
	netmask 255.255.255.0

Then, restart networking.

	sudo /etc/init.d/networking restart

The settings above assume that your internet connection on the first ethernet port assigns an address to you automatically. If your provider has given you a static address, you need to set it here.

**Setup the DHCP Server**

The Chromebooks on the network will get their address from the server and also use it as a router. To do so, the server needs to run a DHCP server on the second ethernet port:

	sudo apt-get install dhcp3-server
	sudo nano /etc/default/isc-dhcp-server
	
Set the following settings, save, and exit:

	INTERFACES="eth1"
	
Then edit the dhcpf.conf

	sudo nano /etc/dhcp/dhcpd.conf
	
And set the following settings, save, and exit:

	option domain-name "yourdomain.org";
	option domain-name-servers 192.168.100.254;
	authoritative;
	option subnet-mask 255.255.255.0;
	option broadcast-address 192.168.100.255;
	option routers 192.168.100.254;


	subnet 192.168.100.0 netmask 255.255.255.0 {
		range 192.168.100.2 192.168.100.99;
	} 
	
**Setup the NFS Server**

The Chomebooks will load the majority of their software from the server over the network. Setup the NFS server:

	sudo mkdir /opt/nfs
	sudo apt-get install nfs-kernel-server
	sudo nano /etc/exports

Add to exports, save, and exit:

	/home 192.168.100.0/255.255.255.0(rw,sync,no_root_squash,no_subtree_check)
	/opt/nfs 192.168.100.0/255.255.255.0(ro,sync,no_root_squash,no_subtree_check) 
	
Then start the server:

	sudo exportfs -a
	sudo service nfs-kernel-server start 
	
**Setup the LDAP Server**

The Chromebook will login against a central user database on the server called LDAP. Setup the LDAP server:

	sudo apt-get install slapd ldap-utils
	
Enter your admin password when prompted.

Now configure:

	sudo dpkg-reconfigure slapd
	
With the following options:

	Omit OpenLDAP server configuration?
	No
	
	DNS domain name:
	yourdomain.org
	
	Organization name:
	yourdomain
	
	Administrator password:
	<your admin password>
	
	Administrator password:
	HDB
	
	Remove the database when slapd is purged?
	No
	
	Move old database?
	Yes
	
	Allow LDAPv2 protocol?
	No
	
To make our LDAP perform better, lets setup some indexes:

	nano ~/index.ldif
	
Enter these lines, save, and exit:

	dn: olcDatabase={1}hdb,cn=config
	add: olcDbIndex
	olcDbIndex: uid eq
	olcDbIndex: uidNumber eq
	olcDbIndex: gidNumber eq
	olcDbIndex: memberUid eq
	olcDbIndex: cn eq
	olcDbIndex: uniqueMember eq

	
Then start the indexing:

	sudo ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f index.ldif
	
LDAP is easier to manage with a graphical interface. Install the manager:

	sudo apt-get install phpldapadmin
	
Configure the manager:

	sudo nano /etc/phpldapadmin/config.php
	
Set these options, save, and exit:

	$servers->setValue('server','base',array('dc=yourdomain,dc=org'));
	$servers->setValue('login','bind_id','cn=admin,dc=yourdomain,dc=org');
	$config->custom->appearance['hide_template_warning'] = true;

Fix a bug in phpldapadmin to do with php5:

	sudo nano /usr/share/phpldapadmin/lib/TemplateRender.php
 
Change line 2469 to:

	$default = $this->getServer()->getValue('appearance','password_hash_custom');

Enable bash shell as an option. Edit posixAccount.xml:

	sudo nano /etc/phpldapadmin/templates/creation/posixAccount.xml

Add this option under loginShell, save, and exit:

	<value id="/bin/bash">/bin/bash</value>

Create a basic web page for the server:

	sudo rm /var/www/html/index.html 
	sudo nano /var/www/html/index.html 

Enter the following, save, and exit:

	<h1>NewLifeOrissa.net</h1>
	<br><br>
	<a href='/phpldapadmin'>User Admin</a>

Navigate to the webpage http://192.168.100.254 and click on the User Admin link.

Login to the LDAP manager using the password you set above.

To add a record to the LDAP:

* Click on the plus sign to expand your domain.
* Click on "Create new entry here"

Let's setup some basic records. We will organize our users into 'groups':

* Click on the plus sign to expand your domain in the left menu.
* Click on "Create new entry here"
* Create a record with the "Generic: Organizational Unit" template.
* Call it "groups"
* Commit the record

Repeat the above steps to create a "users" unit:

* Create a record with the "Generic: Organizational Unit" template.
* Call it "users"
* Commit the record

Create groups called "admin":

* Click on the "ou=groups" record in the left menu.
* Click on "Create a child entry" in the right panel.
* Choose the "Generic: Posix Group" template.
* Enter "admin" for the group name.
* Commit the record

Repeat the above steps to create a "user" group.

Now we can setup users:

* Click on the "ou=users" record in the left menu.
* Click on "Create a child entry" in the right panel.
* Choose the "Generic: User Account" template.
* Fill out the user info, making sure the common name and home directory match and are unique:
	* Common name: Jonathan Gould
	* First name: Jonathan
	* GID Number: user
	* Home directory: /home/users/jgould
	* Last name: Gould
	* Login shell: /bin/sh
	* Password: mypassword
	* User ID: jgould

 

**Setup the Chroot**

The chroot is a custom Edubuntu image that the Chromebooks will run. We start by building a basic image:

	sudo apt-get install debootstrap
	sudo debootstrap --arch i386 trusty /opt/nfs
	
Each time you want to edit the chroot, you must enter it:

	sudo chroot /opt/nfs
	mount -t proc none /proc
	
You can now install packages, change settings, etc and they will affect the Chromebook image. When you are done making changes, properly exit the chroot:

	umount /proc
	exit
	
**Install Software**

Now we have a very basic image, we need to enter the chroot (see above) and install some software. First, enable the Ubuntu sources:

	apt-get update
	apt-get install nano
	nano /etc/apt/sources.list

Add the sources, save, and exit:

	deb http://archive.ubuntu.com/ubuntu trusty main restricted universe
	deb-src http://archive.ubuntu.com/ubuntu trusty main restricted universe
	
Update the source cache, and continue to install:

	apt-get update
	apt-get install edubuntu-desktop
	apt-get install linux-image-generic-lts-trusty
	
Now determine the kernel version (using version number in /boot - ours is 3.13.0-24-generic):

	ls /boot/vmlinuz*
	
And install the correct linux headers:

	apt-get install linux-headers-3.13.0-24-generic
	
**Setup the NFS Client**

(still in chroot)

We need to make the image connect to our server for its image. First, install the NFS client:

	apt-get install nfs-common
	
Then edit the fstab file:

	nano /etc/fstab
	
Add the following, save, and exit:

	192.168.100.254:/home /home nfs auto,noatime,nolock,bg,nfsvers=4,intr,tcp,actimeo=1800 0 0

**Setup Overlayroot**

(still in chroot)

As the NFS root is read only, the Chromebook needs somewhere to write temp files, print jobs, etc. Install overlayroot:

	apt-get install overlayroot

Edit the overlayroot.conf:

	nano /etc/overlayroot.conf
	
Set the following, save, and exit:

	overlayroot="tmpfs"
	
This will create temp folders in memory. Later we'll move this to the Chromebooks flash.

**Install Language Packs**

Language packs are installed by a two digit code, which can be found [here](http://www.loc.gov/standards/iso639-2/php/English_list.php). To test the code, type:

	check-language-support -l en
	
Which will display all packages available for english. To install those packages, type:

	yes | apt-get install `check-language-support -l en`
	

**Set the Image Locale**

(still in chroot)

We need to set the language of the image. The following selects US English:

	locale-gen en_US.UTF-8
	dpkg-reconfigure locales
	
Edit the environment file:

	nano /etc/environment
	
Add the following lines, save, and exit:

	LC_ALL=en_US.UTF-8
	LANG=en_US.UTF-8
	


**Install Network Driver**

(still in chroot)

We need to build a module for the USB gigabit network card (we are using an Asix based driver). Download the driver source into /asix in the chroot and build the module:

	cd /asix
	nano Makefile
	
Edit the CURRENT variable to reflect our kernel version (detection doesnt work well in a chroot), and modify the install line, save, and exit:

	CURRENT = 3.13.0-24-generic
	
	install:
        su -c "cp -v $(TARGET).ko $(DEST) && /sbin/depmod -a $(CURRENT)"
	
Now make and install the driver:

	make
	make install

**Configure NFS**

(still in chroot)


NFS requires some more configuration. Edit the initramfs.conf:

	nano /etc/initramfs-tools/initramfs.conf

Change these settings, save, and exit:

	MODULES=netboot
	BOOT=nfs
	DEVICE=eth0
	NFSROOT=192.168.100.254:/opt/nfs

Then edit the modules file:

	nano /etc/initramfs-tools/modules
	
And add your network card module, save, and exit:

	ax88179_178a

Finally, update the initramfs:

	update-initramfs -u
	
**Setup Network**

(still in chroot)

Edit intefaces:

	nano /etc/network/interfaces
	
Set the following, save, and exit:

	auto lo
	iface lo inet loopback
	
	auto eth0
	iface eth0 inet dhcp
	
	
**Client Hostname**

(still in chroot)

Chromebooks booted from the NFS need a unique hostname assigned to them. Download the hostname script from this repo and copy it to /etc/initramfs-tools/scripts/init-bottom/ in the chroot.

Set the permissions on the script:

	cd /etc/initramfs-tools/scripts/init-bottom/
	chown root:root 09-hostname
	chmod 700 09-hostname
	
**Acer Modules**

(still in chroot)

The Chromebook needs some custom modules to fix issues with video and the trackpad. Download the trusty-patch script from this repo and copy it to /chromeos in the chroot.

Run the script:

	cd /chromeos/
	chmod a+x trusty-patch.sh
	./trusty-patch.sh
	update-initramfs -u

**Fix Suspend Issue**

(still in chroot)

A script is need to fix some suspend issues. Download the 05_sound script from this repo to /etc/pm/sleep.d/ and give it the right permissions:

	cd /etc/pm/sleep.d/
	chmod +x 05_sound

Edit rc.local:

	nano /etc/rc.local
	
Add the following lines, save, and exit:
	
	echo EHCI > /proc/acpi/wakeup
	echo HDEF > /proc/acpi/wakeup
	echo XHCI > /proc/acpi/wakeup
	echo LID0 > /proc/acpi/wakeup
	echo TPAD > /proc/acpi/wakeup
	echo TSCR > /proc/acpi/wakeup
	echo 300 > /sys/class/backlight/intel_backlight/brightness
	rfkill block bluetooth
	/etc/init.d/bluetooth stop

Do not remove the line at the end that says "exit 0"

**Fix Shutdown Script**

(still in chroot)

A default shutdown script appears to try to unmount the root NFS mount too early during shutdown. Edit the script:

	nano /etc/init.d/umountnfs.sh
	
Find the line:

	if [ "$DIRS" ]
	
Change to match below, save, and exit:

	if [ "$DIRS" -ne "/media/root-ro" ]
	
Be careful with the spaces and make sure it is exactly as above.

**LDAP**

(still in chroot)

Configure the chromebook to authenticate against the server:

	apt-get install ldap-auth-client nscd
	
When prompted, configure the ldap client:

	LDAP server Uniform Resource Identifier:
	ldap://192.168.100.254
	
	Distinguished name of the search base:
	dc=yourdomain,dc=org
	
	LDAP Version:
	3
	
	Make local root Database admin:
	No
	
	Does LDAP database require login?
	No
	
	Local crypt to use when changing passwords:
	md5
	
If you make a mistake, you can change these settings here:

	dpkg-reconfigure ldap-auth-config
	
Edit the nsswitch.conf file:

	nano /etc/nsswitch.conf
	
Set the settings, save, and exit:

	passwd:         ldap compat
	group:          ldap compat
	shadow:         ldap compat
	
Edit the common-session file:

	nano /etc/pam.d/common-session
	
Add a line at the bottom that reads:

	session required    pam_mkhomedir.so skel=/etc/skel umask=0022

Execute the following command to customize the login screen:

	sudo sh -c 'printf "[SeatDefaults]\nallow-guest=false\ngreeter-hide-users=true\ngreeter-show-manual-login=true\n" >/usr/share/lightdm/lightdm.conf.d/50-no-guest.conf'

	
**Update Initramfs**

(still in chroot)

Build a final init image before copying to the chromebook:

	update-initramfs -u
	
Exit the chroot:

	umount /proc
	exit
	
Then clean up the hostname file in the chroot (sometimes get set during update-initramfs):

	sudo nano /opt/nfs/etc/hostname
	
Make sure the file is empty.
	
**Test the Image**

(outside the chroot)

Exit the chroot (see above) and build a thumb drive for testing. We will ultimately install this image on the Chromebooks flash, but first we should test it.

Create a grub.cfg:

	nano ~/grub.cfg
	
Add these lines, save, and exit:

	menuentry "Edubuntu Workstation" {
		root=(hd0,msdos1)
		linux /boot/vmlinuz root=/dev/nfs nfsroot=192.168.100.254:/opt/nfs,ro ip=dhcp netboot=nfs rootdelay=5 noresume noswap i915.modeset=1 tpm_tis.force=1 tpm_tis.interrupts=0 nmi_watchdog=panic,lapic
		initrd /boot/initrd.img 		
	}

Make a bootable thumbdrive and copy our kernel and init files to it:

	sudo mdir /media/usb
	sudo mount /dev/sdb1 /media/usb
	sudo grub-install --force --no-floppy --boot-directory=/	media/usb/boot
	sudo cp ~/grub.cfg /media/usb/boot/grub
	sudo cp /opt/nfs/boot/vmlinuz-3.13.0-24-generic /media/usb/boot/vmlinuz
	sudo cp /opt/nfs/boot/initrd.img-3.13.0-24-generic /media/usb/boot/initrd.img
	sudo umount /media/usb

To boot the USB, we must enable some settings on the Chromebook.

* Power off the Chromebook
* Press and hold Escape and Refresh (F3) then press Power.
* When asked to insert recovery media, press Ctrl-D to enter developer mode.
* Let the Chromebook boot, select a wifi, accept the license agreement, but do not login.
* At the login screen, press Ctrl-Alt-Forward (F2) to enter the development console.
* Login with the username 'chronos'.

Execute the following commands:

	sudo bash
	chromeos-firmwareupdate --mode=todev
	sudo crossystem dev_boot_usb=1 dev_boot_legacy=1
	
Reboot the Chromebook. At the white splash screen, press Ctrl-L to boot to legacy mode. Your USB drive should now boot.

Later, after we test out the image, we will make legacy mode the permament boot option eliminating the need for all these steps.  

***

Incomplete - more instructions to come:

* Enable IP forwarding / DNS
* Connect LDAP to Google education
* Hamachi remote access
* Install on Chromebook
* Make legacy permanent
* Set grub default / time
* Move overlay to sda
* Add splash and quiet




