# TOPMed Analysis Pipeline -- WDL Version

![help wanted](https://img.shields.io/badge/help-wanted-red)**WIP; not suitable for published use**![help wanted](https://img.shields.io/badge/help-wanted-red)
---
[![WDL 1.0 shield](https://img.shields.io/badge/WDL-1.0-lightgrey.svg)](https://github.com/openwdl/wdl/blob/main/versions/1.0/SPEC.md)  
This is a collection of several WDL files which attempt to implement some components of the [University of Washington TOPMed pipeline](https://github.com/UW-GAC/analysis_pipeline). Rather than running as a Python pipeline, this takes the R scripts which the Python pipeline is calling and wraps them into various WDL tasks.

Example files are provided in `testdata`. The original pipeline had arguments relating to runtime such as `ncores` and `cluster_type` that do not apply to WDL. Please familarize yourself with the [runtime attributes of WDL](https://cromwell.readthedocs.io/en/stable/RuntimeAttributes/) if you are unsure how your settings may transfer.

## Motivation
The original goal of this undertaking was to provide sample preparation options for TOPMed Freeze 8 users on Terra, who previously had to work with an unoptimized Jupyter notebook. While we hope that this can eventually be used for that case, the scope has since widened for other forms of analysis, and in the name of interoperability between CWL-based platforms and WDL-based platforms. For that reason, this pipeline is designed to be as close to [the CWL version](https://github.com/UW-GAC/analysis_pipeline_cwl) as possible.

## Bonuses
* The original script required a space to be included in input files. This is no longer necessary.
* This pipeline is very similiar to the CWL version and the main differences between the two [are throughly documented](https://github.com/aofarrel/analysis_pipeline_WDL/blob/master/cwl-vs-wdl.md).
* As it works in a Docker container, it does not have any external dependencies other than the usual setup required for [WDL](https://software.broadinstitute.org/wdl/documentation/quickstart) and [Cromwell](http://cromwell.readthedocs.io/en/develop/).

## Limitations
* Functionality is not one-to-one with the UW pipeline
* Due to how Cromwell works, local runs may draw too much memory; [see here for more info + migitation strategies](https://github.com/aofarrel/analysis_pipeline_WDL/issues/15)

## Components
* [vcf-to-gds-wf](https://github.com/aofarrel/analysis_pipeline_WDL/blob/master/README_vcf-to-gds-wf.md)

------

#### Author
Ash O'Farrell (aofarrel@ucsc.edu)  
Please see the original TOPMed Pipeline for contributors to the overall structure and R scripts that this WDL relies upon.
