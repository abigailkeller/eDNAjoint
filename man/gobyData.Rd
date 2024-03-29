% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/gobyData.R
\docType{data}
\name{gobyData}
\alias{gobyData}
\title{gobyData}
\format{
A list with four matrices representing eDNA sampling data (qPCR.N
and qPCR.K), seine sampling data (count), and site-level covariate data
(site.cov).
\describe{
\item{qPCR.N}{Total number of eDNA qPCR replicates at each site (row) and
eDNA sample replicate (column). Data includes 39 total sites and a
maximum of 22 eDNA sample replicates. NA indicates that fewer eDNA
samples were collected than the maximum at a site.}
\item{qPCR.K}{Total number of positive eDNA qPCR detections at each site
(row) and eDNA sample replicate (column). Data includes 39 total sites
and a maximum of 22 eDNA sample replicates. NA indicates that fewer eDNA
samples were collected than the maximum at a site.}
\item{count}{Count of goby individuals in seine samples at each site (row)
and seine sample replicate (column). Data includes 39 total sites and a
maximum of 22 seine replicates. NA indicates that fewer seine samples
were collected than the maximum at a site.}
\item{site.cov}{Data representing site-level covariates at each site (row).
Data includes mean salinity at a site ('Salinity'), mean time to filter
eDNA samples ('Filter_time'), density of other fish species
('Other_fishes'), size of habitat ('Hab_size'), and presence of
vegetation ('Veg'). All non-integer covariate data is standardized.}
}
}
\source{
\url{https://datadryad.org/stash/dataset/doi:10.5061/dryad.6rs23}
}
\usage{
gobyData
}
\description{
gobyData
}
\references{
Schmelzle, M.C. and Kinziger, A.P. (2016). Using occupancy
modelling to compare environmental DNA to traditional field methods for
regional-scale monitoring of an endangered aquatic species. Molecular
Ecology Resources. 16(4): 895-908.
}
\keyword{data}
