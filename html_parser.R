library(dplyr)
library(readr)
library(stringr)
read = read_delim('perl/sites2.html', delim='^') #false flag delimiter


parser = function(html) {
  # parse 18 line segments starting with the first line after <TABLE
  table_vec = vector()
  z=1
  for(i in 1:nrow(html)){
    if(str_detect(html[i,1], '<TABLE')){
      table_vec[z] = i
      z=z+1
      
    }
  }
  catch = data.frame(SAMPLE=character(),
                     SITE=character(),
                     LOCALITY=character(),
                     STATE=character(),
                     COUNTY=character(),
                     COUNTRY=character(),
                     LONGITUDE=numeric(),
                     LATITUDE=numeric(),
                     ELEVATION=numeric(),
                     PRIMARY_REF=character(),
                     PRIMARY_REF_LINK=character(),
                 #    ADDITIONAL_REF=character(),
                     ADDITIONAL_REF_LINK=character(),
                     TAXA_NUM=character(),
                     TAXA_LINK=character(),
                     AGES_NUM=character(),
                     AGES_LINK=character(),
                     stringsAsFactors = F
                     )
  line=1
  for(n in table_vec){
    #start at n+1 and parse each line
    #
    #1 <TR BGCOLOR="CCCCCC"><TD COLSPAN="2">RECORD 1 of 3209</TD></TR>
    #2 <TR><TD COLSPAN="2"><B>SAMPLE:</B> BCK10 &nbsp; <B>SITE:</B> Buffalo Creek Lookout &nbsp; <B>LOCALITY:</B> (no data) <BR>
    p2 = str_split(html[n+2,], '[<>]')
    catch[line, 'SAMPLE'] = str_replace(p2[[1]][9], '&nbsp;', '') %>% str_trim();
    catch[line, 'SITE'] = str_replace(p2[[1]][13], '&nbsp;', '') %>% str_trim();
    catch[line, 'LOCALITY'] = str_replace(p2[[1]][17], '&nbsp;', '') %>% str_trim();
    #3 <B>STATE or PROVINCE:</B> WY &nbsp; <B>COUNTY:</B> Washakie &nbsp; <B>COUNTRY:</B> USA<BR>
    p3 = str_split(html[n+3,], '[<>]')
    catch[line, 'STATE'] = str_replace(p3[[1]][5], '&nbsp;', '') %>% str_trim();
    catch[line, 'COUNTY'] = str_replace(p3[[1]][9], '&nbsp;', '') %>% str_trim();
    catch[line, 'COUNTRY'] = str_replace(p3[[1]][13], '&nbsp;', '') %>% str_trim();
    #4 <B>LONGITUDE (DMS):</B> -107 30  <B>LATITUDE (DMS):</B> 44 9  <BR>
    #5 <B>LONGITUDE (DD):</B> -107.500 <B>LATITUDE (DD): </B> 44.150 <BR>
    p5 = str_split(html[n+5,], '[<>]')
    catch[line, 'LONGITUDE'] = p5[[1]][5]
    catch[line, 'LATITUDE'] = p5[[1]][9]
    #6 <B>ELEVATION:</B> 1500 m<BR>
    p6 = str_split(html[n+6,], '[<>]')
    catch[line, 'ELEVATION'] = str_replace(p6[[1]][5], 'm', '') %>% str_trim();
    #7 <B>PRIMARY REFERENCE:</B> Lyford, 2001 (<A HREF="/midden/midref.html#228m">228m</A>)<BR>
    p7 = str_split(html[n+7,], '[<>]')
    p7_sub = str_split(p7[[1]][6], '["]')
    catch[line, 'PRIMARY_REF'] = str_replace(p7[[1]][5], "[(]", "") %>% str_trim();
    catch[line, 'PRIMARY_REF_LINK'] = p7_sub[[1]][2]
    #8 <B>ADDITIONAL REFERENCES:</B>  <A HREF="/midden/midref.html#227m"></A><BR>
    p8 = str_split(html[n+8,], '[<>]')
    p8_sub = str_split(p8[[1]][6], '["]')
   # catch[line, 'ADDITIONAL_REF'] = str_replace(p8[[1]][5], "[(]", "") %>% str_trim();
    catch[line, 'ADDITIONAL_REF_LINK'] = p8_sub[[1]][2]
    #9 </TD></TR>
    #10 <TR>
    #11 <TD WIDTH="35%">Number of taxa identified in sample: 0</TD><TD>
    p11 = str_split(html[n+11,], '[<>]')
    p11_sub = str_split(p11[[1]][3], ':')
    catch[line, 'TAXA_NUM'] = p11_sub[[1]][2]
    #12 &nbsp;</TD></TR> ### same as #15 but for taxon table
    p12 = str_split(html[n+12,], '[<>]')
    p12_sub = str_split(p12[[1]][2], '["]')
    catch[line, 'TAXA_LINK'] = p12_sub[[1]][2]
    #13 <TR>
    #14 <TD WIDTH="35%">Number of C14 ages for this sample: 1</TD><TD>
    p14 = str_split(html[n+14,], '[<>]')
    p14_sub = str_split(p14[[1]][3], ':')
    catch[line, 'AGES_NUM'] = p14_sub[[1]][2]
    #15 <A HREF="/cgi-bin/mid2q2?qtype=2&samcode=BCK10" TARGET="new">SHOW C14 AGES</A></TD></TR>
    p15 = str_split(html[n+15,], '[<>]')
    p15_sub = str_split(p15[[1]][2], '["]')
    catch[line, 'AGES_LINK'] = p15_sub[[1]][2]
    
    #advance line!
    line = line + 1
  }
  
  return(catch)
}

t = parser(read)

head(t)
tail(t)
