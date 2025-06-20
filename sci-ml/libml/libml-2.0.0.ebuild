# Copyright 2022-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit cmake

DESCRIPTION="Loading, configuring, and running machine learning models in production."
HOMEPAGE="https://github.com/snort3/libml/"
SRC_URI="https://github.com/snort3/${PN}/archive/refs/tags/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0 MIT BSD-2-Clause "
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~riscv"
IUSE="static-libs"
# IUSE="abseil cpuinfo eigen farmhash fft2d flatbuffers gemmlowp ruy neon2sse ml_dtypes XNNPACK tensorflow"

DEPEND="
	dev-cpp/abseil-cpp:=
	dev-libs/flatbuffers:=
"

src_prepare() {
	cmake_src_prepare
}


src_configure() {
	local mycmakeargs=(
		# Enable static libs
		-Dstatic_libs=$(usex static-libs)
	)
	cmake_src_configure
}
