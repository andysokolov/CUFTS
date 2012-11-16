## CUFTS::Config
##
## Copyright Todd Holbrook - Simon Fraser University (2003)
##
## This file is part of CUFTS.
##
## CUFTS is free software; you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free
## Software Foundation; either version 2 of the License, or (at your option)
## any later version.
##
## CUFTS is distributed in the hope that it will be useful, but WITHOUT ANY
## WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
## FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
## details.
##
## You should have received a copy of the GNU General Public License along
## with CUFTS; if not, write to the Free Software Foundation, Inc., 59
## Temple Place, Suite 330, Boston, MA 02111-1307 USA

package CUFTS::Config;

use Exception::Class::DBI;
use CUFTS::BasicConfig;

use strict;

use vars qw(
    $CUFTS_DB_ATTR
    $CUFTS_DB_STRING
    @CUFTS_DB_CONNECT

    $CUFTS_LOG_DIR
    $CUFTS_TITLE_LIST_UPLOAD_DIR

    $CUFTS_MODULE_PREFIX

    $CUFTS_MAIL_REPLY_TO

    $CUFTS_REQUEST_LOG

    $CUFTS_TEMPLATE_DIR

    $CJDB_BASE_DIR
    $CJDB_URL

    $CJDB_TEMPLATE_DIR
    $CJDB_SITE_TEMPLATE_DIR

    $CJDB_CSS_DIR
    $CJDB_SITE_CSS_DIR

    $CJDB_SITE_DATA_DIR

    $CRDB_BASE_DIR
    $CRDB_URL

    $CRDB_TEMPLATE_DIR
    $CRDB_SITE_TEMPLATE_DIR

    $CRDB_CSS_DIR
    $CRDB_SITE_CSS_DIR

    $CUFTS_RESOLVER_DIR
    $CUFTS_RESOLVER_SITE_DIR
    $CUFTS_RESOLVER_URL
    
    @CUFTS_JOURNAL_FT_FIELDS
);

$CUFTS_DB_STRING = "dbi:Pg:dbname=${CUFTS_DB};host=localhost;port=5432";
$CUFTS_DB_ATTR   = {
    'PrintError'  => 0,
    'RaiseError'  => 0,
    'HandleError' => Exception::Class::DBI->handler(),
    'AutoCommit'  => 0
};

@CUFTS_DB_CONNECT = ( $CUFTS_DB_STRING, $CUFTS_USER, $CUFTS_PASSWORD, $CUFTS_DB_ATTR );

$CUFTS_LOG_DIR               = "${CUFTS_BASE_DIR}/logs";
$CUFTS_TITLE_LIST_UPLOAD_DIR = "${CUFTS_BASE_DIR}/uploads";

$CUFTS_MODULE_PREFIX = 'CUFTS::Resources::';

$CUFTS_MAIL_REPLY_TO = $CUFTS_MAIL_FROM;

$CUFTS_REQUEST_LOG = "${CUFTS_LOG_DIR}/requests_log";

$CUFTS_TEMPLATE_DIR = "${CUFTS_BASE_DIR}/templates";

$CJDB_BASE_DIR = "${CUFTS_BASE_DIR}/CJDB";
$CJDB_URL      = 'http://localhost:3000/';

$CJDB_TEMPLATE_DIR      = "${CJDB_BASE_DIR}/root";
$CJDB_SITE_TEMPLATE_DIR = "${CJDB_TEMPLATE_DIR}/sites";

$CJDB_CSS_DIR      = "${CJDB_BASE_DIR}/root/static/css";
$CJDB_SITE_CSS_DIR = $CJDB_SITE_TEMPLATE_DIR;

$CJDB_SITE_DATA_DIR = "${CUFTS_BASE_DIR}/data/sites";

$CRDB_BASE_DIR = "${CUFTS_BASE_DIR}/CRDB";
$CRDB_URL      = 'http://localhost:3000/';

$CRDB_TEMPLATE_DIR      = "${CRDB_BASE_DIR}/root";
$CRDB_SITE_TEMPLATE_DIR = "${CRDB_TEMPLATE_DIR}/sites";

$CRDB_CSS_DIR      = "${CRDB_BASE_DIR}/root/static/css";
$CRDB_SITE_CSS_DIR = $CRDB_SITE_TEMPLATE_DIR;

$CUFTS_RESOLVER_DIR      = "${CUFTS_BASE_DIR}/Resolver";
$CUFTS_RESOLVER_SITE_DIR = "${CUFTS_RESOLVER_DIR}/root/sites";
$CUFTS_RESOLVER_URL      = 'http://localhost:3000/CUFTS/Resolver';

@CUFTS_JOURNAL_FT_FIELDS = qw(
    ft_start_date
    ft_end_date
    vol_ft_start
    vol_ft_end
    iss_ft_start
    iss_ft_end
    embargo_months
    embargo_days
);

1;
