################################################################################
#
# openbox
#
################################################################################

OPENBOX_VERSION = 3.6.1
OPENBOX_SOURCE = openbox-$(OPENBOX_VERSION).tar.gz
OPENBOX_SITE = http://openbox.org/dist/openbox
OPENBOX_LICENSE_FILES = COPYING
OPENBOX_INSTALL_STAGING = YES

$(eval $(autotools-package))
