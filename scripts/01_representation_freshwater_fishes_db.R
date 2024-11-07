
####################################################################################################
#### -- Script used to evaluate the representation of Alberta freshwater fishes in databases -- ####
####################################################################################################

#### ----------------- Extract sequence header from fasta ------------------------------------- ####

# Header were extracted using shell command : grep ">" file.fasta | sed -e "s/>//" > headers.txt

#### ------------------ Load libraries  ------------------------------------------------------- ####

library(tidyverse)

#### ----------------- Load databases sequence header ----------------------------------------- ####

## RDP classifier
rdp12s_raw = read.table("~/fish_edna/database/header_rdp_12S.txt", sep = ";")
rdpcoi_raw = read.table("~/fish_edna/database/header_rdp_coi.txt", sep = ";")

## barque
barque12s_raw = read.table("/home/kvilleneuve/fish_edna/database/header_barque_12S.txt", sep = "_")
barquecoi_raw = read.table("/home/kvilleneuve/fish_edna/database/header_bold_coi_barque.txt",  sep = "_")


#### ----------------- Load list of Freshwater fishes from Alberta --------------------------- ####


alberta_fish = read.csv("~/fish_edna/database/fishbase_alberta_freswater.csv", header = TRUE, check.names = FALSE)
alberta_fish$Species = gsub(" ", "_", alberta_fish$Species) # Replace space to underscore

### ------------------- Parse dataframes  -------------------------------------------------- ####

# Because the number of ranks differ between databases used with
# the RDP classifier and the barque workflow they are initially processed separately

## RDP databases

list_rdp_db = list("COI RDP" = rdpcoi_raw, "12S RDP" = rdp12s_raw)
list_rdp_taxa = list()
i = 0
for (databases in list_rdp_db){
  i = i + 1
  names(databases) = c("ID", "Superkingdom", "Kingdom", "Phylum", "Class", "Order", "Family", "Genus", "Species")
  list_rdp_taxa[[i]] = databases
  names(list_rdp_taxa)[i] = names(list_rdp_db[i])
}

## barque databases

list_barque_db = list("12S barque" = barque12s_raw, "COI barque" = barquecoi_raw)
list_barque_taxa = list()
i = 0
for (databases in list_barque_db){
  i = i + 1
  names(databases) = c("Family", "Genus", "sort_species")
  databases$Species = paste(databases$Genus,"_",databases$sort_species, sep ="")
  list_barque_taxa[[i]] = databases
  names(list_barque_taxa)[i] = names(list_barque_db[i])
}

# After parsing each databases we combine them into as single list
# then we filter out fishes which are not found in the list of Alberta freshwater fishes

jointlist_all_db = c(list_rdp_taxa, list_barque_taxa)
list_filtered_db = list()
i = 0

for (databses in jointlist_all_db){
  i = i + 1
  filtered_db = databses %>%
    filter(Species %in% unique(alberta_fish$Species))
  filtered_db_df = as.data.frame(unique(filtered_db$Species))
  names(filtered_db_df) = "Species"
  filtered_db_df[names(jointlist_all_db[i])] = "Yes"
  list_filtered_db[[i]] = filtered_db_df
}

filtered_df = Reduce(function(...) merge(..., all=T), list_filtered_db)

### ------------------------- Combine as dataframe as save output  ----------------------------------------- ####

final_df = merge(alberta_fish, filtered_df, by = "Species", all = TRUE)
final_df$Species = gsub("_", " ", final_df$Species)
# Reordering columns
final_df = final_df[,c(2,3,1,4,5,6,7,8,9,10)]

write.csv(final_df, "~/fish_edna/results/represensation_albertafish_databases.csv", quote = FALSE)
