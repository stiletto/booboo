# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"
inherit elisp-common eutils mercurial toolchain-funcs

DESCRIPTION="The Go Programming Language"
HOMEPAGE="http://golang.org/"
SRC_URI=""
EHG_REPO_URI="https://go.googlecode.com/hg/"
use experimental || EHG_REVISION="release"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="emacs vim-syntax experimental"

RESTRICT="test"

RDEPEND="sys-devel/gcc"
DEPEND="${RDEPEND}
	emacs? ( virtual/emacs )
	sys-devel/bison
	sys-apps/ed"

S="${WORKDIR}/hg"

ENVFILE="${WORKDIR}/50${PN}"

src_prepare() {
	GOBIN="${WORKDIR}/bin"
	mkdir -p "${GOBIN}" || die

	sed -i \
		-e "/^GOBIN=/s:=.*:=${GOBIN}:" \
		-e "/MAKEFLAGS=/s:=.*:=${MAKEOPTS}:" \
		src/make.bash || die

	sed -i \
		-e "/^GOBIN=/s:=.*:=/usr/bin:" \
		-e "/MAKEFLAGS=/s:=.*:=${MAKEOPTS}:" \
		src/Make.common || die
	
	epatch "${FILESDIR}/portageize-makefile.patch"
	
	# We don't need nasty kludges that break things
	sed -ie "s/QUOTED_//i" src/Make.*

	case ${ARCH} in
	x86)
		GOARCH="386"
		;;
	*)
		GOARCH="${ARCH}"
		;;
	esac

	case ${CHOST} in
	*-darwin*)
		GOOS="darwin"
		;;
	*)
		GOOS="linux"
		;;
	esac
#	*-nacl*)
#		GOOS="nacl"
#		;;

	cat > "${ENVFILE}" <<EOF
GOROOT="/usr/$(get_libdir)/${PN}"
GOARCH="${GOARCH}"
GOOS="${GOOS}"
EOF
	. "${ENVFILE}"

	export GOBIN GOROOT GOARCH GOOS
}

src_compile() {
	cd src
	PATH="${GOBIN}:${PATH}" GOROOT="${S}" CC="$(tc-getCC)" ./make.bash || die
	if use emacs ; then
		elisp-compile "${S}"/misc/emacs/*.el || die
	fi
}

src_test() {
	cd src
	PATH="${GOBIN}:${PATH}" GOROOT="${S}" CC="$(tc-getCC)" ./run.bash || die
}

src_install() {
	dobin "${GOBIN}"/* || die

	insinto "${GOROOT}"
	doins -r pkg || die

	insinto "${GOROOT}/src"
	doins src/Make.* || die

	if use emacs ; then
		elisp-install ${PN} "${S}"/misc/emacs/*.el* || die "elisp-install failed"
	fi

	if use vim-syntax ; then
		dodir /usr/share/vim/vimfiles/
		cp -r "${S}"/misc/vim/* "$D/usr/share/vim/vimfiles/" || die
	fi

	doenvd "${ENVFILE}" || die

	dodoc AUTHORS CONTRIBUTORS README || die
	dohtml -r doc/* || die
}

pkg_postinst() {
	elog "please don't forget to source /etc/profile"
}
