# This script describes the derivation of slope and a hydrological model from digital elevation data
#
# set working directory - enter your directory here
setwd("/home/andreas/Documents/Projects/Sum_acad_spatmod/DEM_hydro")
resultdir <- '/home/andreas/Documents/Projects/Sum_acad_spatmod/results'

# SRTM 90 m data is directly available in R
library(raster)
library(rgdal)

mwi_dem <- getData("alt", country="MWI", mask=TRUE)
mwi_dem@crs
projection(mwi_dem)

mapview(mwi_dem)
# WGS84 projection

# derive slope
terrain()
slp <- raster::terrain(mwi_dem, opt = "slope", unit = "degrees")
# and plot
mapview(slp)

# only few areas with high slope
# save slp layer - uncomment if necessary
save(slp, file = file.path(resultdir, "Slope.RData"))

# in the next step we load a stream network for Malawi that has been clipped
# from the global Hydrosheds network
# This has been done in QGIS because working with 
# large shapefiles is not very efficient in R
# I used the GADM boundaries for clipping in R
# uncomment if you want to repeat these steps
# load('~/Arbeit/Lehre_Betreuung/2014/Summer_academy/Modelling/Rainfall/MWI_adm0.RData')
# plot(gadm)
# uncomment for writing
# writeOGR(gadm, "/Users/ralfs/Arbeit/Lehre_Betreuung/2014/Summer_academy/Modelling/Rainfall/", "Malawi", "ESRI Shapefile") 

# load the river network for Malawi
streams <- readOGR("/home/andreas/Documents/Projects/Sum_acad_spatmod/DEM_hydro/Hydrosheds",
                   layer="mal_riv_15s")
mapview(streams)

getwd()
# now we buffer the network
# first we project to UTM
stream_trans <- spTransform(streams, CRS("+init=epsg:32736"))
# then we load the rgeos library and buffer
library(rgeos)

stream_buf <- gBuffer(stream_trans, width = 200)
mapview(stream_buf)
# buffered network
save(stream_buf, file = file.path(resultdir, "Buff_stream.RData"))

# -------------------------------------------------------------------------------------------
# in the following an alternative is presented for obtaining a stream network
# this example shows how to link R and GRASS GIS, which is more efficient
# -------------------------------------------------------------------------------------------
# 
# first we have to establish the link between R and GRASS GIS

# we project the DEM before use in order to have correct units for buffering

mwidem_trans <- projectRaster(mwi_dem, crs=CRS("+init=epsg:32736"))
mwidem_trans2 <- as(mwidem_trans, "SpatialGridDataFrame") # from raster:: to sp:: data format

proj4 = proj4string(mwidem_trans2)

# format needed for GRASS
proj4string(mwidem_trans2)
# library(spgrass6)
# for grass6
library(rgrass7)
# for grass7
# MacOS users
initGRASS("/usr/lib/grass72", 
          home=tempdir(), override=TRUE, SG=mwidem_trans2)#,
          #mapset = 'PERMANENT')
# Windows OS users please adapt and use the following lines
# location<-initGRASS("C:/OSGeo4W/apps/grass/grass-6.4.3", override=TRUE)
## Please visit "http://cran.r-project.org/web/packages/spgrass6/index.html" 
# and "http://grasswiki.osgeo.org/wiki/GRASS_Help#First_Day_Documentation"
# for details and GRASS initiation instructions for other OS users

execGRASS('g.proj',
          flags = c('c'),
          proj4 = proj4)
gmeta()
# write to GRASS and override projection checking
writeRAST(mwidem_trans2, "DEM", zcol = 1, flags="overwrite")
# in Grass6 use:
# writeRAST6(mwidem_trans2, "DEM", zcol = 1, flags="o")

# use GRASS module r.watershed
# http://grass.osgeo.org/grass65/manuals/r.watershed.html
execGRASS("r.watershed", flags="overwrite",
          parameters=list(elevation="DEM", stream="streams_g", threshold=30))
# threshold is a crucial parameter, has to be adjusted - if available against an existing network

# now buffer the created stream network
# and read into R
execGRASS("r.buffer", flags="overwrite",
          parameters=list(input="streams_g", output="streams_g_buf",  distances=200))
streams_g_buf <- raster(readRAST("streams_g_buf"))

gmeta()

projection(test)
projection(streams_g_buf)
# in GRASS6 use:
# streams_g_buf <- raster(readRAST6("streams_g_buf"))

plot(stream_buf)
plot(streams_g_buf, add=TRUE)
mapview(stream_buf) +
  mapview(streams_g_buf)
# stream network looks similar
