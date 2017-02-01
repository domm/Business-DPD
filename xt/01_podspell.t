use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;
add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');
__DATA__
RevDev
we {at} revdev.at
Business::DPD
Jozef
Kutej
Pavlovic
Klausner
barcode
MPSEXPDATA
IPPPPPPPTTTTTTTTTTTTTTSSSCCC
PPPPPPPTTTTTTTTTTTTTTSSSCCC
PPPPPPPTTTTTTTTTTTTTTSSSCCCP
Servicecode
Servicetext
TODO
mpsexpdata
pdf
PDF
checksum
