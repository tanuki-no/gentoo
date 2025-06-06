# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="A remake of the computer game Ultima IV"
HOMEPAGE="https://xu4.sourceforge.net/"
SRC_URI="https://sourceforge.net/projects/xu4/files/${PN}/$(ver_cut 1-2)/${P}.tar.gz
	https://ultima.thatfleminggent.com/ultima4.zip
	https://downloads.sourceforge.net/xu4/u4upgrad.zip"
#S="${WORKDIR}/u4-${PV}/"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="allegro"

RDEPEND="
	dev-libs/boron
	allegro? ( media-libs/allegro:5[opengl] )
	!allegro? ( media-libs/glfw )
	>=media-libs/faun-0.2.1
	media-libs/libglvnd
	media-libs/libpng:=
	sys-libs/zlib:=[minizip]
"
DEPEND="${RDEPEND}"
BDEPEND="app-arch/unzip"

PATCHES=(
	"${FILESDIR}/1.4-system-minizip.patch"
	"${FILESDIR}/1.4.3-glfw-build.patch"
)

src_unpack() {
	# xu4 will read the data files right out of the zip files
	# but we want the docs from the original.
	unpack ${P}.tar.gz
	unpack ultima4.zip
	# Place zips where make install expects them
	cp "${DISTDIR}/ultima4.zip" "${DISTDIR}/u4upgrad.zip" "${S}" || die
}

src_prepare() {
	default

	# rm as part of using system minizip patch
	rm -f src/unzip.{c,h} || die
	sed -i -e '/CXXFLAGS+=-O3 -DNDEBUG/d' src/Makefile || die
	# Don't strip executable
	sed -i -e 's:-s src/xu4:src/xu4:g' Makefile || die
}

src_configure() {
	# custom configure
	local myconf=(
		$(usev allegro --allegro)
		$(usev !allegro --glfw)
	)
	./configure "${myconf[@]}" || die
}

src_install() {
	emake DESTDIR="${D}/usr" install
	dodoc AUTHORS README.md doc/*.txt "${WORKDIR}"/*.txt
	insinto "/usr/share/xu4"
	doins "${DISTDIR}/ultima4.zip"
}
