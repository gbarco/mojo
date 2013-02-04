use FindBin;
use lib "$FindBin::Bin/../lib";
use Mojo::Base -strict;

use Mojo::ByteStream 'b';
use Mojo::UserAgent;

use File::Temp;
use File::Copy;

my $FH = File::Temp->new();

my $fname = $FH->filename;

if($ARGV[0] eq '-') {
	close($FH);
	open($FH, '>-') || die("ERROR: Could not reopen STDOUT");
}

print $FH <<'MODULE';
package Mojo::Util::Entities;

use Mojo::Base -base;

sub new {
    my $self = shift->SUPER::new(@_);

	my $entities;

	while(my $l = <DATA>) {
		$entities->{$1} = chr hex($2) if $l =~ /^(\S+)\s+U\+(\S+)/;
		$entities->{$1} = chr(hex($2)) . chr(hex($3)) if $l =~ /^(\S+)\s+U\+(\S+)\s+U\+(\S+)/;
	}

	# Reverse entities for html_escape (without "apos")
	my $reverse = {"\x{0027}" => '#39;'};
	$reverse->{$entities->{$_}} //= $_
		for sort  { @{[$a =~ /[A-Z]/g]} <=> @{[$b =~ /[A-Z]/g]} }
		sort grep {/;/} keys %$entities;

    $self->{Forward} = $entities;
    $self->{Reverse} = $reverse;

    return $self;
}

1;

__DATA__
MODULE

 # Extract named character references from HTML5 spec
my $tx = Mojo::UserAgent->new->get(
  'http://www.w3.org/html/wg/drafts/html/master/single-page.html');
b($_->at('td > code')->text . ' ' . $_->children('td')->[1]->text)->trim->say
  for $tx->res->dom('#named-character-references-table tbody > tr')->each;

1;
