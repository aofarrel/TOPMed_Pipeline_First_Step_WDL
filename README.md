# TOPMed Analysis Pipeline -- WDL Version

**Work in progress, not suitable for published use**
---

## This branch is used to build Docker containers. It is not a development branch.

It contains a minimal amount of test data and R scripts, the latter of which are hardcoded into the Docker image so the user does not need to pass in a bunch of R scripts. R scripts that are in development should not be placed into this branch. Instead, pass them in as an input parameter for the WDL.

The Docker container in question currently builds off the UAW-CAG Docker, so this repo does not contain the TOPMed packages and cannot be the sole basis of a Docker container.

For documentation on this repo, please see the readme on any other branch.

## R Scripts Included
* ld_pruning.R
* vcfToGds.R

### Authors
Contributing authors to the WDLs in this fork include:
* Ash O'Farrell (aofarrel@ucsc.edu)
* Tim Majarian (tmajaria@broadinstitute.org) -- original [GDS2VCF WDL and WDL-ready R script](https://github.com/manning-lab/vcfToGds) that this project was originally a fork of
