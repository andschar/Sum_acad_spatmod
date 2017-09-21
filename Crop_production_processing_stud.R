###
# setwd("~/Arbeit/Lehre_Betreuung/2017/SS/Summer_academy/Modelling/")

library(rgdal)
library(maptools)
library(mapview)

# library for GDAL/OGR drivers
# import shapefile - you need to set your path to the file here!
resultdir <- file.path(getwd(), 'results')
landcover <- readOGR("/home/andreas/Documents/Projects/Sum_acad_spatmod/data/mwi_gc_adg",
                     layer="mwi_gc_adg")
# enter shapefile directory and filename without file extension
# data taken from http://www.fao.org/geonetwork/srv/en/main.home?uuid=5153876a-1afa-4c5f-8606-228f928d16fe
# Regional land cover data for Malawi

# inspect object
getClass(class(landcover))
getSlots(class(landcover))
head(landcover@data)

# which land cover types occur?
sort(unique(landcover@data$GRIDCODE))

#--------------------------Exercise--------------------------
# Look up which of these codes are related to crop production!

# now we extract these crop categories
cropmwi <- landcover[landcover@data$GRIDCODE %in% c("PLACE CODES HERE - REMOVE QUOT. MARKS"), ]
sort(unique(cropmwi@data$GRIDCODE))
# worked!

sum(cropmwi@data$AREA_M2)/(1000*1000) 
# sum of crop area in km2
# 22747.28 is approximately 20% of Malawi (118,480 km2 according to wikipedia)

getClass(class(cropmwi))
# now let us dissolve the polygons as we are only interested in cropland
# to dissolve, we run an union query over the spatial dataframe
crop_comb <- unionSpatialPolygons(cropmwi, rep(1, length(cropmwi@data$GRIDCODE)))

#--------------------------Exercise--------------------------
# now we project into UTM and calculate the crop area
# Find an appropriate UTM coordinate system for Malawi!

# projection
crop_trans <- spTransform(crop_comb, CRS("+init= PLACE CODE HERE "))

# area calculation
crop_trans@polygons

str(crop_trans)
# crop_trans@polygons[[1]]@Polygons[[1]]@area
areas <- sapply(slot(crop_trans, "polygons"), function(x) sapply(slot(x, "Polygons"), slot, "area"))
sum(areas)/(1000*1000)
# 27244.1 is more plausible

# we write the file as Rdata object
# uncomment to save
save(crop_trans, file = file.path(resultdir, "Crop_trans.RData"))

