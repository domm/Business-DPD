package Business::DPD::DBIC::Schema::Country;

use strict;
use warnings;

use base qw(DBIx::Class);

__PACKAGE__->load_components("Core");
__PACKAGE__->table("country");
__PACKAGE__->add_columns(
  "num",
  { data_type => "integer", is_nullable => 0, size => undef },
  "alpha2",
  { data_type => "text", is_nullable => 0, size => undef },
  "alpha3",
  { data_type => "text", is_nullable => 0, size => undef },
  "languages",
  { data_type => "text", is_nullable => 0, size => undef },
  "flagpost",
  { data_type => "integer", is_nullable => 0, size => undef },
);
__PACKAGE__->set_primary_key("num");


# Created by DBIx::Class::Schema::Loader v0.04999_05 @ 2008-10-22 10:32:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:paNte3y1sQsBcyiE/OUw/Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
