# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..13} )

inherit autotools optfeature python-single-r1

if [[ ${PV} == "9999" ]] ; then
	inherit git-r3
	EGIT_REPO_URI="https://gitlab.com/${PN}/main.git"
else
	SRC_URI="https://gitlab.com/${PN}/main/-/archive/v${PV}/main-v${PV}.tar.bz2 -> ${P}.tar.bz2"
	KEYWORDS="~amd64 ~x86 ~x86-linux"
	S="${WORKDIR}/main-v${PV}"
fi

DESCRIPTION="Lightweight user-defined software stacks for high-performance computing"
HOMEPAGE="https://hpc.github.io/charliecloud/"
LICENSE="Apache-2.0"

SLOT="0"
IUSE="ch-image doc +fuse +json"

# Extensive test suite exists, but downloads container images
# directly and via Docker and installs packages inside using apt/yum.
# Additionally, clashes with portage namespacing and sandbox.
RESTRICT="test"

DOCS=( NOTICE README.rst )

REQUIRED_USE="${PYTHON_REQUIRED_USE}"

DEPEND="elibc_musl? ( sys-libs/argp-standalone )"
COMMON_DEPEND="
	ch-image? (
		$(python_gen_cond_dep '
			dev-python/lark[${PYTHON_USEDEP}]
			dev-python/requests[${PYTHON_USEDEP}]
		')
		dev-vcs/git
		net-misc/rsync
	)
	fuse? (
		sys-fs/fuse:3=
		sys-fs/squashfuse
	)
	json? (
		dev-libs/cJSON
	)
"
RDEPEND="
	${DEPEND}
	${COMMON_DEPEND}
	${PYTHON_DEPS}
"
BDEPEND="
	${COMMON_DEPEND}
	${PYTHON_DEPS}
	virtual/pkgconfig
	doc? (
		$(python_gen_cond_dep '
			dev-python/sphinx[${PYTHON_USEDEP}]
			dev-python/sphinx-rtd-theme[${PYTHON_USEDEP}]
		')
		net-misc/rsync
	)
"

src_prepare() {
	default
	# Remove -W from SPHINXOPTS to prevent failure due to warnings
	sed -i 's#^SPHINXOPTS .*=.*#SPHINXOPTS =#' doc/Makefile.am || die "Makefile patching failed"
	eautoreconf
}

src_configure() {
	local econf_args=(
		$(use_enable doc html)
		$(use_enable ch-image)
		$(use_with json)
		# activates linking against both fuse and squashfuse
		$(use_with fuse squashfuse)
		# https://github.com/ivmai/bdwgc not packaged
		--without-gc
		# Libdir is used as a libexec-style destination.
		--libdir="${EPREFIX}"/usr/lib
		# Attempts to call python-exec directly otherwise.
		--with-sphinx-python="${EPYTHON}"
		# This disables -Werror, see also: https://github.com/hpc/charliecloud/pull/808
		--enable-buggy-build
		# Do not use bundled version of dev-python/lark.
		--disable-bundled-lark
		# Use correct shebang.
		--with-python="${PYTHON}"
		# Disable configure checks vor OverlayFS causing sandbox violations.
		--disable-impolite-checks
	)
	econf "${econf_args[@]}"
}

src_install() {
	docompress -x "${EPREFIX}"/usr/share/doc/"${PF}"/examples
	default
}

pkg_postinst() {
	elog "Various builders are supported, as alternative to the internal ch-image."
	optfeature "Building with Buildah" app-containers/buildah
	optfeature "Building with Docker" app-containers/docker
	optfeature "Building with Podman" app-containers/podman
	optfeature "Progress bars during long operations" sys-apps/pv
	optfeature "Pack and unpack squashfs images" sys-fs/squashfs-tools
	optfeature "Build versioning with ch-image" dev-vcs/git
}
