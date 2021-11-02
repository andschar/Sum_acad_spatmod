################################
# Check dominant soil texture  #
################################
# First set your working directory, need to adapt
setwd("/home/andreas/Documents/Projects/Sum_acad_spatmod/Soil_grids")
resultdir <- '/home/andreas/Documents/Projects/Sum_acad_spatmod/results'
# load library for raster processing
library(raster)
# We use data from www.soilgrids.org that is provided by ISRIC - International Soil Reference and Information Centre
# The data is ready for the course, a tutorial how to download is here
# http://gsif.isric.org/doku.php/wiki:tutorial_soilgrids

# load sand and silt raster
sand <- raster("geonode_sndppt_m_sl1_250m.tif")
silt <- raster("geonode_sltppt_m_sl1_250m.tif")
# load country borders - we have downloaded the file before
maw_gadm <- readRDS(file.path(resultdir, "GADM_2.8_MWI_adm0.rds"))
# you need to adapt to your path here!
# check that CRS of country borders and soil layers is identical
identical(maw_gadm@proj4string, sand@crs)

mapview(sand)

# crop layer to extent of malawi
sand_sub1 <- crop(sand, maw_gadm)

spplot(sand_sub1)
# mask values outside of Malawi
sand_sub2 <- mask(sand_sub1, maw_gadm)
spplot(sand_sub2)
# most areas dominantly sand
# check distribution of values for sand
par(las=1,cex=1.5)
hist(sand_sub2, freq=FALSE, xlab="%Sand content", main="")
# approximately 95% of cells have more than 50% sand content

# check for silt
# crop layer to extent of malawi
silt_sub1 <- crop(silt, maw_gadm)
# mask values outside of Malawi
silt_sub2 <- mask(silt_sub1, maw_gadm)
spplot(silt_sub2)
# no areas with more than 25% silt content

# Runoff model could be run soil specific, for reasons of simplicity,
# we assume that sand is generally dominant
