FROM uwgac/topmed-master:latest

MAINTAINER Ash O-Apostrophe-Farrell (aofarrel@ucsc.edu)

# prevent apt-get dialogs
ENV DEBIAN_FRONTEND noninteractive

# become root to install packages
# is there a better workaround?
USER root

RUN apt-get update & \
	apt-get install git

# an attempt to keep the image as small and secure as possible
# this branch contains only the R scripts I have added
RUN git clone --branch slim https://github.com/aofarrel/analysis_pipeline_WDL.git
