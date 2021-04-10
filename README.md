# TOPMed Analysis Pipeline -- WDL Version

[![WDL 1.0 shield](https://img.shields.io/badge/WDL-1.0-lightgrey.svg)](https://github.com/openwdl/wdl/blob/main/versions/1.0/SPEC.md) ![help wanted](https://img.shields.io/badge/help-wanted-red)  
This is a work-in-progress project to implement some components of the [University of Washington TOPMed pipeline](https://github.com/UW-GAC/analysis_pipeline) components into Workflow Description Lauange (WDL) in a way that closely mimics [the Common Workflow Langauge version of the UW Pipeline](https://github.com/UW-GAC/analysis_pipeline_cwl) as possible. In other words, this is a WDL that mimics a CWL that mimics a Python pipeline. All three pipelines, however, use the same underlying R scripts which do most of the heavy lifting, making their results directly comparable.

Example files are provided in `testdata`. The original pipeline had arguments relating to runtime such as `ncores` and `cluster_type` that do not apply to WDL. Please familarize yourself with the [runtime attributes of WDL](https://cromwell.readthedocs.io/en/stable/RuntimeAttributes/) if you are unsure how your settings may transfer.

## Motivation
The original goal of this undertaking was to provide sample preparation options for TOPMed Freeze 8 users on Terra, who previously had to work with an unoptimized Jupyter notebook. While we hope that this can eventually be used for that case, the scope has since widened for other forms of analysis, and in the name of interoperability between CWL-based platforms and WDL-based platforms. For that reason, this pipeline is designed to be as close to [the CWL version](https://github.com/UW-GAC/analysis_pipeline_cwl) as possible.

## Features
* This pipeline is very similiar to the CWL version and the main differences between the two [are throughly documented](https://github.com/aofarrel/analysis_pipeline_WDL/blob/master/cwl-vs-wdl.md).
* As it works in a Docker container, it does not have any external dependencies other than the usual setup required for [WDL](https://software.broadinstitute.org/wdl/documentation/quickstart) and [Cromwell](http://cromwell.readthedocs.io/en/develop/).
* Testing has indicated that the results the CWL pipeline and this WDL pipeline give across platforms are almost exactly the same.

## Limitations
* Functionality is not one-to-one with the UW pipeline
* Due to how Cromwell works, local runs may draw too much memory; [see here for more info + migitation strategies](https://github.com/aofarrel/analysis_pipeline_WDL/issues/15)

## Components
* [vcf-to-gds-wf](https://github.com/aofarrel/analysis_pipeline_WDL/blob/master/README_vcf-to-gds-wf.md)

------

#### Author
Ash O'Farrell (aofarrel@ucsc.edu)  
Please see the original TOPMed Pipeline for contributors to the overall structure and R scripts that this WDL relies upon.
