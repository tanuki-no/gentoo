# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="Very good, but slow, deflate or zlib compression"
HOMEPAGE="https://github.com/google/zopfli/"
SRC_URI="https://github.com/google/zopfli/archive/${P}.tar.gz"
S="${WORKDIR}/${PN}-${P}"

LICENSE="Apache-2.0"
SLOT="0/1"
KEYWORDS="~alpha amd64 arm arm64 hppa ~loong ~mips ppc ppc64 ~riscv ~s390 sparc x86 ~amd64-linux ~x86-linux"

DOCS=( CONTRIBUTORS README README.zopflipng )

PATCHES=( "${FILESDIR}"/${P}-cmake4.patch )
