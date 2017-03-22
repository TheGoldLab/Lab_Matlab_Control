Release Note, PL2303 Mac OS X driver v1.2.1r2, Prolific Edition
=============================================

Supported device ID:
====================  
    VID:067B
    PID:2303

Kernel extension filename:
====================  
    ProlificUsbSerial.kext

Device base name: 
====================  
    usbserial

Device descriptions: 
====================  
    USB-Serial Controller

Driver version:
====================  
    1.2.1r2

Installer filename:
====================  
    PL2303_1.2.1.pkg

Installer script:
====================  
    Remove any previous installed driver first.

Installer title:
====================  
    Prolific USB to Serial Cable driver for Mac OS X

 
System Requirement:
====================  
. MacOS 10.1 or later for PowerPC based Mac
. MacOS 10.4 or later for Intel based Mac
. USB host controller
. Device using PL-2303H/X


====================  
History Change:
====================  

Changes from v1.2.1:
--------------------------------
. Rebuilt DMG file for Mac OS 10.2.8.

Changes from v1.2.0:
--------------------------------
. Modify version and copyright information in property list.

Changes from v1.1.0b1:
--------------------------------
. Migrate project to Xcode 2.2 and make the driver work on Intel based Mac.

Changes from v1.0.9b7:
--------------------------------
1. Fix data lost problem on TX and RX.
    1.1 TX queue available size does not returned correctly.
    1.2 RX queue overflow while adding received data to RX queue.
    -> Wait until available space on queue is enough for received data.

2. Fix last transmit can not completed on blocking mode.
    -> In blocking mode, send operation should returned after data has been sent from queue to device.

Changes from v1.0.9b6:
--------------------------------
. Unload and remove old .kext file before installing.
. Add build number on copyright information for identification driver version.
. Add build number of driver version on system log while driver is loaded.

Changes from v1.0.9b5:
--------------------------------
. Remove garbage file .DS_Store which will be copied by the installer.

Changes from v1.0.9b4:
--------------------------------
. Change installer authorization action from 'Admin Authorization' to 'Root Authorization'.

    Note: Some users with admin authorization does not have enough permission to install the driver,
    so the installation can not success for those users. With 'Root Authorization',
    the installer will ask for suitable authorization before installation and successfully install the driver.

. Correct the permissions of '/System/Library/Extensions' which overwritten by previous version driver installer.
    Note: Old driver changed the permissions of '/System/Library/Extensions' to allow all user to write,
    it generates a security problem.
 
==================================================
Prolific Technology Inc. 
http://tech.prolific.com.tw
 

