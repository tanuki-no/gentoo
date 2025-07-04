# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop eapi9-pipestatus linux-info readme.gentoo-r1 xdg-utils

DESCRIPTION="Video conferencing and web conferencing service"
HOMEPAGE="https://zoom.us/"
SRC_URI="https://zoom.us/client/${PV}/${PN}_x86_64.tar.xz -> ${P}_x86_64.tar.xz"
S="${WORKDIR}/${PN}"

LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="-* ~amd64"
IUSE="opencl pulseaudio wayland +zoom-symlink"
RESTRICT="mirror bindist strip"

RDEPEND="zoom-symlink? ( !games-engines/zoom )
	>=app-accessibility/at-spi2-core-2.46.0:2
	app-crypt/mit-krb5
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/fdk-aac:0/2
	media-libs/fontconfig
	media-libs/freetype
	media-libs/mesa[gbm(+)]
	media-sound/mpg123
	net-print/cups
	sys-apps/dbus
	sys-apps/util-linux
	sys-libs/glibc
	sys-libs/zlib
	virtual/libudev
	virtual/opengl
	x11-libs/cairo
	x11-libs/libdrm
	x11-libs/libX11
	x11-libs/libxcb
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libxkbcommon[X]
	x11-libs/libXrandr
	x11-libs/libXrender
	x11-libs/libxshmfence
	x11-libs/libXtst
	x11-libs/pango
	x11-libs/xcb-util-image
	x11-libs/xcb-util-keysyms
	x11-libs/xcb-util-renderutil
	x11-libs/xcb-util-wm
	opencl? ( virtual/opencl )
	pulseaudio? ( media-libs/libpulse )
	wayland? ( dev-libs/wayland )"

BDEPEND="dev-util/bbe"

CONFIG_CHECK="~USER_NS ~PID_NS ~NET_NS ~SECCOMP_FILTER"
QA_PREBUILT="opt/zoom/*"

src_prepare() {
	default

	# The tarball doesn't contain an icon, so extract it from the binary
	bbe -s -b '/<svg width="32" height="32"/:/<\x2fsvg>\n/' -e 'J 1;D' zoom \
		>videoconference-zoom.svg && [[ -s videoconference-zoom.svg ]] \
		|| die "Extraction of icon failed"

	if ! use pulseaudio; then
		# For some strange reason, zoom cannot use any ALSA sound devices if
		# it finds libpulse. This causes breakage if media-sound/apulse[sdk]
		# is installed. So, force zoom to ignore libpulse.
		bbe -e 's/libpulse.so/IgNoRePuLsE/' zoom >zoom.tmp || die
		mv zoom.tmp zoom || die
	fi
}

src_install() {
	insinto /opt/zoom
	exeinto /opt/zoom
	doins -r calendar cef diagnostic email imjs js json ringtone sip \
		timezones translations
	doins *.pcm Embedded.properties version.txt
	doexe zoom zopen ZoomLauncher ZoomWebviewHost *.sh \
		aomhost libaomagent.so libcml.so libdvf.so libmkldnn.so libquazip.so \
		libavcodec.so* libavformat.so* libavutil.so* libswresample.so*
	fperms a+x /opt/zoom/cef/chrome_sandbox
	dosym -r {"/usr/$(get_libdir)",/opt/zoom}/libmpg123.so
	dosym -r "/usr/$(get_libdir)/libfdk-aac.so.2" /opt/zoom/libfdkaac2.so

	if use opencl; then
		doexe libclDNN64.so
		dosym -r {"/usr/$(get_libdir)",/opt/zoom}/libOpenCL.so.1
	fi

	if ! use wayland; then
		# Soname dependency on libwayland-client.so.0
		rm "${ED}"/opt/zoom/cef/libGLESv2.so || die
	fi

	doins -r Qt
	find Qt -type f '(' -name '*.so' -o -name '*.so.*' ')' \
		-printf '/opt/zoom/%p\0' | xargs -0 -r fperms 0755
	pipestatus || die
	(	# Remove libs and plugins with unresolved soname dependencies.
		# Why does the upstream package contain such garbage? :-(
		cd "${ED}"/opt/zoom/Qt || die
		rm -r plugins/audio plugins/egldeviceintegrations \
			plugins/platforms/libqeglfs.so plugins/platforms/libqlinuxfb.so \
			plugins/platformthemes/libqgtk3.so qml/QtQml/RemoteObjects \
			qml/QtQuick/LocalStorage qml/QtQuick/Particles.2 \
			qml/QtQuick/Scene2D qml/QtQuick/Scene3D \
			qml/QtQuick/XmlListModel || die
		use wayland || rm -r lib/libQt5Wayland*.so* plugins/wayland* \
			plugins/platforms/libqwayland*.so qml/QtWayland || die
	)

	use zoom-symlink && dosym -r /opt/zoom/ZoomLauncher /usr/bin/zoom

	make_desktop_entry "${EPREFIX}/opt/zoom/ZoomLauncher %U" Zoom \
		videoconference-zoom "Network;VideoConference;" \
		"MimeType=$(printf '%s;' \
			x-scheme-handler/zoommtg \
			x-scheme-handler/zoomus \
			application/x-zoom)"
	doicon videoconference-zoom.svg
	doicon -s scalable videoconference-zoom.svg

	local DOC_CONTENTS="Some of Zoom's screen share features (e.g.
		the whiteboard) require display compositing. If you encounter
		a black window when sharing the screen, then one of the following
		actions should help:
		\\n- Enable compositing in your window manager if it is supported
		\\n- Alternatively, run the xcompmgr command (from x11-misc/xcompmgr)"
	readme.gentoo_create_doc
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_icon_cache_update
	readme.gentoo_print_elog
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}
