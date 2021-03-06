# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=3
USE_RUBY="ruby18 ruby19 jruby"

RUBY_FAKEGEM_TASK_DOC="docs"
RUBY_FAKEGEM_DOCDIR="doc"
RUBY_FAKEGEM_EXTRADOC=""

inherit ruby-fakegem

DESCRIPTION="cURL binding for Ruby"
HOMEPAGE="http://curb.rubyforge.org/"
LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~ia64 ~x86"
IUSE=""

DEPEND="net-misc/curl"

ruby_add_bdepend "
	test? (	virtual/ruby-test-unit )"

