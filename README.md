# sakaki-tools Gentoo Overlay

Overlay containing various utility ebuilds for Gentoo on EFI.

> 31 Oct 2020: sadly, due to legal obligations arising from a recent change in my 'real world' job, I must announce I am **standing down as maintainer of this project with immediate effect**. For the meantime, I will leave the repo up (for historical interest, and since the ebuilds etc. may be of use to others); however, I plan no further updates, nor will I be accepting / actioning further pull requests or bug reports from this point. Email requests for support will also have to be politely declined, so, **please treat this as an effective EOL notice**.<br><br>For further details, please see my post [here](https://forums.gentoo.org/viewtopic-p-8522963.html#8522963).<br><br>If you have used my [EFI Guide](https://wiki.gentoo.org/wiki/User:Sakaki/Sakaki%27s_EFI_Install_Guide) (and this repo) to install your PC-based Gentoo system, it *should* still continue to work for some time, **but** you should now take steps to migrate to a baseline [Gentoo Handbook](https://wiki.gentoo.org/wiki/Handbook:AMD64) install (since the underlying tools, such as [`buildkernel`](https://github.com/sakaki-/buildkernel), will also now no longer be supported and may eventually fail as more modern kernels etc. are released).<br><br>With sincere apologies, sakaki ><

Required for the tutorial ["**Sakaki's EFI Install Guide**"](https://wiki.gentoo.org/wiki/Sakaki's_EFI_Install_Guide) on the Gentoo wiki.

## List of ebuilds

* **app-portage/showem** [source](https://github.com/sakaki-/showem)
  * Provides a simple utility script (**showem**(1)), which enables you to monitor the progress of a parallel **emerge**(1). A manpage is included.
* **sys-kernel/buildkernel** [source](https://github.com/sakaki-/buildkernel)
  * Provides a script (**buildkernel**(8)) to build a (stub EFI) kernel (with integral initramfs) suitable for booting from a USB key on UEFI BIOS PCs. Automatically sets the necessary kernel configuration parameters, including the command line, and signs the resulting kernel if possible (for secure boot). Has a interactive and non-interactive (batch) mode. Manpages for the script and its configuration file (_/etc/buildkernel.conf_) are included.
* **app-portage/genup** [source](https://github.com/sakaki-/genup)
  * Provides the **genup**(8) script, to simplify the process of keeping your Gentoo system up-to-date. **genup**(8) can automatically update the Portage tree, all installed packages, and kernel. Has interactive and non-interactive (batch) modes. A manpage is included.
* **app-portage/porthash** [source](https://github.com/sakaki-/porthash)
  * Provides the **porthash**(1) script, which creates, or by default verifies, a signed `sha512` "master" hash of the specified Portage repostitory tree (by default, `/usr/portage`). It is intended to provide assurance - when distributing a repo snapshot over an unauthenticated channel such as rsync - that the consitutent ebuilds, manifests etc. have not been tampered with in transit. A manpage is included.
* **app-portage/porthole**
  * A simple ebuild, extending porthole-0.6.1-r5, and patching an issue experienced on some systems where `PORTDIR` is undefined.
* **app-crypt/efitools**
  * This package provides various useful tools for manipulating the EFI secure boot variables. It is no longer required as a more modern version has become available in the main Gentoo tree.
* **app-crypt/staticgpg**
  * A simple ebuild, derived from **app-crypt/gnupg** version 1.4.16, which creates a statically linked, no-pinentry version of **gpg**(1) suitable for use in an initramfs context. It can safely be installed beside a standard 2.x version of **app-crypt/gnupg** (which isn't SLOTted). Deploys its executable to _/usr/bin/staticgpg_. A placeholder manpage is included.
* **sys-apps/coreboot-utils** [upstream](https://www.coreboot.org)
  * This package provides a few utilities from the coreboot project, specifically `ifdtool` to parse and modify flash dumps of Intel firmware and (on `amd64` only) `intelmetool` to query the status of the Intel Management Engine.
* **sys-apps/me_cleaner** [upstream](https://github.com/corna/me_cleaner)
  * Provides `me_cleaner-1.2`; a tool for disabling the Intel Management Engine, by modifying its firmware.
* **media-gfx/fotoxx** [upstream](https://www.kornelix.net/fotoxx/fotoxx.html)
  * Provides `fotoxx-18.01.3`, a program for improving digital photographs (supports HDR etc.).
* **(eclass/)java-maven-pkg.eclass**
  * Provides an eclass to support building Maven pacakges from source. Use `mvn2ebuild` in place of `mvn` within a working Maven build tree, to create a 'starter' ebuild using this eclass.
* **app-portage/mvn2ebuild**
  * Provides a simple utility to create a starter ebuild for a working Maven Java build, leveraging the `java-maven-pkg` eclass.
* **dev-java/jitsi-sctp** [upstream](https://github.com/mstyura/jitsi-sctp)
  * Provides a from-source build of the JNI component for the usrsctp library (currently for `~arm64` and `~amd64`). Uses `java-maven-pkg` eclass.
* **acct-group/jitsi**
  * Provides a runtime group used by Jitsi services. Currently set at 377.
* **acct-user/jicofo**
  * Provides a runtime uid for the JItsi COnference FOcus server. Currently set at 377.
* **acct-user/jvb**
  * Provides a runtime uid for the Jitsi Videobridge SFU. Currently set at 376.
* **net-im/jicofo** [upstream](https://github.com/jitsi/jicofo)
  * Provides a from-source build of the JItsi Meet COnference FOcus server (media session manager). Uses `java-maven-pkg` eclass.
* **net-im/jitsi-meet-master-config**
  * Provides master configuration settings for Jitsi Meet server, via a prompt-based tool.
* **net-im/jitsi-meet-prosody** [upstream](https://github.com/jitsi/jitsi-meet)
  * Provides Prosody configuration and plugins for use with Jitsi Meet.
* **net-im/jitsi-meet-server**
  * Provides a top-level service for the Jitsi Meet baseline server set, allowing all subcomponents to be started and stopped together. Emerge this package to build the Jitsi complex, then run `emerge --config jitsi-meet-master-config`, and then start the `jitsi-meet-server` service. Supports both OpenRC and systemd.
* **net-im/jitsi-meet-turnserver** [upstream](https://github.com/jitsi/jitsi-meet)
  * This package configures the `net-im/coturn` server to work with Jitsi Meet.
* **net-im/jitsi-meet-web-config** [upstream](https://github.com/jitsi/jitsi-meet)
  * Provides Webserver (nginx/apache) configurations for use with Jitsi Meet.
* **net-im/jitsi-meet-web** [upstream](https://github.com/jitsi/jitsi-meet)
  * Provides an (upstream deb-derived) WebRTC, JavaScript/WASM-based videoconferencing client webroot filestructure.
* **net-im/jitsi-videobridge** [upstream](https://github.com/jitsi/jitsi-videobridge)
  * Provides a from-source build of Jitsi VideoBridge - a WebRTC compatible SFU. Uses `java-maven-pkg` eclass.
* **dev-python/xkcdpass** [upstream](https://github.com/redacted/XKCD-password-generator)
  * Provides a tool to generate secure multiword passwords/passphrases, inspired by XKCD 936.

## Installation

As of version >= 2.2.16 of Portage, **sakaki-tools** is best installed (on Gentoo) via the [new plug-in sync system](https://wiki.gentoo.org/wiki/Project:Portage/Sync).
Full instructions are provided on the [Gentoo wiki](https://wiki.gentoo.org/wiki/Sakaki's_EFI_Install_Guide/Building_the_Gentoo_Base_System_Minus_Kernel#Preparing_to_Run_Parallel_emerges).

The following are short form instructions. If you haven't already installed **git**(1), do so first:

    # emerge --ask --verbose dev-vcs/git 

Next, create a custom `/etc/portage/repos.conf` entry for the **sakaki-tools** overlay, so Portage knows what to do. Make sure that `/etc/portage/repos.conf` exists, and is a directory. Then, fire up your favourite editor:

    # nano -w /etc/portage/repos.conf/sakaki-tools.conf

and put the following text in the file:
```
[sakaki-tools]
 
# Various utility ebuilds for Gentoo on EFI
# Maintainer: sakaki (sakaki@deciban.com)
 
location = /usr/local/portage/sakaki-tools
sync-type = git
sync-uri = https://github.com/sakaki-/sakaki-tools.git
priority = 50
auto-sync = yes
```

Then run:

    # emaint sync --repo sakaki-tools

If you are running on the stable branch by default, allow **~amd64** keyword files from this repository. Make sure that `/etc/portage/package.accept_keywords` exists, and is a directory. Then issue:

    # echo "*/*::sakaki-tools ~amd64" >> /etc/portage/package.accept_keywords/sakaki-tools-repo
    
Now you can install packages from the overlay. For example:

    # emerge --ask --verbose app-portage/genup

## Maintainers

* [sakaki](mailto:sakaki@deciban.com)
