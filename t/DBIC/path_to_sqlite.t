use 5.010;
use strict;
use warnings;

use Test::More tests => 2;
use Test::NoWarnings;

use Business::DPD::DBIC;

like(Business::DPD::DBIC->path_to_sqlite,qr{Business/DPD/dpd.sqlite$},'path_to_sqlite');


