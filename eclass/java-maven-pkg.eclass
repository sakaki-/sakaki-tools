# Copyright 2020 sakaki <sakaki@deciban.com>
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: java-maven-pkg.eclass
# @MAINTAINER:
# sakaki@deciban.com
# @AUTHOR:
# sakaki (sakaki@deciban.com)
# @BLURB: Utilities for Java packages using the Maven build system.
# @DESCRIPTION:
# This class provides support for Java packages using the Maven
# build system, creating an on-the-fly local Maven
# repository into which jars and poms can be inserted, from remote
# repos or from Portage-installed packages.
#
# Acknowledgement:
# Maven hackery below draws on patterns from net-p2p/bisq-0.6.3.ebuild

if [[ -z ${_JAVA_MAVEN_UTILS_ECLASS} ]]; then
	_JAVA_MAVEN_UTILS_ECLASS=1
fi

((EAPI<7)) && die "Unsupported EAPI=${EAPI:-0} (too old) for ${ECLASS}"

inherit java-utils-2 

BDEPEND+="
	>=dev-java/maven-bin-3.6
	>=dev-java/java-config-2.2.0-r4
"

if ! has java-pkg-2 ${INHERITED}; then
	die "java-maven-pkg eclass can only be inherited AFTER java-pkg-2"
fi
if has git-r3 ${INHERITED}; then
	die "git-r3 eclass can only be inherited AFTER java-maven-pkg"
fi

EXPORT_FUNCTIONS pkg_setup src_unpack src_prepare src_compile src_install

# @ECLASS-VARIABLE: __SVU_DONE
# @INTERNAL
# @DESCRIPTION:
# Whether the SRC_URI setup has already been done.
__SVU_DONE=0

# @ECLASS-VARIABLE: __MVN_P
# @INTERNAL
# @DESCRIPTION:
# Temporary copy of mvn executable, relative to ${T}.
__MVN_P=""

# @ECLASS-VARIABLE: CLASSPATH
# @OUTPUT_VARIABLE
# @DESCRIPTION
# Classpath derived for the target artefact and its deps.

# @ECLASS-VARIABLE: JAVA_GENTOO_CLASSPATH
# @DEFAULT_UNSET
# @DESCRIPTION:
# Comma or space separated list of java packages to include in the
# class path. The packages will also be registered as runtime
# dependencies of this new package. Dependencies will be calculated
# transitively. See "java-config -l" for appropriate package names.
#
# @CODE
#	JAVA_GENTOO_CLASSPATH="foo,bar-2"
# @CODE

# @ECLASS-VARIABLE: JAVA_GENTOO_CLASSPATH_EXTRA
# @DEFAULT_UNSET
# @DESCRIPTION:
# Extra list of colon separated path elements to be put on the
# classpath at compile time. Not usually required.

# @ECLASS-VARIABLE: EMAVEN_VENDOR
# @DEFAULT_UNSET
# @DESCRIPTION:
# List of strings specifying locations of various maven assets required
# for the build. Each string contains first a source location (either URI
# or fully qualified path) followed by a space, followed by the Maven
# coordinate name. The artefacts will have their pathname disambiguated
# and then be added to ${SRC_URI} automatically. You can use <ARCH>
# in these fully qualified paths - it will be substituted with Maven's
# os.detected.arch.

# @ECLASS-VARIABLE: EMAVEN_PARAMS
# @DESCRIPTION:
# Parameters to be passed to mvn during the compile stage.
EMAVEN_PARAMS="-DskipTests -Dassembly.skipAssembly=false clean package install -f pom.xml"

# @ECLASS-VARIABLE: EMAVEN_INSTALL_JAR_FROM
# @DESCRIPTION:
# Location of the main jar post-build, relative to the build root.
# You can use <ARCH> in this path - it will be substituted with
# Maven's os.detected.arch. 
EMAVEN_INSTALL_JAR_FROM="target/${PN}.jar"

# @ECLASS-VARIABLE: EMAVEN_INSTALL_JAR_TO
# @DESCRIPTION:
# Path of the main jar to install, relative to the install root.
# Usually just a filename.
# You can use <ARCH> in this path - it will be substituted with
# Maven's os.detected.arch. 
EMAVEN_INSTALL_JAR_TO="target/${PN}.jar"

# @ECLASS-VARIABLE: EMAVEN_FIXUP_SNAPSHOTS
# @DESCRIPTION:
# By default, the eclass automatically creates snapshot jar/pom
# files for a artefact, where there is only one existing
# jar/pom versioned pair satisfying the snapshot in the temporary
# local Maven repo. Set to 0 to disable this behaviour.
EMAVEN_FIXUP_SNAPSHOTS=1

# @ECLASS-VARIABLE: EMAVEN_FIXUP_MAVEN_METADATA
# @DESCRIPTION:
# By default, the eclass automatically finds all maven-metadata.xml
# files for non-SNAPSHOT entities.
EMAVEN_FIXUP_MAVEN_METADATA=1

# @ECLASS-VARIABLE: EMAVEN_COMPILE_OFFLINE
# @DESCRIPTION:
# By default, the eclass runs the Maven build with --offline
# set (thereby enforcing the self-sufficiency of the temporary
# local Maven repo). Set to 0 to disable this behaviour.
EMAVEN_COMPILE_OFFLINE=1

# @FUNCTION: java-maven-pkg_pkg_setup
# @DESCRIPTION:
# pkg_setup for simple Maven ebuilds. Adds specification of the
# arch to ${EMAVEN_PARAMS} (as this can often fail for aarch_64).
#
# Does not invoke the default handler.
java-maven-pkg_pkg_setup() {
	# we need to explicitly force the architecture settings for arm64 on some maven builds
	if use arm64; then
		EMAVEN_PARAMS+=" -Dos.detected.name=linux -Dos.detected.arch=aarch_64 -Dos.detected.classifier=linux-aarch_64"
	elif use amd64; then
		EMAVEN_PARAMS+=" -Dos.detected.name=linux -Dos.detected.arch=x86_64 -Dos.detected.classifier=linux-x86_64"
	else
		die "Unknown architecture (only arm64 and amd64 supported currently)"
	fi
	einfo "EMAVEN_PARAMS: '${EMAVEN_PARAMS}'"
}

# @FUNCTION: java-maven-pkg_setup_maven_src_uri
# @INTERNAL
# @DESCRIPTION:
# Goes through ${EMAVEN_VENDOR} and, for those with an http or https URI,
# adds them to SRC_URI, -> to a disambiguated artefact name (the
# disambiguation uses the full Maven coordinate of the artefact).
java-maven-pkg_setup_maven_src_uri() {
	if ((__SVU_DONE==0)); then
		local lib e uri fname r
		for lib in "${EMAVEN_VENDOR[@]}"; do
			e="${lib##*.}"
			if [[ "${lib:0:4}" == "http" ]]; then
				uri="${lib%% *}"
				coord="${lib##* }"
				fname="${coord##*/}"
				r="${coord%/*}"
				fname="${r//\//_}_${fname}"
				# rename to avoid clashes with common filenames
				SRC_URI+=" ${uri}/${coord} -> ${fname}"
			fi
		done
		__SVU_DONE=1
	fi
}

# @FUNCTION: java-maven-pkg_pkg_setup
# @DESCRIPTION:
# src_unpack for simple Maven ebuilds. Simply passes through only those
# assets which do _not_ have jar, pom or xml extensions to the default
# handler (assets that do have these extensions will be in the
# distfiles directory already, and will be handled by
# java-maven-pkg_src_prepare later).
#
# Invokes the default handler at the end.
java-maven-pkg_src_unpack() {
	((__SVU_DONE==1)) || die "java-maven-pkg_setup_maven_src_uri not called in ebuild global scope"
	local f e a=""
	for f in ${A}; do
		e="${f##*.}"
		if [[ ${e} != "jar" && ${e} != "pom" && ${e} != "xml" ]]; then
			a+="${f} "
		fi
	done
	A="${a% }"
	default
}

# @FUNCTION: java-maven-pkg_setup_maven_classpath
# @INTERNAL
# @DESCRIPTION:
# Creates and exports the ${CLASSPATH} variable, ensuring that
# all artefacts on the ${JAVA_GENTOO_CLASSPATH} list, and
# their deps, are added, and that the (fully qualified) artefacts
# on ${JAVA_GENTOO_CLASSPATH_EXTRA} are also added.
java-maven-pkg_setup_maven_classpath() {
	# auto generate classpath
	java-pkg_gen-cp JAVA_GENTOO_CLASSPATH
	local classpath="${JAVA_GENTOO_CLASSPATH_EXTRA}" dependency
	for dependency in ${JAVA_GENTOO_CLASSPATH}; do
		classpath="${classpath}:$(java-pkg_getjars --with-dependencies ${dependency})" \
			|| die "getjars failed for ${dependency}"
	done
	while [[ $classpath = *::* ]]; do classpath="${classpath//::/:}"; done
	while [[ $classpath = *//* ]]; do classpath="${classpath//\/\///}"; done
	classpath=${classpath%:}
	classpath=${classpath#:}

	export CLASSPATH="${classpath}"
}

# @FUNCTION: java-maven-pkg_src_prepare
# @DESCRIPTION:
# src_prepare for simple Maven ebuilds. We do two things here:
# create a temporary copy of the Maven binary subsystem
# in ${T} (to avoid sandbox violations), and create a temporary
# local Maven repo, at ${T}/m2/repository, which we then proceed
# to stock with artefacts taken from the /var/cache/distfiles
# directory, per ${EMAVEN_VENDOR}, and via direct links to
# artefacts installed to /usr/share via (Portage) deps.
# As an (optional) third step, this temporary repo is
# then cleaned up, by ensuring that any SNAPSHOTs refer,
# where possible (controlled by ${EMAVEN_FIXUP_SNAPSHOTS}).
# And as (optional) fourth step, further cleanup of the
# repo is done, renaming any non-SNAPSHOT maven-metadata.xml
# files to maven-metadata-central.xml, to ensure range
# deps can be resolved (controlled by ${EMAVEN_FIXUP_MAVEN_METADATA}).
#
# Invokes the default handler at the end.
java-maven-pkg_src_prepare() {
	((__SVU_DONE==1)) || die "You must call setup_maven_src_uri after EMAVEN_VENDOR setup"
	local arch
	if use arm64; then
		arch="aarch_64"
	elif use amd64; then
		arch="x86_64"
	else
		die "Unknown architecture!"
	fi
	export JAVA_HOME="$(java-config --jdk-home)"
	java-pkg_set-current-vm "$(basename "$(readlink /etc/java-config-2/current-system-vm)")"
	einfo "Making temporary working copy of maven-bin"
	# we do this as native Maven libs are unpacked in-place,
	# causing sandbox violations otherwise
	local MVN_PATH
	MVN_PATH="$(readlink -e "/usr/bin/$(eselect maven show)")"
	MVN_PATH="${MVN_PATH%/bin/mvn}"
	__MVN_P="$(basename "${MVN_PATH}")"
	cp -r "${MVN_PATH}" "${T}" || die "Failed to copy ${MVN_PATH}"
	einfo "Creating local maven repo for build"
	# create an on-the-fly maven local repo in the temp directory
	local d f maven_basedir="${T}/m2/repository"
	mkdir -p "${maven_basedir}" || die "Failed to create temporary local Maven repo"
	# jars from Portage will not have a matching pom (metadata) file;
	# so we create some plausible stand-in poms here, and copy
	# the jars into the maven repo too, so they are available at
	# build time
	local pv gid aid e s fname r coord

	for f in "${EMAVEN_VENDOR[@]}"; do
		s=${f%% *}
		coord=${f##* }
		e=${coord##*.}
		d=${coord%/*}
		f=${coord##*/}
		gid=$(cut -d '/' -f 1 <<<${d})
		aid=$(cut -d '/' -f 2 <<<${d})
		pv=$(cut -d '/' -f 3 <<<${d})
		mkdir -p "${maven_basedir}"/"${d}" || die
		if [[ "${s:0:4}" == "http" ]]; then
			# copy downloaded, checksummed asset
			# NB, we have to use the mapped (disambiguated) asset name
			fname="${coord##*/}"
			r="${coord%/*}"
			fname="${r//\//_}_${fname}"
			cp "${DISTDIR}/${fname}" "${maven_basedir}/${d}/${f}" || die
		elif [[ ${e} == "pom" && ${s} == "TEMPLATE" ]]; then
			# create standin pom with sensible values
			sed -e "s/GROUPID/${gid}/;s/ARTIFACTID/${aid}/;s/VERSION/${pv}/" >"${maven_basedir}/${d}/${f}" <<EOF
<project>
  <modelVersion>4.0.0</modelVersion>
  <groupId>GROUPID</groupId>
  <artifactId>ARTIFACTID</artifactId>
  <version>VERSION</version>
</project>
EOF
		elif [[ ${e} == "jar" || ${e} == "pom" ]]; then
			# assume this is a direct path (e.g. to an artefact
			# installed by another Portage java package); symlink it
			s="${s//<ARCH>/${arch}}"
			einfo "Creating symlink to '${s}' from '${maven_basedir}/${d}/${f}'"
			ln -s "${s}" "${maven_basedir}/${d}/${f}" || die
		else
			die "Unknown extension '${e}'"
		fi
	done
	# fixup missing SNAPSHOT files in repo, if any, by creating copies
	if ((EMAVEN_FIXUP_SNAPSHOTS==1)); then
		local p n v t x
		for x in jar pom; do
			for p in $(find "${maven_basedir}" -type d -name '*SNAPSHOT'); do
				n="${p%/*}"
				n="${n##*/}"
				v="${p##*/}"
				# don't process ourself!
				[[ "${n}" == "${PN}" ]] && continue
				if [[ ! -e "${p}/${n}-${v}.${x}" ]] && (($(find "${p}" -name "${n}"'*.'"${x}" | wc -l)==1)); then
					einfo "Creating missing ${n}-${v}.${x} file"
					cp -d "${p}"/*."${x}" "${p}/${n}-${v}.${x}"
				fi
			done
		done
	fi
	if ((EMAVEN_FIXUP_MAVEN_METADATA==1)); then
		local m
		for m in $(find "${maven_basedir}" -type d -path '*SNAPSHOT*' -prune -type f -o -name 'maven-metadata.xml'); do
			einfo "Migrating ${m/${maven_basedir}\//} to maven-metadata-central.xml"
			mv "${m}" "${m%*.xml}-central.xml"
		done
	fi
	default
}

# @FUNCTION: java-maven-pkg_src_compile
# @DESCRIPTION:
# src_compile for simple Maven ebuilds. Invokes a build
# using our temporary copy of mvn, and using the
# temporary local artefact repo created by
# java-maven-pkg_src_prepare. If ${EMAVEN_COMPILE_OFFLINE}
# is set (the default), the build will happen in offline
# mode (network access will be sandboxed in any event).
#
# Does not invoke the default handler.
java-maven-pkg_src_compile() {
	# following not strictly necessary, since the local maven
	# repo should have all necessary classes in for the build
	# but provide it anyway
	java-maven-pkg_setup_maven_classpath
	# build using our temporary copy of Maven, and
	# using our local Maven repo
	local ol="--offline"
	((EMAVEN_COMPILE_OFFLINE!=1)) && ol=""
	${T}/${__MVN_P}/bin/mvn ${ol}\
		-Dmaven.repo.local="${T}/m2/repository" \
		${EMAVEN_PARAMS} || die "Maven build failed"
}

# @FUNCTION: java-maven-pkg_src_install
# @DESCRIPTION:
# src_install for simple Maven ebuilds. Simply installs
# ${EMAVEN_INSTALL_JAR_FROM} to ${EMAVEN_INSTALL_JAR_TO}.
#
# Suitable for e.g. simple library packages, but not for handling
# end-applications with a bundled lib/ etc; in such cases, you
# should provide your own src_install (see e.g. one of the
# net-im/jitsi-videobridge::sakaki-tools ebuilds, for an example of
# what to do in such cases).
#
# Does not invoke the default handler.
java-maven-pkg_src_install() {
	[[ -z "${EMAVEN_INSTALL_JAR_FROM}" ]] && die "You must set EMAVEN_INSTALL_JAR_FROM"
	[[ -z "${EMAVEN_INSTALL_JAR_TO}" ]] && die "You must set EMAVEN_INSTALL_JAR_TO"
	local arch
	if use arm64; then
		arch="aarch_64"
	elif use amd64; then
		arch="x86_64"
	else
		die "Unknown architecture!"
	fi
	java-pkg_newjar "${EMAVEN_INSTALL_JAR_FROM//<ARCH>/${arch}}" \
		"${EMAVEN_INSTALL_JAR_TO//<ARCH>/${arch}}"
}

