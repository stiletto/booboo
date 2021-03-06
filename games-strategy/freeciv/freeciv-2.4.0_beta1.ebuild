# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/games-strategy/freeciv/freeciv-2.3.2.ebuild,v 1.4 2012/05/21 10:10:10 phajdan.jr Exp $

EAPI=4
inherit eutils gnome2-utils games-ggz games

DESCRIPTION="multiplayer strategy game (Civilization Clone)"
HOMEPAGE="http://www.freeciv.org/"
SRC_URI="mirror://sourceforge/freeciv/${P/_/-}.tar.bz2"

LICENSE="GPL-2"
SLOT="2.4"
KEYWORDS="~amd64 ~ppc ~ppc64 ~x86"
IUSE="auth dedicated ggz gtk gtk3 ipv6 nls readline sdl +sound"

RDEPEND="readline? ( sys-libs/readline )
	sys-libs/zlib
	app-arch/bzip2
	auth? ( virtual/mysql )
	!dedicated? (
		nls? ( virtual/libintl )
		gtk? ( x11-libs/gtk+:2 )
		gtk3? ( >=x11-libs/gtk+-3.4:3 )
		sdl? (
			media-libs/libsdl[video]
			media-libs/sdl-image[png]
			media-libs/freetype
		)
		!gtk3? ( !gtk? ( !sdl? ( x11-libs/gtk+:2 ) ) )
		sound? (
			media-libs/libsdl[audio]
			media-libs/sdl-mixer
		)
		ggz? ( games-board/ggz-gtk-client )
		media-libs/libpng
	)"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	!dedicated? (
		nls? ( sys-devel/gettext )
		x11-proto/xextproto
	)"

S=${WORKDIR}/${P/_/-}

src_prepare() {
	sh ./autogen.sh

	# install the .desktop in /usr/share/applications
	# install the icons in /usr/share/pixmaps
	sed -i \
		-e 's:^.*\(desktopfiledir = \).*:\1/usr/share/applications:' \
		-e 's:^\(icon[0-9]*dir = \)$(prefix)\(.*\):\1/usr\2:' \
		-e 's:^\(icon[0-9]*dir = \)$(datadir)\(.*\):\1/usr/share\2:' \
		client/Makefile.in \
		server/Makefile.in \
		modinst/Makefile.in \
		data/Makefile.in \
		data/icons/Makefile.in \
		|| die "sed failed"
	
	# install data to freeciv-2.4 folder
	sed -i -e 's:AC_INIT(\[freeciv\(.*\):AC_INIT(\[freeciv-2.4\1:' configure.ac || die "sed failed"

	# remove civclient manpage if dedicated server
	if use dedicated ; then
		epatch "${FILESDIR}"/${P}-clean-man.patch
	fi
}

src_configure() {
	local myclient myopts

	if use dedicated ; then
		myclient="no"
	else
		use sdl && myclient="${myclient} sdl"
		use gtk && myclient="${myclient} gtk2"
		use gtk3 && myclient="${myclient} gtk3"
		[[ -z ${myclient} ]] && myclient="gtk2" # default to gtk if none specified
		myopts=$(use_with ggz ggz-client)
	fi

	egamesconf \
		--program-suffix=-2.4
		--disable-dependency-tracking \
		--localedir=/usr/share/locale \
		--with-ggzconfig=/usr/bin \
		--enable-noregistry="${GGZ_MODDIR}" \
		$(use_enable auth) \
		$(use_enable ipv6) \
		$(use_enable nls) \
		$(use_with readline) \
		$(use_enable sound sdl-mixer) \
		${myopts} \
		--enable-client="${myclient}"
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"

	if ! use dedicated ; then
		# Create and install the html manual. It can't be done for dedicated
		# servers, because the 'civmanual' tool is then not built. Also
		# delete civmanual from the GAMES_BINDIR, because it's then useless.
		# Note: to have it localized, it should be ran from _postinst, or
		# something like that, but then it's a PITA to avoid orphan files...
		./manual/freeciv-manual || die "freeciv-manual failed"
		dohtml manual*.html || die "dohtml failed"
		rm -f "${D}/${GAMES_BINDIR}"/civmanual
		use sdl && make_desktop_entry freeciv-sdl-2.4 "Freeciv 2.4 (SDL)"
		freeciv-client-2.4
	fi

	dodoc ChangeLog NEWS doc/{BUGS,CodingStyle,HACKING,HOWTOPLAY,README*,TODO}
	rm -rf "${D}$(games_get_libdir)"

	prepgamesdirs
}

pkg_preinst() {
	games_pkg_preinst
	gnome2_icon_savelist
}

pkg_postinst() {
	games_pkg_postinst
	games-ggz_update_modules
	gnome2_icon_cache_update
}

pkg_postrm() {
	games-ggz_update_modules
	gnome2_icon_cache_update
}
