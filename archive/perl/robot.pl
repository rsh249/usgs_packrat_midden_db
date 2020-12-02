#!/usr/bin/perl
###USGS PACKRAT MIDDEN DATABASE
##Automated retrieval of all site data, including localities, references, taxa, and dating information.
use LWP::UserAgent;
use Encode;
use DBD::mysql;
use DBI;
use Cwd;

PBC_INCLUDE : {

	use lib '/home/kcn2/PBC/conf';
	require 'pbc_config.pl'; ### contains pac_defaults() and pac_config() CALLS pac_defaults()

}

mysql_ext_connect();
	


pac_defaults();

pac_init();
get_args();



my $filename = 'sites.html';
open(my $fh, '<:encoding(UTF-8)', $filename)
	or die "Could not open file '$filename' $!";

@line = ();
$zzz = 0;
while (my $row = <$fh>) {
	chomp $row;
	#print "$row\n";
	$line[$zzz] = $row;
	$zzz++;
}

$site_num = -1; 
initialize();

for (my $x = 0; $x<=$#line; $x++){
	$line[$x] =~ s/&nbsp;//g;
	$line[$x] =~ s/\'//g;
	if($line[$x] =~ m/\<TABLE/g){
		$site_num++; ##Reset all site specific values here?
		#print "$site_num:\n";
		$go_on = 0;

	#need to call a function to reset all site details here, and maybe one at the start to update sql with site details.
	}
	
	if($line[$x] =~ m/Number of taxa/g){
		my @holdit = split(/:/, $line[$x]);
		my @trimit = split(/\</, $holdit[1]);
		#print "$trimit[0]\n";
		$taxon_number[$site_num] = $trimit[0];
		if($taxon_number[$site_num] > 0){
			my @nextline = split(/\"/, $line[$x+1]);
			$tax_url[$site_num] = $nextline[1];
		#	print "Taxa: $taxon_number[$site_num]: $tax_url[$site_num]\n";
		#	get_tax_page($tax_url[$site_num]);
			$go_on = 1;
		} else {$go_on = 0;}

	} 
	if($line[$x] =~ m/Number of C14 ages/g){
		my @holdit = split(/:/, $line[$x]);
		my @trimit = split(/\</, $holdit[1]);
		#print "$trimit[0]\n";
		$age_number[$site_num] = $trimit[0];
		if($age_number[$site_num] > 0){
			my @nextline = split(/\"/, $line[$x+1]);
			$age_url[$site_num] = $nextline[1];
		#	print "Ages: $age_number[$site_num]: $age_url[$site_num]\n";
		#	get_age_page($age_url[$site_num]);
		}
	}
	if($line[$x]=~ m/SITE/g){
		#Site name
		#locality
		$line[$x] =~ s/<.+?>/,/g;
		my @li = split(/[\:|,]/, $line[$x]);
		s{^\s+|\s+$}{}g foreach @li;
		$site_name[$site_num] = $li[8];
		$site_locality[$site_num]  = $li[11];
		$site_sample[$site_num] = $li[5]; ##UNIQUE TERM
		#for(my $i=0; $i<=$#li; $i++){print "$i: $li[$i]\n";}
		#print "Sample: $site_sample[$site_num]; Name: $site_name[$site_num]; Locality: $site_locality[$site_num]\n";
	}

	if($line[$x] =~ m/STATE or PROVINCE/g){
		#state (abbrev)
		#County
		#Country
		$line[$x] =~ s/<.+?>/,/g;
		my @li = split(/[\:|,]/, $line[$x]);
		s{^\s+|\s+$}{}g foreach @li;
		$site_state[$site_num] = $li[3];
		$site_county[$site_num]  = $li[6];
		$site_country[$site_num] = $li[9];
		#print "STATE: $site_state[$site_num]; County: $site_county[$site_num]; Country: $site_country[$site_num]\n";
	
	}
	if($line[$x]=~m/LONGITUDE \(DD\)/g){
		#decimal lat
		#decimal lon
		$line[$x] =~ s/<.+?>/,/g;
		my @li = split(/[\:|,]/, $line[$x]);
		s{^\s+|\s+$}{}g foreach @li;
		$site_lon[$site_num] = $li[3];
		$site_lat[$site_num] = $li[6];
		#print "LONGITUDE: $site_lon[$site_num], LATITUDE: $site_lat[$site_num]\n";
	}

	if($line[$x]=~m/ELEVATION:/g){
		$line[$x] =~ s/<.+?>/,/g;
		my @li = split(/[\:|,]/, $line[$x]);
		s{^\s+|\s+$}{}g foreach @li;
		$site_elev[$site_num] = $li[3];
		#print "ELEV: $site_elev[$site_num]\n";
	}

	if($line[$x]=~m/PRIMARY REFERENCE:/g){
		my @pr_line = split(/\:\<\/B\> /, $line[$x]);
		my $pr_string = $pr_line[1]; #Starts with Author,year #tag to link.
		$pr_string =~ s/\(//g;
		my @pr_arr = split(/[\>,\<]+/, $pr_string);
		s{^\s+|\s+$}{}g foreach @pr_arr; # remove all leading and trailing white space
		$primary_ref[$site_num] = "$pr_arr[0], $pr_arr[1]";
		$primary_refid[$site_num] = "$pr_arr[3]";
		if($primary_refid[$site_num] eq "/A") {$primary_refid[$site_num] = '';}
		#print "PRIMARY REFERENCE: $primary_ref[$site_num]; $primary_refid[$site_num]\n";
	}

	if($line[$x]=~m/ADDITIONAL REFERENCES:/g){
		my @ad_line = split(/\:\<\/B\> /, $line[$x]);
		my $ad_string = $ad_line[1]; 
		my @ad_arr = split(/[\>|\<]+/, $ad_string);
		my $add_str = ''; my $co=0;
		s{^\s+|\s+$}{}g foreach @ad_arr; # remove all leading and trailing white space
		for (my $i = 0; $i<=$#ad_arr; $i++){
			if($ad_arr[$i] =~ m/m/g && $ad_arr[$i] =~ m/^(\d+)/){
				if($co >0){
					$add_str = $add_str . ", " .  $ad_arr[$i];
				} else {$add_str = $ad_arr[$i];}
				$co++;
			}

		}
		$additional_refs[$site_num] = $add_str;
		#print "ADDITIONAL REFERENCE: $additional_refs[$site_num]\n";

	}

}

for(my $i = 0; $i<= $#site_name; $i++){
	if($taxon_number[$i] > 5){
		print "$i:\nSample: $site_sample[$i]; Name: $site_name[$i]; Locality: $site_locality[$i]\n";
		print "STATE: $site_state[$i]; County: $site_county[$i]; Country: $site_country[$i]\n";
		print "LONGITUDE: $site_lon[$i], LATITUDE: $site_lat[$i]\n";	
		print "ELEV: $site_elev[$i]\n";
		print "PRIMARY REFERENCE: $primary_ref[$i]; $primary_refid[$i]\n";
		print "ADDITIONAL REFERENCE: $additional_refs[$i]\n";
		print "Ages: $age_number[$i]: $age_url[$i]\n";
		#get_age_page($age_url[$i]);
		print "Taxa: $taxon_number[$i]: $tax_url[$i]\n";
		#get_tax_page($tax_url[$i]);

		update_sql($i);
		#write_file($i); # write new function to write to one or more text files # then remove references to cloud SQL infrastructure		
		
	} #else {print "$i: $taxon_number[$i]\n";}
}

mysql_ext_disconnect();

exit;

sub write_file($$){
  my ($row) = @_;

	#write to midden_sites.tab
	
	#project, plot_name, major_geo, country, pol1, pol2, locality_desc, lat, lon, elev_mean, reference_str
	
	my $project = "USGS_Packrat_midden_database";
	my $major_geo = "North America";
#	my $mystr = "insert into div_ext.midden_sites SET plot_name = '$site_sample[$row]', project = '$project', major_geo = '$major_geo', country = '$site_country[$row]', pol1 = '$site_state[$row]', pol2 = '$site_county[$row]', locality_desc = '$site_name[$row]: $site_locality[$row]', lat = '$site_lat[$row]', lon = '$site_lon[$row]', elev_mean = '$site_elev[$row]', reference_str = '$primary_ref[$row], $primary_refid[$row], $additional_refs[$row]', taxa_url = '$tax_url[$row]', age_url = '$age_url[$row]';";
	my $header = "site_sample\tproject\tmajor_geo\tsite_country\tsite_state\tsite_county\tsite_name\tsite_locality\tsite_lat\tsite_lon\tsite_elev\tprimary_ref\tprimary_refid\tadditional_refs\ttax_url\tage_url\n";
	my $mystr = "$site_sample[$row]\t$project\t$major_geo\t$site_country[$row]\t$site_state[$row]\t$site_county[$row]\t$site_name[$row]\t$site_locality[$row]\t$site_lat[$row]\t$site_lon[$row]\t$site_elev[$row]\t$primary_ref[$row]\t$primary_refid[$row]\t$additional_refs[$row]\t$tax_url[$row]\t$age_url[$row]\n";



}

sub update_sql($$){
	my ($row) = @_;

	#insert into midden_sites
	#project, plot_name, major_geo, country, pol1, pol2, locality_desc, lat, lon, elev_mean, reference_str
	my $project = "USGS_Packrat_midden_database";
	my $major_geo = "North America";
	my $mystr = "insert into div_ext.midden_sites SET plot_name = '$site_sample[$row]', project = '$project', major_geo = '$major_geo', country = '$site_country[$row]', pol1 = '$site_state[$row]', pol2 = '$site_county[$row]', locality_desc = '$site_name[$row]: $site_locality[$row]', lat = '$site_lat[$row]', lon = '$site_lon[$row]', elev_mean = '$site_elev[$row]', reference_str = '$primary_ref[$row], $primary_refid[$row], $additional_refs[$row]', taxa_url = '$tax_url[$row]', age_url = '$age_url[$row]';";


	print "$mystr\n";
	my $return = mysql_ext_execute($mystr); #where $ is the query to execute... 

	#get last id
	my $site_id = mysql_ext_last_insert();
	print "$site_id\n";
	if ($site_id < 20000) {
		print "BAD SITE!!! $mystr\n"; die;
 	} else {
	#	die;
		#insert taxon occurrence
		#genus, species, material, original_count, abundance code, site_id
#		$site_taxa = ();
#		$site_material = ();
#		$site_count = ();
#		$site_abundance = ();
	
		get_tax_page($tax_url[$row]);
		for (my $i = 0; $i<=$#site_taxa; $i++){
			my $original = $site_taxa[$i];
			$site_taxa[$i] =~ s/-type//g;
			if ($site_taxa[$i] =~ m/aceae/g or $site_taxa =~ m/tae/g){
				my $mytaxstr = "insert into div_ext.midden_sites_obs set site_id = '$site_id', plot_name = '$site_sample[$row]', genus = '', species = '', material_obs = '$site_material[$i]', original_count = '$site_count[$i]', abundance_code = '$site_abundance', taxon_str = '$original';";
				my $tax_return = mysql_ext_execute($mytaxstr);
			} else {
				my @taxstr = split(/ /, $site_taxa[$i]);
				my $this_genus = $taxstr[0];
				my $this_species = $taxstr[1];
				if ($this_species =~ m/cf/g) {$this_species=$taxstr[2];}
				if ($this_genus =~ m/cf/g) {$this_genus=$taxstr[1];}
				my $mytaxstr = "insert into div_ext.midden_sites_obs set site_id = '$site_id', plot_name = '$site_sample[$row]', genus = '$this_genus', species = '$this_species', material_obs = '$site_material[$i]', original_count = '$site_count[$i]', abundance_code = '$site_abundance', taxon_str = '$original';";
				my $tax_return = mysql_ext_execute($mytaxstr);
			}
	
		}
		#insert ages
		#site_id, lab_id, age, stdev, material, comments
		get_age_page($age_url[$row]);
#		$site_labid = ();
#		$site_age = ();
#		$site_stdev = ();
#		$site_material_used = ();
#		$site_date_comments = ();
		for (my $i = 0; $i<=$#site_labid; $i++){
			my $myagestr = "insert into div_ext.midden_age set site_id = '$site_id', lab_id = '$site_labid[$i]', age = '$site_age[$i]', age_stdev = '$site_stdev[$i]', material_sampled = '$site_material_used[$i]', comments = '$site_date_comments';";
			my $age_return = mysql_ext_execute($myagestr);
	
	
		}
	}	
}	
	
sub get_tax_page($$){

	my ($tax_url) = @_;
	my $url_get = "http://geochange.er.usgs.gov" . $tax_url; #$link_url is $age_url  
	my $page = get_content($url_get);
#	print "$url_get\n";
	#BY LINE: If line matches "<TR><TD>" then contains data of the form:
		#taxon, Type of material, Orig. count, Abundance code
			#else ignore all other lines...
	@site_taxa = (); $#site_taxa = -1;
	@site_material = (); $#site_material = -1;
	@site_count = (); $#site_count = -1;
	@site_abundance = (); $#site_abundance = -1;

	my $nnn = 0;
	my @lines = split(/\n/, $page);
	for (my $i=0; $i<=$#lines; $i++){
			#print "$lines[$i]\n";
		if ($lines[$i] =~ m/TD/g){
			
			#print "$lines[$i]\n";
			#$lines[$x] =~ s/&nbsp//g;
			$lines[$i] =~ s/,//g;			
			$lines[$i] =~ s/<.+?>/,/g;
			my @li = split(/[\:|,]/, $lines[$i]);
			s{^\s+|\s+$}{}g foreach @li;
			$site_taxa[$nnn] = $li[2];
			$site_material[$nnn] = $li[4]; 
			$site_count[$nnn] = $li[6];
			$site_abundance[$nnn] = $li[8];
			print "Taxon: $site_taxa[$nnn], Type of Material: $site_material[$nnn], Orig. count: $site_count[$nnn], Abundance Code: $site_abundance[$nnn]\n";
			$nnn++;
		} else {}
	}

}

sub get_age_page($$){

	my ($age_url) = @_;
	my $url_get = "http://geochange.er.usgs.gov" . $age_url; #$link_url is $age_url  
	my $page = get_content($url_get);

	#BY LINE: If line matches "<TR><TD>" then contains data of the form:
		#taxon, Type of material, Orig. count, Abundance code
			#else ignore all other lines...
	@site_labid = (); $#site_labid = -1;
	@site_age = (); $#site_age = -1;
	@site_stdev = (); $#site_stdev = -1;
	@site_material_used = (); $#site_material_used = -1;
	@site_date_comments = (); $#site_date_comments = -1;

	my $nnn = 0;
	my @lines = split(/\n/, $page);
	for (my $i=0; $i<=$#lines; $i++){
		#print "$lines[$i]\n";
		if ($lines[$i] =~ m/\<TD/g){
			#print "$lines[$i]\n";
			#$lines[$x] =~ s/&nbsp//g;
			$lines[$i] =~ s/,//g;			
			$lines[$i] =~ s/<.+?>/,/g;
			my @li = split(/[\:|,]/, $lines[$i]);
			s{^\s+|\s+$}{}g foreach @li;
			$site_labid[$nnn] = $li[2];
			$site_age[$nnn] = $li[4]; 
			$site_stdev[$nnn] = $li[6];
			$site_material_used[$nnn] = $li[8];
			$site_date_comments[$nnn] = $li[10];
			print "$site_labid[$nnn], $site_age[$nnn], $site_stdev[$nnn], $site_material_used[$nnn], $site_date_comments[$nnn]\n";
			$nnn++;
		} else {}
	}
}


sub get_content($$) 
{
	my($url_get) = @_;
	my $to = 18000;
	print "\n$url_get\n";
	my $content = '';
	my $ua = new LWP::UserAgent;
	$ua->timeout($to);
	my $request = new HTTP::Request('GET', $url_get);
	my $response = $ua->request($request);
	my $content = $response->content;
	$content =~ s/\"//g; #remove all quotes
	$content =~ s/\;//g;
	$content =~ s/\'//g;
	$content =~ s/\t//g;
	#print "$content\n";
	my @lines = split(/\n/, $content);
	my $linecount = scalar(@lines);

	#print "STATUS: $linecount\n$content\n";
	return $content;
}
 
sub initialize(){
	@taxon_number = ();
	@tax_url = ();
	@age_number = ();
	@age_url = ();
	@site_elev = ();
	@additional_refs = ();
	@primary_refid = ();
	@primary_ref = ();
	@site_lon = ();
	@site_lat = ();	
	@site_name = ();
	@site_locality = ();
	@site_sample = ();
	@site_state = ();
	@site_county = ();
	@site_country = ();
}

##STRUCTURE OF TAXON LIST PAGES

#<HTML><HEAD><TITLE>Packrat Midden Database Query Results</TITLE></HEAD><BODY BGCOLOR="#FFFFFF"><H2>Packrat Midden Database Query Results</H2>
#<B>SAMPLE: TSE1C</B><BR>
#<TABLE BORDER="1" WIDTH="100%" CELLPADDING="4">
#<TR BGCOLOR="CCCCCC"><TH>TAXA</TH><TH>TYPE OF MATERIAL</TH><TH>ORIG.COUNT</TH><TH>ABUNDANCE CODE</TH></TR>
#<TR><TD>Abies concolor</TD><TD>&nbsp;</TD><TD>4.6</TD><TD>1</TD></TR>
#<TR><TD>Amelanchier utahensis</TD><TD>&nbsp;</TD><TD>3.5</TD><TD>1</TD></TR>
#<TR><TD>Argemone sp.</TD><TD>&nbsp;</TD><TD>24</TD><TD>2</TD></TR>
#<TR><TD>Chamaebatiaria millefolium</TD><TD>&nbsp;</TD><TD>R</TD><TD>1</TD></TR>
#<TR><TD>Cirsium sp.</TD><TD>&nbsp;</TD><TD>2.3</TD><TD>1</TD></TR>
#<TR><TD>Compositae</TD><TD>involucres</TD><TD>R</TD><TD>1</TD></TR>
#<TR><TD>Echinocereus sp.</TD><TD>&nbsp;</TD><TD>3.5</TD><TD>1</TD></TR>
#<TR><TD>Forsellesia nevadensis</TD><TD>&nbsp;</TD><TD>55</TD><TD>2</TD></TR>
#<TR><TD>Fraxinus anomala</TD><TD>&nbsp;</TD><TD>13</TD><TD>2</TD></TR>
#<TR><TD>Juniperus cf. osteosperma</TD><TD>&nbsp;</TD><TD>299</TD><TD>2</TD></TR>
#<TR><TD>Lepidium sp.</TD><TD>&nbsp;</TD><TD>4.6</TD><TD>1</TD></TR>
#<TR><TD>Linum sp.</TD><TD>&nbsp;</TD><TD>R</TD><TD>1</TD></TR>
#<TR><TD>Lithospermum sp.</TD><TD>&nbsp;</TD><TD>4.6</TD><TD>1</TD></TR>
#<TR><TD>Opuntia sp.</TD><TD>spines</TD><TD>143</TD><TD>2</TD></TR>
#<TR><TD>Ostrya knowltonii</TD><TD>&nbsp;</TD><TD>16</TD><TD>2</TD></TR>
#<TR><TD>Pinus flexilis</TD><TD>&nbsp;</TD><TD>2.3</TD><TD>1</TD></TR>
#<TR><TD>Pseudotsuga menziesii</TD><TD>&nbsp;</TD><TD>36</TD><TD>2</TD></TR>
#<TR><TD>Ribes sp.</TD><TD>&nbsp;</TD><TD>17</TD><TD>2</TD></TR>
#<TR><TD>Rosa cf. stellata</TD><TD>&nbsp;</TD><TD>143</TD><TD>2</TD></TR>
#<TR><TD>Symphoricarpos sp.</TD><TD>&nbsp;</TD><TD>13</TD><TD>2</TD></TR>
#</TABLE>
#<P><B>EXPLANATION OF ABUNDANCE CODE:</B> 0 = absent; 1 = present but rare; 2 = present and abundant<BR>
#<HR>
#This web page produced by a CGI script.<BR>
#For questions or comments, contact rschumann@usgs.gov<BR>
#</BODY></HTML>



##STRUCTURE OF DATE PAGES

#<HTML><HEAD><TITLE>Packrat Midden Database Query Results</TITLE></HEAD><BODY BGCOLOR="#FFFFFF"><H2>Packrat Midden Database Query Results</H2>
#<B>SAMPLE: TSE1C</B><BR>
#<TABLE BORDER="1" WIDTH="100%" CELLPADDING="4">
#<TR BGCOLOR="CCCCCC"><TH>LAB ID</TH><TH>C14 AGE</TH><TH>STD DEV</TH><TH>MATERIAL DATED</TH><TH>COMMENTS</TH></TR>
#<TR><TD>A-1794</TD><TD>12600</TD><TD>540</TD><TD>Pseudotsuga menziesii needles</TD><TD>&nbsp;</TD></TR>
#<TR><TD>A-1806</TD><TD>13340</TD><TD>150</TD><TD>Neotoma pellets</TD><TD>&nbsp;</TD></TR>
#</TABLE>
#<HR>
#This web page produced by a CGI script.<BR>
#For questions or comments, contact rschumann@usgs.gov<BR>
#</BODY></HTML>




