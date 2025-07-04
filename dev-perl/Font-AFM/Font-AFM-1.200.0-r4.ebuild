# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DIST_AUTHOR=GAAS
DIST_VERSION=1.20
inherit perl-module

DESCRIPTION="Parse Adobe Font Metric files"

SLOT="0"
KEYWORDS="amd64 ppc ~riscv sparc x86"

BDEPEND="
	test? (
		media-fonts/urw-fonts
	)
"

PATCHES=(
	"${FILESDIR}/${PN}-1.20-custom-test-font.patch"
)

src_test() {
	# nimbus sans l medium r normal iso8859-1
	TEST_FONT="n019003l" \
		TEST_FONT_WIDTH="4279" \
		METRICS="${EPREFIX}/usr/share/fonts/urw-fonts" \
		perl-module_src_test
}
