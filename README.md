# Free and open copy of the USGS North American Packrat Midden Database

*These data and tools come with no license or warranty.* You can use these tools or data for any purposes that are consistent with the original published data found at https://geochange.er.usgs.gov/midden/

## Why?

The original database (https://geochange.er.usgs.gov/midden/) is not machine readable and is generally inaccessible for bulk analyses. 

The goal of this repository is to provide better access to these data. The entire database can now be read into your favorite coding environment, spreadsheet, or database software from the files in the [db](https://github.com/rsh249/usgs_packrat_midden_db/tree/master/db) folder.

[Samples table](https://raw.githubusercontent.com/rsh249/usgs_packrat_midden_db/master/db/samples.csv) -- Gives sample level data from the USGS database for all available sites.

[Taxa table](https://raw.githubusercontent.com/rsh249/usgs_packrat_midden_db/master/db/taxa.csv) -- Taxa identified for each sample with taxonomic data.

[Ages table](https://raw.githubusercontent.com/rsh249/usgs_packrat_midden_db/master/db/ages.csv) -- C14 Ages for each sample with carbon dating data.


## How do I use these?

### Option 1: read the archived data:

Read directly into your favorite programming language. e.g., in R do:

```{r}
library(dplyr)

samples = read.csv('https://raw.githubusercontent.com/rsh249/usgs_packrat_midden_db/master/db/samples.csv')
taxa_data = read.csv('https://raw.githubusercontent.com/rsh249/usgs_packrat_midden_db/master/db/taxa.csv')
age_data = read.csv('https://raw.githubusercontent.com/rsh249/usgs_packrat_midden_db/master/db/ages.csv')


taxa_join = inner_join(samples, taxa_data, 'SAMPLE') %>% arrange(-desc(SAMPLE))
head(taxa_join)

ages_join = inner_join(samples, age_data, 'SAMPLE') %>% arrange(-desc(SAMPLE))
head(ages_join)

```