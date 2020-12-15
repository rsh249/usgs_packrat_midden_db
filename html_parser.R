library(dplyr)
library(readr)
library(stringr)
read = read_delim('sites2.html', delim='^') #false flag delimiter


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
  for(n in 1:length(table_vec)){
    start = table_vec[n]
    if(n<length(table_vec)){
      end = table_vec[n+1]
    } else {
      end = length(html)
    }
    #loop from table_vec[n]:table_vec[n+1]
    for(z in start:end){
     # print(z)
      #1 <TR BGCOLOR="CCCCCC"><TD COLSPAN="2">RECORD 1 of 3209</TD></TR>
      #2 <TR><TD COLSPAN="2"><B>SAMPLE:</B> BCK10 &nbsp; <B>SITE:</B> Buffalo Creek Lookout &nbsp; <B>LOCALITY:</B> (no data) <BR>
      if(grepl('SAMPLE', html[z,])){
        p2 = str_split(html[z,], '[<>]')
        catch[line, 'SAMPLE'] = str_replace(p2[[1]][9], '&nbsp;', '') %>% str_replace("[/]", '_') %>% str_trim();
        catch[line, 'SITE'] = str_replace(p2[[1]][13], '&nbsp;', '') %>% str_trim();
        catch[line, 'LOCALITY'] = str_replace(p2[[1]][17], '&nbsp;', '') %>% str_trim();
      }
      #3 <B>STATE or PROVINCE:</B> WY &nbsp; <B>COUNTY:</B> Washakie &nbsp; <B>COUNTRY:</B> USA<BR>
      if(grepl('STATE or PROVINCE', html[z,])){
        p3 = str_split(html[z,], '[<>]')
        catch[line, 'STATE'] = str_replace(p3[[1]][5], '&nbsp;', '') %>% str_trim();
        catch[line, 'COUNTY'] = str_replace(p3[[1]][9], '&nbsp;', '') %>% str_trim();
        catch[line, 'COUNTRY'] = str_replace(p3[[1]][13], '&nbsp;', '') %>% str_trim();
      }
      #4 <B>LONGITUDE (DMS):</B> -107 30  <B>LATITUDE (DMS):</B> 44 9  <BR>
      #5 <B>LONGITUDE (DD):</B> -107.500 <B>LATITUDE (DD): </B> 44.150 <BR>
      if(grepl('LATITUDE', html[z,]) & grepl('(DD)', html[z,])){
        p5 = str_split(html[z,], '[<>]')
        catch[line, 'LONGITUDE'] = p5[[1]][5] %>% str_trim();
        catch[line, 'LATITUDE'] = p5[[1]][9] %>% str_trim();
      }
      #6 <B>ELEVATION:</B> 1500 m<BR>
      if(grepl('ELEVATION', html[z,])){
        p6 = str_split(html[z,], '[<>]')
        catch[line, 'ELEVATION'] = str_replace(p6[[1]][5], 'm', '') %>% str_trim();
      }
      #7 <B>PRIMARY REFERENCE:</B> Lyford, 2001 (<A HREF="/midden/midref.html#228m">228m</A>)<BR>
      if(grepl('PRIMARY REFERENCE', html[z,])){
        p7 = str_split(html[z,], '[<>]')
        p7_sub = str_split(p7[[1]][6], '["]')
        catch[line, 'PRIMARY_REF'] = str_replace(p7[[1]][5], "[(]", "") %>% str_trim();
        catch[line, 'PRIMARY_REF_LINK'] = p7_sub[[1]][2] %>% str_trim();
      }
      #8 <B>ADDITIONAL REFERENCES:</B>  <A HREF="/midden/midref.html#227m"></A><BR>
      if(grepl('ADDITIONAL REFERENCES', html[z,])){
        p8 = str_split(html[z,], '[<>]')
        p8_sub = str_split(p8[[1]][6], '["]')
        # catch[line, 'ADDITIONAL_REF'] = str_replace(p8[[1]][5], "[(]", "") %>% str_trim();
        catch[line, 'ADDITIONAL_REF_LINK'] = p8_sub[[1]][2] %>% str_trim();
      }

      #9 </TD></TR>
      #10 <TR>
      #11 <TD WIDTH="35%">Number of taxa identified in sample: 0</TD><TD>
      if(grepl('Number of taxa', html[z,])) {
        p11 = str_split(html[z,], '[<>]')
        p11_sub = str_split(p11[[1]][3], ':')
        catch[line, 'TAXA_NUM'] = p11_sub[[1]][2] %>% str_trim();
        
        #12 &nbsp;</TD></TR> ### same as #15 but for taxon table
        p12 = str_split(html[z+1,], '[<>]')
        p12_sub = str_split(p12[[1]][2], '["]')
        catch[line, 'TAXA_LINK'] = p12_sub[[1]][2] %>% str_trim();
      }

      #13 <TR>
      #14 <TD WIDTH="35%">Number of C14 ages for this sample: 1</TD><TD>
      if(grepl('Number of C14 ages', html[z,])) {
        p14 = str_split(html[z,], '[<>]')
        p14_sub = str_split(p14[[1]][3], ':')
        catch[line, 'AGES_NUM'] = p14_sub[[1]][2] %>% str_trim();
      }
      #15 <A HREF="/cgi-bin/mid2q2?qtype=2&samcode=BCK10" TARGET="new">SHOW C14 AGES</A></TD></TR>
      if(grepl('SHOW C14 AGES', html[z,])){
        p15 = str_split(html[z,], '[<>]')
        p15_sub = str_split(p15[[1]][2], '["]')
        catch[line, 'AGES_LINK'] = p15_sub[[1]][2] %>% str_trim();
      }
    }
    #advance line!
    line = line + 1
  }
  
  return(catch)
}

t = parser(read)

head(t)
tail(t)

#view some of the samples with taxonomic data
t %>% filter(TAXA_NUM>3) %>% filter(!is.na(LATITUDE)) %>% tail(20)

## Download HTML for TAXA_LINK
dir.create('cgi-bin')

for(row in 1:nrow(t)){
  if(t$TAXA_NUM[row] > 0){
    print(paste('get taxa for', t$SAMPLE[row]))
    download.file(paste('https://geochange.er.usgs.gov', t$TAXA_LINK[row], sep=''), destfile=paste('cgi-bin/', t$SAMPLE[row], "_taxa.html", sep=''))
  }
  if(t$AGES_NUM[row] > 0){
    print(paste('get ages for', t$SAMPLE[row]))
    download.file(paste('https://geochange.er.usgs.gov', t$AGES_LINK[row], sep=''), destfile=paste('cgi-bin/', t$SAMPLE[row], "_ages.html", sep=''))
  }
}

####################
#ENTER TAXA AND AGES PARSING PHASE
# <TR BGCOLOR="CCCCCC"><TH>TAXA</TH><TH>TYPE OF MATERIAL</TH><TH>ORIG.COUNT</TH><TH>ABUNDANCE CODE</TH></TR>
taxa = data.frame(SAMPLE=character(),
                  TAXA=character(),
                  TYPE_OF_MATERIAL=character(),
                  ORIG_COUNT=numeric(),
                  ABUNDANCE_CODE=numeric(),
                  stringsAsFactors = F)

#<TR BGCOLOR="CCCCCC"><TH>LAB ID</TH><TH>C14 AGE</TH><TH>STD DEV</TH><TH>MATERIAL DATED</TH><TH>COMMENTS</TH></TR>
ages = data.frame(SAMPLE=character(),
                  LAB_ID=character(),
                  C14_AGE=numeric(),
                  STD_DEV=numeric(),
                  MATERIAL_DATED=character(),
                  COMMENTS=character(),
                  stringsAsFactors = F)
taxa_line = 1
ages_line = 1


for(row in 1:nrow(t)){
  if(t$TAXA_NUM[row] > 0){
    print(paste('parse taxa for', t$SAMPLE[row]))
    sub_read_taxa = read_delim(paste('cgi-bin/', t$SAMPLE[row], "_taxa.html", sep=''), delim='^') 
    for(s in 1:nrow(sub_read_taxa)){
      ##parse taxa
      # header
      if(grepl('^<TR><TD>', sub_read_taxa[s,])){
        # example data line
        # <TR><TD>Atriplex confertifolia</TD><TD>&nbsp;</TD><TD>3</TD><TD>2</TD></TR>
       # print(sub_read_taxa[s,])
        p2 = str_split(sub_read_taxa[s,], '[<>]')
        taxa[taxa_line, 'SAMPLE'] = t$SAMPLE[row]
        taxa[taxa_line, 'TAXA'] = str_replace(p2[[1]][5], '&nbsp;', '') %>% str_trim();
        taxa[taxa_line, 'TYPE_OF_MATERIAL'] = str_replace(p2[[1]][9], '&nbsp;', '') %>% str_trim();
        taxa[taxa_line, 'ORIG_COUNT'] = str_replace(p2[[1]][13], '&nbsp;', '') %>% str_trim();
        taxa[taxa_line, 'ABUNDANCE_CODE'] = str_replace(p2[[1]][17], '&nbsp;', '') %>% str_trim();
        taxa_line = taxa_line+1
      }
    }
  }
}

for(row in 1:nrow(t)){
  if(t$AGES_NUM[row] > 0){
    print(paste('parse ages for', t$SAMPLE[row]))
    sub_read_ages = read_delim(paste('cgi-bin/', t$SAMPLE[row], "_ages.html", sep=''), delim='^') 
    for(s in 1:nrow(sub_read_ages)){
      ##parse ages
      # header
      if(grepl('^<TR><TD>', sub_read_ages[s,])){
        # example data line
        # <TR><TD>Atriplex confertifolia</TD><TD>&nbsp;</TD><TD>3</TD><TD>2</TD></TR>
        #print(sub_read_ages[s,])
        p2 = str_split(sub_read_ages[s,], '[<>]')
        ages[ages_line, 'SAMPLE'] = t$SAMPLE[row]
        ages[ages_line, 'LAB_ID'] = str_replace(p2[[1]][5], '&nbsp;', '') %>% str_trim();
        ages[ages_line, 'C14_AGE'] = str_replace(p2[[1]][9], '&nbsp;', '') %>% str_trim();
        ages[ages_line, 'STD_DEV'] = str_replace(p2[[1]][13], '&nbsp;', '') %>% str_trim();
        ages[ages_line, 'MATERIAL_DATED'] = str_replace(p2[[1]][17], '&nbsp;', '') %>% str_trim();
        ages[ages_line, 'COMMENTS'] = str_replace(p2[[1]][21], '&nbsp;', '') %>% str_trim();
        ages_line = ages_line+1
      }
    }
    
  }
}

#parse reference list into table
read_refs = read_delim('https://geochange.er.usgs.gov/midden/midref.html', delim='^') 
names(read_refs) = 'RAW_LINES'

ref = read_refs %>% filter(str_detect(RAW_LINES, "^<td>")) 
ref_id = read_refs %>% filter(str_detect(RAW_LINES, "^<tr>"))

for(i in 1:nrow(ref)) {
  p = str_split(ref[i,], '[<>]')
  ref[i,] = p[[1]][3]
  
  p2 = str_split(ref_id[i,], '[<>]')
  ref_id[i,] = p2[[1]][7]
}


cbind(ref_id, ref) %>% head(
  
)



################# WRITE DATA ##################
dir.create('db')
write.csv(t, 'db/samples.csv')
write.csv(taxa, 'db/taxa.csv')
write.csv(ages, 'db/ages.csv')



#example join

test_join = inner_join(t, taxa, 'SAMPLE') %>% arrange(-desc(SAMPLE))
head(test_join)

ages_join = inner_join(t, ages, 'SAMPLE') %>% arrange(-desc(SAMPLE))




 
