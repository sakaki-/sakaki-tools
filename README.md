# sakaki-tools Gentoo Overlay

Overlay containing various utility ebuilds for Gentoo on EFI.

Required for the [**EFI Gentoo End to End Install**](https://wiki.gentoo.org/wiki/EFI_Gentoo_End_to_End_Install) tutorial on the Gentoo wiki.

## List of ebuilds

* **app-portage/showem** (1.0.0) [source](https://github.com/sakaki-/showem)
  * Provides a simple utility script (**showem**(1)), which enables you to monitor the progress of a parallel **emerge**(1). A manpage is included.
* **sys-kernel/buildkernel** (1.0.3) [source](https://github.com/sakaki-/buildkernel)
 * Provides a script (**buildkernel**(8)) to build a (stub EFI) kernel (with integral initramfs) suitable for booting from a USB key on UEFI BIOS PCs. Automatically sets the necessary kernel configuration parameters, including the command line, and signs the resulting kernel if possible (for secure boot). Has a interactive and non-interactive (batch) mode. Manpages for the script and its configuration file (_/etc/buildkernel.conf_) are included.
* **app-portage/genup** (1.0.2) [source](https://github.com/sakaki-/genup)
 * Provides the **genup**(8) script, to simplify the process of keeping your Gentoo system up-to-date. **genup**(8) can automatically update the Portage tree, all installed packages, and kernel. Has interactive and non-interactive (batch) modes. A manpage is included.
* **app-crypt/efitools** (1.4.2-r2)
 * This package provides various useful tools for manipulating the EFI secure boot variables. However, at the time of writing, the latest version available on Gentoo (1.4.2-r1) does not yet reflect a [change made upstream](http://git.kernel.org/cgit/linux/kernel/git/jejb/efitools.git/commit/) which is necessary to allow proper operation with LVM under Gentoo. The ebuild supplied here (1.4.2-r2) is *identical* to the standard version (1.4.2-r1), except that it additionally applies a patch to bring version 1.4.2-r1 in line with upstream. It will be removed from the **sakaki-tools** repository when the official Gentoo repository version bumps.
* **app-crypt/staticgpg** (1.4.16)
 * A simple ebuild, derived from **app-crypt/gnupg** version 1.4.16, which creates a statically linked, no-pinentry version of **gpg**(1) suitable for use in an initramfs context. It can safely be installed beside a standard 2.x version of **app-crypt/gnupg** (which isn't SLOTted). Deploys its executable to _/usr/bin/staticgpg_. A placeholder manpage is included.

## Installation

**sakaki-tools** is best installed (on Gentoo) via **layman**(8).
Full instructions are provided on the [Gentoo wiki](https://wiki.gentoo.org/wiki/EFI_Gentoo_End_to_End_Install/Building_the_Gentoo_Base_System_Minus_Kernel#Preparing_to_Run_Parallel_emerges).

The following are short form instructions. If you haven't already installed **layman**(8), do so first:

    emerge --ask --verbose app-portage/layman
    echo 'source "/var/lib/layman/make.conf"' >> /etc/portage/make.conf

Make sure the `git` USE flag is set for the **app-portage/layman** package (it should be by default).

Next, create a custom layman entry for the **sakaki-tools** overlay, so **layman**(8) can find it on GitHub. Fire up your favourite editor:

    nano -w /etc/layman/overlays/sakaki-tools.xml

and put the following text in the file:

    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE repositories SYSTEM "/dtd/repositories.dtd">
    <repositories xmlns="" version="1.0">
        <repo priority="50" quality="experimental" status="unofficial">
    	    <name>sakaki-tools</name>
    	    <description>Various utility ebuilds for Gentoo on EFI, from sakaki.</description>
    	    <homepage>https://github.com/sakaki-/sakaki-tools</homepage>
    	    <owner>
    		    <email>sakaki@deciban.com</email>
    		    <name>sakaki</name>
            </owner>
    	    <source type="git">https://github.com/sakaki-/sakaki-tools.git</source>
        </repo>
    </repositories>

Then run:

    layman --sync-all
    layman --add="sakaki-tools"

If you are running on the stable branch by default, allow **~amd64** keyword files from this repository:

    echo '*/*::sakaki-tools ~amd64' >> /etc/portage/package.accept_keywords
    
Now you can install packages from the overlay. For example:

    emerge --ask --verbose app-portage/genup

## Maintainers

* [sakaki](mailto:sakaki@deciban.com)
