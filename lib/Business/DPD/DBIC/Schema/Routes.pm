package Business::DPD::DBIC::Schema::Routes;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("routes");
__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0, size => undef },
  "dest_country",
  { data_type => "text", is_nullable => 0, size => undef },
  "begin_postcode",
  { data_type => "text", is_nullable => 0, size => undef },
  "end_post_code",
  { data_type => "text", is_nullable => 0, size => undef },
  "service_code",
  { data_type => "text", is_nullable => 0, size => undef },
  "routing_places",
  { data_type => "text", is_nullable => 0, size => undef },
  "sending_date",
  { data_type => "text", is_nullable => 0, size => undef },
  "o_sort",
  { data_type => "text", is_nullable => 0, size => undef },
  "d_depot",
  { data_type => "text", is_nullable => 0, size => undef },
  "grouping_priority",
  { data_type => "text", is_nullable => 0, size => undef },
  "d_sort",
  { data_type => "text", is_nullable => 0, size => undef },
  "barcode_id",
  { data_type => "text", is_nullable => 0, size => undef },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2008-10-15 12:07:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:y04XPOeEwLOADJygkc5avQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
