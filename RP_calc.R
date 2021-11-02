# Computation of Runoff potential

require(mapview)

# first we load all maps into R
# and process them individually
setwd('/home/andreas/Documents/Projects/Sum_acad_spatmod')
resultdir <- '/home/andreas/Documents/Projects/Sum_acad_spatmod/results'
# load slope
# loading is fairly easy in Rstudio:
# you can open the file over the file menu (double click)
load(file.path(resultdir, 'Slope.RData'))

# load buffered streams
load(file.path(resultdir, 'Buff_stream.RData'))

# load crop land
load(file.path(resultdir, 'Crop_trans.RData'))

# Soil OC
library(rgdal)
oc <- readGDAL("/home/andreas/Documents/Projects/Sum_acad_spatmod/data/Average_Soil_Organic_Carbon_raster.tif")
image(oc)

# we check that information are loaded
ls()
str(oc)
# we begin processing the OC
oc@data$band2 <- 1/(1+(10*oc@data$band1))
# check that result is plausible
summary(oc@data$band2)

# multiply with interception term
oc@data$band3 <- oc@data$band2*(1-25/100)

# and multiply with application rate
# we transform the CRS before in order to
# be able to multiply with the application rate
# we first convert to a raster object and set resolution to 1000
library(raster)
ocras <- raster(oc["band3"])
ocras_trans <- projectRaster(ocras, crs = stream_buf@proj4string, res = 1000)
mapview(ocras)

# check resolution
ocras_trans
plot(ocras_trans)
# resolution of 1000*1000 means 1 km2 = 100 ha
# this means we have to multiple with 136*100 = 13600
ocras_fin <- ocras_trans*13600

# next step we calculate the slope values
# we create a new raster in which we calculate
f_slp <- slp
f_slp[f_slp <= 20] <- 0.001423 *(f_slp[f_slp <= 20])^ 2 + 0.02153 *(f_slp[f_slp <= 20])
f_slp[f_slp > 20] <- 1

# check results
summary(f_slp)
summary(slp)
# same number of NAs, makes sense

# now we use the max Rainfall to compute the respective function f(P,T)
rain_max <- readGDAL(file.path(resultdir, "Precip.tif"))
class(rain_max)
summary(rain_max@data)
# calculate after replication of file
rain_rp <- rain_max
rain_rp@data$band1 <- -5.86e-6 * (rain_max@data$band1)^3 + 2.63e-3 * (rain_max@data$band1)^2 - 1.14e-2*rain_max@data$band1 - 1.64e-2
# check values
summary(rain_max@data$band1)
summary(rain_rp@data$band1)
# looks plausible

# check relationship between rain and surface runoff
dev.off()
plot(rain_max@data$band1, rain_rp@data$band1)

# final values for RP calculated as f(P,T)/P
# hence we need to divide rain_rp by rain_max
rain_fin <- rain_rp
rain_fin@data$band1 <- rain_rp@data$band1/rain_max@data$band1
summary(rain_fin@data$band1)

# ok we have now more or less all parts of the equation together
# see slides for overview
# rain_fin@data$band1
# f_slp
# ocras_fin

# Next step: calculate crop area per ha 
crop_trans@proj4string
# check projection
# does it match with crop file?
identical(crop_trans@proj4string, CRS(projection(ocras_fin)))
# match!

time = Sys.time()
crop_trans_r <- rasterize(crop_trans, ocras_fin, getCover=TRUE)
Sys.time() - time
save(crop_trans_r, file = file.path(resultdir, 'crop_trans_r.RData'))
# this function runs ~ 10 minutes on a Core i7 with 2.3 Ghz and 8 GB RAM
# download if you have a slow computer and load (you should know by now...)
load(file.path(resultdir, 'crop_trans_r.RData'))
plot(crop_trans_r)
# looks plausible
# divide by 100 as should be between 0 and 1
crop_fin <- crop_trans_r/100

# now we can multiply all files
# but first check that all are in some projection, extent etc.
crop_fin
ocras_fin
# both same resolution, extent and CRS
f_slp
# needs conversion
fin_slp <- projectRaster(f_slp, ocras_fin)
fin_slp
# ok
rain_ras <- raster(rain_fin)
rain_ras_fin <- projectRaster(rain_ras, ocras_fin)

# combine all layers
final_rp <- crop_fin*ocras_fin* fin_slp*rain_ras_fin
mapview(final_rp)
hist(final_rp)
# double square root transformation
# note that in the literature often log is used
final_rpsq <- sqrt(sqrt(final_rp))
plot(final_rpsq)
hist(final_rpsq)

# lets cut only the cells around water bodies
class(stream_buf)
stream_buf@proj4string
# matches with the others

# mask cells that are not around streams
rp_mal <- rasterize(stream_buf,final_rpsq, mask = TRUE)
mapview(rp_mal)
# export to google earth for web presentation
# set name for layer
rp_mal@data@names <- "RP"
# load kml package
# if you do not have this package - install first
# install.packages("plotKML", repos=c("http://R-Forge.R-project.org")) #! DIDN'T WORK FOR ME!
library(plotKML)
data(SAGA_pal)
kml(rp_mal, colour_scale = SAGA_pal[[1]], colour = "RP")
# now open the file and display over Google Earth

# more dynamic visualisation can be achieved using 
# the Google visualisation package
# but this is beyond the scope of our course
# http://code.google.com/p/google-motion-charts-with-r/


