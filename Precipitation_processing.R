# This script describes the preparation of precipitation data
#
# if you don't know how to set your working directory, navigate to your directory
# and select a random file
file.choose()
# afterwards copy and paste your path (without file name!) into the setwd function
#
# set working directory - enter your directory here
setwd("/home/andreas/Documents/Projects/Sum_acad_spatmod/Precipitation_data/")
resultdir = '/home/andreas/Documents/Projects/Sum_acad_spatmod/results'

# we prepare precipitation data
# this data was downloaded from
# ftp://ftp.cpc.ncep.noaa.gov/fews/fewsdata/africa/arc2//geotiff/
# and then unzipped using a Shell window (do not run in R!)
# for file  in *.zip; do unzip $file; done; 
# -----------------------------------------------------
# see paper for different data source and their advantages/disadvantages
# Sylla, M. B., Giorgi, F., Coppola, E. and Mariotti, L. (2013):
# Uncertainties in daily rainfall over Africa: 
# assessment of gridded observation products and evaluation of a regional climate model simulation. 
# Int. J. Climatol., 33: 1805–1817. doi: 10.1002/joc.3551
# -----------------------------------------------------
# 

# load library
library(raster)
library(mapview)

# read raster files with daily precipitation
rasfiles <- list.files(path= paste(getwd(),"/ARC2", sep=""),full.names=TRUE)  
# alternative: set path directly
# rasfiles <- list.files(path="~/Desktop/Data/", full.names = TRUE)


# select tif files
fil_sel <- grep("*tif", rasfiles)
# subset
rasfiles[fil_sel]

# create a layer stack, i.e. files with same resolution, extent etc.
rain_data <- stack(as.list(rasfiles[fil_sel]))
# you can google the coordinate reference system
# we will convert it later

# you could also look into file information using gdal command lines tools from within R
# we first have to change the path and then can invoke the command
# needs modification of the OSGEO installation path on Windows
# Sys.setenv(PATH = "/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/Library/Frameworks/GDAL.framework/Programs")
# system(command = paste("gdalinfo", rasfiles[fil_sel][1]))

# in the next step we crop the extent to Malawi and a bit of the surrounding
raster::getData("ISO3")
# overview on country names
mwi_gadm  <- getData("GADM", country="MWI", level=0,
                     path = resultdir) # GADM = Global ADMinistrative boundaries
# you will find a R data file now in your working directory
plot(mwi_gadm)
mapview(mwi_gadm)

# and convert CRS to the rasterstack
mwi_trans <- spTransform(mwi_gadm, rain_data@crs)
mapview(mwi_gadm) +
  mapview(mwi_trans)

# plot for defined region
plot(mwi_trans, col="white", xlim=c(30,40), ylim=c(-20, -5))

# now we draw an Extent around Malawi
Ex <- drawExtent()
# you could also use the following line to create an Extent (uncomment it)
Ex <- extent(31.8, 37.2, -17.6, -8.7)
Ex
# and use it to crop the raster stack
mal_rain <- crop(rain_data, Ex)
# let's have a look
plot(mal_rain)
# plots the first 16
plot(mal_rain, 16:25)
# plots defined rasters
mapview(mal_rain) +
  mapview(mwi_trans)

# and now use the maximum cell value 
max_mal <- max(mal_rain)
plot(max_mal)

# and plot Malawi over maximum rain map
plot(mwi_trans, add=TRUE)
# we notice that the GADM polygon is much more precise

mapview(max_mal) +
  mapview(mwi_trans)

# we convert the raster file to WGS84

precip_mal <- projectRaster(max_mal, crs=CRS("+init=epsg:4326"))
# and write it to disk
writeRaster(precip_mal, file.path(resultdir, "Precip.tif"), format="GTiff", overwrite = TRUE)


