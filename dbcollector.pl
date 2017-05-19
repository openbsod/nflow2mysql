#!/usr/bin/perl
use strict;
use IO::Socket::INET;
use DBI;
use POSIX;
use feature qw { switch };
# Initialisation
#Variables
$| = 1;
my ($log_level) = 10;
#Hash
my (%templates_data,%templates_format);
#Init socket
my ($socket,$received_data,$peer_address,$peer_port, $version);
$socket = new IO::Socket::INET (
	LocalPort => '9996',
	Proto => 'udp',
) or die "ERROR in Socket Creation : $!\n";
#Connect to DB
my ($dbname) = 'flow';
my ($dbhost) = '127.0.0.1';
my ($dbusr) = 'netflow';
my ($dbpass) = 'netflow';
my ($db) = DBI->connect("DBI:mysql:$dbname;host=$dbhost", "$dbusr", "$dbpass") || die "Could not connect to database: $DBI::errstr";
#Reading templates
my ($temp) = $db->prepare('SELECT t.device_id,
                                  d.device_header AS device_header,
                                  t.template_id,
                                  t.template_header,
                                  t.template_data,
                                  t.template_format
                           FROM templates t
                           INNER JOIN devices d ON t.device_id = d.device_id');
$temp->execute;
while (my $result = $temp->fetchrow_hashref) {
	my (@template_data) = split (",", $templates_data{"$result->{device_header}"});
	my (@template_format) = split (",", $templates_format{"$result->{device_header}"});
	$template_data[0] = $result->{device_id};
	$template_format[0] = $result->{device_id};
	$template_data["$result->{template_id}"] = $result->{template_data};
	$template_format["$result->{template_id}"] = $result->{template_format};
	$templates_data{"$result->{device_header}"} = join (",", @template_data);
	$templates_format{"$result->{device_header}"} = join (",", @template_format);
}
#Reading socket
while(1) {
my ($recieved_data);
while(!$recieved_data) {
	$socket->recv($recieved_data,4096);
	$peer_address = unpack("N", $socket->peeraddr());
}
	$version = unpack("n", substr($recieved_data,0,2));
	given ( $version ) {
		when ( 5 ) { fv5($recieved_data,$peer_address); }
		when ( 9 ) { fv9($recieved_data,$peer_address); }
	}
}
#Closing Socket
$socket->close();
$db->disconnect();
sub fv5 {
	my $sth = $db->prepare("SELECT COUNT(*) FROM devices WHERE `device_header`=$_[1]");
	$sth->execute;
	if ($sth->fetchrow == 0) {
		$db->do("INSERT INTO devices (`device_header`) VALUES($_[1])");
	}
	my $sth = $db->prepare("SELECT `device_id` FROM `devices` WHERE `device_header`=$_[1]");
	$sth->execute;
	my $result = $sth->fetchrow_hashref;
	my $dev_id = $result->{device_id};
	my (@header) = unpack("nnN4NNNHHH2", substr($_[0],0,24));
	my @records = ();
	my ($i, $fmt, @substr);
	my $data = "INSERT INTO `v5` VALUES\n";
	for ($i=0; substr($_[0], 24+48*$i, 48); $i++) {
		@substr = unpack("N3n2N4n2C4n2C2n", substr($_[0], 24+48*$i, 48));
		$records[$i] = "('0','$dev_id','$header[3]','$header[2]','" . join("','", @substr) . "')";
		$fmt = "%08x0100 %08x%08x %08x %08x %08x %02x %02x %08x %08x %s %s %04x %04x %02x %02x %02x %02x %04x %04x %02x %02x %02x\n";
		flog (5,0, sprintf ("$fmt\n", $_[1],$header[3], $header[2], @substr));
	}
	$data .= join(",\n", @records);
#	print "$data\n";
	$db->do("$data");
}
sub fv9 {
	flog (10,0, sprintf ("Got a data from %08x ", $_[1]));
	my (@header) = unpack("n2N4", substr($_[0],0,20));
	my ($marker) = 20;
	my (@template_id);
	my ($i);
	for ($i=0; $i < $header[1]; $i++) {
		@template_id = unpack("n2", substr($_[0],$marker,4));
		if ($template_id[0] == 0) {
			$i += &fv9_templates(substr($_[0], $marker+4, $template_id[1]-4),$_[1], $template_id[1]);
		} else {
			$i += &fv9_records(substr($_[0], $marker+4, $template_id[1]-4), $_[1], $template_id[0], $template_id[1], $header[3], $header[2]);
		}
		$marker += $template_id[1];
	}
	flog (10,0, "$marker bytes in ".($i+1)." records processed\n");
};
sub fv9_templates {
	my (@template_id, @template_format, @templates_id, @template_data);
	my ($marker, $field_count) = 0;
	my ($i,$j) = -1;
	if (exists($templates_data{"$_[1]"})) {
		@template_data = split(",", $templates_data{"$_[1]"});
		@template_format = split(",", $templates_format{"$_[1]"});
	} else {
		@template_data;
		@template_format;
	}
	my ($count) = $_[2];
	while ($count>4) {
		@templates_id = unpack("n2", substr($_[0],$marker,4));
		if (!exists($template_data[$templates_id[0]])) {
		$template_data[$templates_id[0]] = unpack("H".($templates_id[1]*8+8), substr($_[0],$marker,($templates_id[1]*4+4)));
		my ($template, $template_len) = "";
		$field_count = hex(substr($template_data[$templates_id[0]],4,4));
		my @table_snap = ("CREATE TABLE IF NOT EXISTS `$_[1]$templates_id[0]` (`device_id` INT UNSIGNED NOT NULL, `template_id` INT UNSIGNED NOT NULL, `datetime` INT UNSIGNED , `uptime` INT UNSIGNED");
		for ($j=1; $j<=$field_count; $j++) {
		my $l = hex(substr($template_data[$templates_id[0]],$j*8+4,4));
		given ($l) {
#			when (1) {	$template .= "C";
#					push (@table_snap, ", `" . hex(substr($template_data[$templates_id[0]],$j*8,4)) . "` TINYINT UNSIGNED"); }
#			when (2) {	$template .= "n";
#					push (@table_snap, ", `" . hex(substr($template_data[$templates_id[0]],$j*8,4)) . "` SMALLINT UNSIGNED"); }
#			when (3) { $template .= "H6";
#					push (@table_snap, ", `" . hex(substr($template_data[$templates_id[0]],$j*8,4)) . "` MEDIUMINT UNSIGNED"); }
#			when (4) { $template .= "N";
#					push (@table_snap, ", `" . hex(substr($template_data[$templates_id[0]],$j*8,4)) . "` INT UNSIGNED"); }
#			when (8) { $template .= "H16";
#					push (@table_snap, ", `" . hex(substr($template_data[$templates_id[0]],$j*8,4)) . "` BIGINT UNSIGNED"); }
			default { $template .= "H".$l*2;
					push (@table_snap, ", `" . hex(substr($template_data[$templates_id[0]],$j*8,4)) . "` VARCHAR(",$l,")"); }
		}
			$template_len += $l;
		}
		push (@table_snap, ") ENGINE=InnoDB");
		$db->do("@table_snap");
		$template_format[$templates_id[0]] = sprintf "%04x$template", $template_len;
		my $sth = $db->prepare("SELECT COUNT(*) FROM devices WHERE `device_header`=$_[1]");
		$sth->execute;
		if ($sth->fetchrow == 0) {
			$db->do("INSERT INTO devices (`device_header`) VALUES($_[1])");
		}
		my $sth = $db->prepare("SELECT `device_id`, `device_header`, `device_description`, `device_data` FROM `devices` WHERE `device_header`=$_[1]");
		$sth->execute;
		my $result = $sth->fetchrow_hashref;
		my $dev_id = $result->{device_id};
		$template_data[0] = $dev_id;
		$template_format[0] = $dev_id;
		$db->do("INSERT INTO templates (`device_id`,
                                                `template_id`,
                                                `template_header`,
                                                `template_data`,
                                                `template_format`)
                         VALUES($dev_id,
                               $templates_id[0],
                               $_[1]$templates_id[0],
                               '$template_data[$templates_id[0]]',
                               '$template_format[$templates_id[0]]')");
		}
		$templates_data {"$_[1]"} = join (",", @template_data);
		$templates_format {"$_[1]"} = join(",", @template_format);
		$count -= $templates_id[1]*4+4;
		$marker += $templates_id[1]*4+4;
		$i++;
	}
return $i;
};
sub fv9_records {
	my ($template, $template_len, $j, $record_count);
	my (@template_format) = split(",", $templates_format{"$_[1]"});
#	print " $templates_data{\"$_[1]\"}\n";
	if (exists($templates_data{"$_[1]"}) && (exists($template_format[$_[2]]))) {
			$template_len = hex(substr($template_format[$_[2]],0,4));
			$template = substr($template_format[$_[2]],4,length($template_format[$_[2]]));
			$record_count = (length($_[0])-4)/$template_len;
			my @records = ();
			my $data = "INSERT INTO `$_[1]$_[2]` VALUES\n";
			for ($j=0; $j<$record_count; $j++) {
				my (@mass) = unpack("$template", substr($_[0],$j*$template_len,$template_len));
				$records[$j] = "($template_format[0], '$_[2]', '$_[4]', '$_[5]', 0x" . join(", 0x", @mass) . ")";
				flog (5,0, sprintf "%08x%04x %04x %04x @mass\n",$_[1],$_[2],$_[4],$_[5]);
			}
			$data .= join(",\n", @records);
			$db->do("$data");
#			print "$data\n";
	} else {
		last;
	}
return $j-1;
};

sub flog {
my (%log_msg) = ('1' => '',
		'2' => '',
		'3' => '',
		'4' => '',
		'5' => '');
if (($_[0] >= $log_level) && ($_[1] != 0)) {
	print $log_msg{$_[1]},"\n";
} elsif (($_[0] >= $log_level) && ($_[1] == 0)) {
	print $_[2];
}
};
