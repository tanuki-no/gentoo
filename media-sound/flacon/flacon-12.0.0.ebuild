# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Tests require lots of disk space
CHECKREQS_DISK_BUILD=10G
inherit check-reqs cmake optfeature virtualx xdg-utils

DESCRIPTION="Extracts audio tracks from an audio CD image to separate tracks"
HOMEPAGE="https://flacon.github.io/"
SRC_URI="https://github.com/flacon/flacon/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="LGPL-2.1+"
SLOT="0"
KEYWORDS="amd64 ~x86"
IUSE="test"

BDEPEND="
	dev-qt/qttools:6[linguist]
	virtual/pkgconfig
"
RDEPEND="
	app-i18n/uchardet
	dev-qt/qtbase:6[gui,network,widgets,concurrent]
	media-libs/taglib:=
	media-sound/sox[flac,wavpack]
	media-video/mediainfo
"
DEPEND="${RDEPEND}
	test? (
		dev-cpp/yaml-cpp
		media-libs/faac
		media-libs/flac
		media-sound/alacenc
		media-sound/alac_decoder
		media-sound/lame
		<=media-sound/mac-4.12
		media-sound/opus-tools
		media-sound/shntool
		media-sound/ttaenc
		media-sound/vorbis-tools
		media-sound/wavpack
	)
"

PATCHES=(
	"${FILESDIR}"/${PN}-11.3.0-no-man-compress.patch
)

RESTRICT="!test? ( test )"

pkg_pretend() {
	use test && check-reqs_pkg_pretend
}

pkg_setup() {
	use test && check-reqs_pkg_setup
}

src_configure() {
	local mycmakeargs=(
		-DBUILD_TESTS="$(usex test)"
		-DUSE_QT5="OFF"
		-DUSE_QT6="ON"
	)
	cmake_src_configure
}

src_test() {
	# All tests fail with enabled sandbox
	# TODO: Get all tests to pass
	# See bug: #831592
	local -x SANDBOX_ON=0

	virtx "${BUILD_DIR}/tests/${PN}_test" || die
}

pkg_postinst() {
	optfeature_header "${PN} optionally supports formats listed below."
	optfeature 'FLAC input and output support' media-libs/flac
	optfeature 'WavPack input and output support' media-sound/wavpack
	optfeature 'APE input support' media-sound/mac
	optfeature 'ALAC input support' media-sound/alacenc
	optfeature 'ALAC output support' media-sound/alac_decoder
	optfeature 'TTA input support' media-sound/ttaenc
	optfeature 'AAC output support' media-libs/faac
	optfeature 'MP3 output support' media-sound/lame
	optfeature 'Vorbis output support' media-sound/vorbis-tools
	optfeature 'Opus input/output support' media-sound/opus-tools

	xdg_icon_cache_update
	xdg_desktop_database_update
}

pkg_postrm() {
	xdg_icon_cache_update
	xdg_desktop_database_update
}
