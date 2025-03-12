# nf-core/metaamr: Usage

## ⚠️ **Warning:** Please read this documentation on the nf-core website: [https://nf-co.re/metaamr/usage](https://nf-co.re/metaamr/usage)

> _Documentation of pipeline parameters is generated automatically from the pipeline schema and can no longer be found in markdown files._

## Introduction
nf-core/metaamr is a bioinformatics pipeline for the detection and characterization of antimicrobial resistance (AMR) genes, plasmids, and taxonomic classification in long-read Nanopore metagenomic data. It enables highly parallelized AMR detection and taxonomic analysis across multiple tools and databases simultaneously. The pipeline efficiently processes sequencing data, generating standardized output tables to facilitate direct comparison of results across different tools and reference databases.

## General Usage

To run nf-core/metaamr, you need at least two input files:

	1.	A sequencing read samplesheet
	2.	A database 

Both files contain metadata and paths to sequencing data and reference databases.If either of these is omitted, the tool will not be executed.

Each step and tool in MetaAMR is optional and must be explicitly enabled. To run a specific tool:

  - For tools that require a database, you can either provide your own in the <database>.csv file or let MetaAMR download it automatically using the appropriate --download_<tool>_db flag
	
  - Supply the appropriate --run_<tool> flag in your command.


The following tools can only be run on assembled data:
- AMRFinderPlus
- Abricate
- RGI 
- PlasmidFinder 
- PlasClass. 

In contrast, ResFinder, Kaiju, and Centrifuge can be run on both assembled and unassembled (raw read) data.

For details on how to prepare input samplesheets and databases, as well as how to run the pipeline, please refer to the documentation. See the parameters section for additional pipeline options.

<!-- TODO nf-core: Add documentation about anything specific to running your pipeline. For general topics, please point to (and add to) the main nf-core website. -->

## Samplesheet input

nf-core/MetaAMR can accept as input raw long-read FASTQ files (Oxford Nanopore)
You will need to create a samplesheet with information about the samples you would like to analyse before running the pipeline. Use this parameter to specify its location. It has to be a comma-separated file with 2 columns, and a header row as shown in the examples below:


This samplesheet is then specified on the command line as follows:
--input '[path to samplesheet file]' 


### Full samplesheet

 There is a strict requirement for the first 2 columns to match those defined in the table below.

A final samplesheet file consisting of single-end data may look something like the one below. This is for 3 samples.

```csv title="samplesheet.csv"
sample,fastq_1
sg17,sample17_S4_L003_R1_001.fastq.gz,
sg18,sample18_S5_L003_R1_001.fastq.gz,
sg19,sample19_S6_L003_R1_001.fastq.gz,
```

| Column    | Description                                                                                                                                                                            |
| --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `sample`  | Custom sample name. This entry must be unique. Spaces in sample names should converted to underscores (`_`). |
| `fastq_1` | Full path to FastQ file for Nanopore long reads. File has to be gzipped and have the extension ".fastq.gz" or ".fq.gz".                                                             |

An [example samplesheet](../assets/samplesheet.csv) has been provided with the pipeline.

### Full database sheet
nf-core/metaamr supports running multiple AMR detection, plasmid detection, and taxonomic classification tools in parallel against various databases.

### Database Handling

- Kaiju and Centrifuge: A database must be provided in the database.csv
- Abricate and PlasClass: These tools come with built-in databases, so no external database input is required.
- Other tools (ResFinder, AMRFinderPlus, CARD-RGI and plasmidfinder): You can either provide a database or allow the pipeline to automatically download the required database using options like: --download_resfinder_db

An example database sheet can look as follows, where 6 tools are being used
```csv title="database.csv"
tool,db_name,db_params,db_path
kaiju,kaiju_db,,/<path>/<to>/kaiju_db
centrifuge,centrifuge_db,,/<path>/<to>/centrifuge_database
resfinder,custom_resfinder_db,,/<path>/<to>/resfinder_db/
amrfinderplus,amrfinder_db,,/<path>/<to>/amrfinderplus_db/
cardrgi,card_db,,/<path>/<to>/card_db/
plasmidfinder,plasmidfinder_db,,/<path>/<to>/plasmidfinder_db
```

| Column    | Description |
|-----------|------------|
| **tool**      | MetaAMR tool (supported by nf-core/metaamr) that the database has been indexed for **[required]**. |
| **db_name**   | A unique name per tool for the particular database **[required]**. Names must be unique across tools, even if reusing the same database. |
| **db_params** | Any parameters for the MetaAMR to use  against this specific database. Can be empty to use default parameters.  |
| **db_path**   | Path to the database. A **directory** containing database index files. **[required]** |


## Running the pipeline

The typical command for running the pipeline is as follows:

```bash
nextflow run nf-core/metaamr --input samplesheet.csv --databases databases.csv --outdir <OUTDIR>  --run_<TOOL1> --run_<TOOL2> -profile docker
```

This will launch the pipeline with the `docker` configuration profile. See below for more information about profiles.

Note that the pipeline will create the following files in your working directory:

```bash
work                # Directory containing the nextflow working files
<OUTDIR>            # Finished results in specified location (defined with --outdir)
.nextflow_log       # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

If you wish to repeatedly use the same parameters for multiple runs, rather than specifying each flag in the command, you can specify these in a params file.

Pipeline settings can be provided in a `yaml` or `json` file via `-params-file <file>`.

⚠️ **Warning:**

Do not use `-c <file>` to specify parameters as this will result in errors. Custom config files specified with `-c` must only be used for [tuning process resource specifications](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources), other infrastructural tweaks (such as output directories), or module arguments (args).

The above pipeline run specified with a params file in yaml format:

```bash
nextflow run nf-core/metaamr -profile docker -params-file params.yaml
```
with:

```yaml title="params.yaml"
input: './samplesheet.csv'
outdir: './results/'
genome: 'GRCh37'
<...>
```

You can also generate such `YAML`/`JSON` files via [nf-core/launch](https://nf-co.re/launch).

### Updating the pipeline

When you run the above command, Nextflow automatically pulls the pipeline code from GitHub and stores it as a cached version. When running the pipeline after this, it will always use the cached version if available - even if the pipeline has been updated since. To make sure that you're running the latest version of the pipeline, make sure that you regularly update the cached version of the pipeline:

```bash
nextflow pull nf-core/metaamr
```
## Sequencing quality control
FastQC gives general quality metrics about your reads. It provides information about the quality score distribution across your reads, per base sequence content (%A/T/G/C), adapter contamination and overrepresented sequences.

## Preprocessing Steps
nf-core/metaamr offers three main preprocessing steps for preprocessing raw sequencing reads:

- Read processing: adapter clipping.
- Complexity filtering: removal of low-sequence complexity reads.
- Host read-removal: removal of reads aligning to reference genome(s) of a host.

You can save the 'final' reads from these steps with --save_analysis_ready_fastqs .

### Read Processing
For accurate antimicrobial resistance (AMR) gene detection and taxonomic classification, it is highly recommended to preprocess raw sequencing reads to remove sequencing artifacts that may lead to false-positive identifications.
Porechop is used for adapter trimming and read merging. It removes sequencing adapters and improves downstream analysis accuracy.


### Read Quality Filtering
Removing low-quality reads: Ensures only high-quality reads are used in AMR detection, plasmid identification, and taxonomic classification.
Filtering low-quality reads is performed using Filtlong.

### Host-Read Removal

In MetaAMR, host-read removal can be enabled using the --perform_hostremoval flag. This step eliminates host-derived reads from long-read Oxford Nanopore data, improving downstream AMR gene detection, plasmid identification, and taxonomic classification.

Similar to quality filtering, host-read removal can reduce misclassifications by eliminating non-microbial sequences. Since the host genome is already known, removing its reads before computationally intensive classification and AMR detection can improve efficiency. 

Host reads are identified using Minimap2, which aligns sequencing reads against a provided reference genome. Unaligned reads are retained for further AMR and taxonomic analysis.

Providing a Reference Genome
- A FASTA-formatted host genome must be provided using --hostremoval_reference.
- A Minimap2 pre-indexed .mmi file can be supplied using --hostremoval_index to speed up processing.
- If an index is not provided, MetaAMR will generate one automatically.

Multiple Host Sequences:

If you need to remove multiple sequences, you can concatenate multiple FASTA files into a single reference file before running host removal.

### Assembly and Quality Assessment
nf-core/metaamr supports optional genome assembly and assembly polishing to improve the accuracy and completeness of assembled contigs before downstream AMR and plasmid detection.
- Genome Assembly with Flye: If enabled, MetaAMR assembles long-read Nanopore sequencing data using Flye, a tool designed for de novo assembly of long reads.

- Assembly Quality Assessment with QUAST: To evaluate the quality of the assembled genome, MetaAMR runs QUAST, which provides key assembly metrics such as contig length, N50, and genome completeness.

- Assembly Polishing with Racon: If enabled, the assembled genome undergoes two rounds of polishing with Racon to improve consensus accuracy by correcting sequencing errors. This step enhances the quality of the assembled contigs, ensuring more reliable downstream analysis for AMR detection, plasmid identification, and taxonomic classification.

### Antimicrobial Resistance (AMR) Detection

nf-core/metaamr detects antimicrobial resistance (AMR) genes using multiple bioinformatics tools and reference databases. This allows for a comprehensive and comparative AMR analysis across different detection methods.
- AMR Detection with ResFinder, AMRFinderPlus, CARD-RGI, and Abricate: These tools identify resistance genes from sequencing data, providing insights into potential antimicrobial resistance mechanisms.

- Supports Both Assembly and Read-Based Approaches:
 ResFinder can analyze both assembled genomes and raw reads.

- AMRFinderPlus, CARD-RGI, and Abricate require assembled genomes for AMR detection.

### Plasmid detection
nf-core/metaamr detects plasmids using multiple bioinformatics tools, identifying plasmid-derived sequences within long-read Nanopore metagenomic data. Plasmids play a crucial role in horizontal gene transfer and are often associated with antimicrobial resistance (AMR) genes.

Plasmid Detection with PlasmidFinder and PlasClass:
- PlasmidFinder identifies known plasmid sequences by comparing assembled contigs against reference databases.
- PlasClass classifies assembled contigs as plasmid-derived or chromosomal, helping distinguish plasmid-associated sequences.

Assembly Requirement
- Both PlasmidFinder and PlasClass require assembled genomes for plasmid identification and classification.
- Raw sequencing reads cannot be directly analyzed by these tools; therefore, assembly must be performed before plasmid detection.

### Taxonomic classification
nf-core/metaamr performs taxonomic classification to identify and profile microbial communities within long-read Nanopore metagenomic data. This step provides crucial insights into the composition of metagenomic samples and the potential hosts of antimicrobial resistance (AMR) genes.
Taxonomic Classification with Kaiju and Centrifuge:
- Kaiju performs taxonomic classification by comparing sequences to protein-level databases, making it well-suited for analyzing highly fragmented or error-prone long reads.
- Centrifuge classifies reads against nucleotide-level reference databases, offering a fast and memory-efficient approach for taxonomic identification.

Assembly vs. Read-Based Classification
- Kaiju and Centrifuge can process both assembled and raw sequencing reads, allowing flexibility in taxonomic classification.
- Classification can be performed on raw reads to retain maximum sequencing data or on assembled contigs for a more refined taxonomic assignment.


### Post Processing
#### Visualization

nf-core/metaamr supports generation of Krona interactive pie chart plots for the following compatible tools.

- Centrifuge
- Kaiju
#### hAMRonization
nf-core/metaamr supports the generation of standardized AMR reports through hAMRonization, a framework designed to unify antimicrobial resistance (AMR) results across different tools. By harmonizing AMR gene predictions from multiple detection tools, MetaAMR ensures consistency and comparability of results, facilitating downstream analysis and interpretation.

hAMRonization is an optional feature and will only be performed if more than one AMR detection tool is run in the pipeline. If enabled, it consolidates results from different tools into a standardized output, reducing inconsistencies and improving the interpretability of AMR findings.



### Reproducibility

It is a good idea to specify a pipeline version when running the pipeline on your data. This ensures that a specific version of the pipeline code and software are used when you run your pipeline. If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code since.

First, go to the [nf-core/metaamr releases page](https://github.com/nf-core/metaamr/releases) and find the latest pipeline version - numeric only (eg. `1.3.1`). Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.3.1`. Of course, you can switch to another version by changing the number after the `-r` flag.

This version number will be logged in reports when you run the pipeline, so that you'll know what you used when you look back in the future. For example, at the bottom of the MultiQC reports.

To further assist in reproducbility, you can use share and re-use [parameter files](#running-the-pipeline) to repeat pipeline runs with the same settings without having to write out a command with every single parameter.

:::tip
If you wish to share such profile (such as upload as supplementary material for academic publications), make sure to NOT include cluster specific paths to files, nor institutional specific profiles.
:::

## Core Nextflow arguments

:::note
These options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen).
:::

### `-profile`

Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments.

Several generic profiles are bundled with the pipeline which instruct the pipeline to use software packaged using different methods (Docker, Singularity, Podman, Shifter, Charliecloud, Apptainer, Conda) - see below.

:::info
We highly recommend the use of Docker or Singularity containers for full pipeline reproducibility, however when this is not possible, Conda is also supported.
:::

The pipeline also dynamically loads configurations from [https://github.com/nf-core/configs](https://github.com/nf-core/configs) when it runs, making multiple config profiles for various institutional clusters available at run time. For more information and to see if your system is available in these configs please see the [nf-core/configs documentation](https://github.com/nf-core/configs#documentation).

Note that multiple profiles can be loaded, for example: `-profile test,docker` - the order of arguments is important!
They are loaded in sequence, so later profiles can overwrite earlier profiles.

If `-profile` is not specified, the pipeline will run locally and expect all software to be installed and available on the `PATH`. This is _not_ recommended, since it can lead to different results on different machines dependent on the computer enviroment.

- `test`
  - A profile with a complete configuration for automated testing
  - Includes links to test data so needs no other parameters
- `docker`
  - A generic configuration profile to be used with [Docker](https://docker.com/)
- `singularity`
  - A generic configuration profile to be used with [Singularity](https://sylabs.io/docs/)
- `podman`
  - A generic configuration profile to be used with [Podman](https://podman.io/)
- `shifter`
  - A generic configuration profile to be used with [Shifter](https://nersc.gitlab.io/development/shifter/how-to-use/)
- `charliecloud`
  - A generic configuration profile to be used with [Charliecloud](https://hpc.github.io/charliecloud/)
- `apptainer`
  - A generic configuration profile to be used with [Apptainer](https://apptainer.org/)
- `wave`
  - A generic configuration profile to enable [Wave](https://seqera.io/wave/) containers. Use together with one of the above (requires Nextflow ` 24.03.0-edge` or later).
- `conda`
  - A generic configuration profile to be used with [Conda](https://conda.io/docs/). Please only use Conda as a last resort i.e. when it's not possible to run the pipeline with Docker, Singularity, Podman, Shifter, Charliecloud, or Apptainer.

### `-resume`

Specify this when restarting a pipeline. Nextflow will use cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously. For input to be considered the same, not only the names must be identical but the files' contents as well. For more info about this parameter, see [this blog post](https://www.nextflow.io/blog/2019/demystifying-nextflow-resume.html).

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

### `-c`

Specify the path to a specific config file (this is a core Nextflow command). See the [nf-core website documentation](https://nf-co.re/usage/configuration) for more information.

## Custom configuration

### Resource requests

Whilst the default requirements set within the pipeline will hopefully work for most people and with most input data, you may find that you want to customise the compute resources that the pipeline requests. Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the steps in the pipeline, if the job exits with any of the error codes specified [here](https://github.com/nf-core/rnaseq/blob/4c27ef5610c87db00c3c5a3eed10b1d161abf575/conf/base.config#L18) it will automatically be resubmitted with higher requests (2 x original, then 3 x original). If it still fails after the third attempt then the pipeline execution is stopped.

To change the resource requests, please see the [max resources](https://nf-co.re/docs/usage/configuration#max-resources) and [tuning workflow resources](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources) section of the nf-core website.

### Custom Containers

In some cases you may wish to change which container or conda environment a step of the pipeline uses for a particular tool. By default nf-core pipelines use containers and software from the [biocontainers](https://biocontainers.pro/) or [bioconda](https://bioconda.github.io/) projects. However in some cases the pipeline specified version maybe out of date.

To use a different container from the default container or conda environment specified in a pipeline, please see the [updating tool versions](https://nf-co.re/docs/usage/configuration#updating-tool-versions) section of the nf-core website.

### Custom Tool Arguments

A pipeline might not always support every possible argument or option of a particular tool used in pipeline. Fortunately, nf-core pipelines provide some freedom to users to insert additional parameters that the pipeline does not include by default.

To learn how to provide additional arguments to a particular tool of the pipeline, please see the [customising tool arguments](https://nf-co.re/docs/usage/configuration#customising-tool-arguments) section of the nf-core website.

### nf-core/configs

In most cases, you will only need to create a custom config as a one-off but if you and others within your organisation are likely to be running nf-core pipelines regularly and need to use the same settings regularly it may be a good idea to request that your custom config file is uploaded to the `nf-core/configs` git repository. Before you do this please can you test that the config file works with your pipeline of choice using the `-c` parameter. You can then create a pull request to the `nf-core/configs` repository with the addition of your config file, associated documentation file (see examples in [`nf-core/configs/docs`](https://github.com/nf-core/configs/tree/master/docs)), and amending [`nfcore_custom.config`](https://github.com/nf-core/configs/blob/master/nfcore_custom.config) to include your custom profile.

See the main [Nextflow documentation](https://www.nextflow.io/docs/latest/config.html) for more information about creating your own configuration files.

If you have any questions or issues please send us a message on [Slack](https://nf-co.re/join/slack) on the [`#configs` channel](https://nfcore.slack.com/channels/configs).

## Running in the background

Nextflow handles job submissions and supervises the running jobs. The Nextflow process must run until the pipeline is finished.

The Nextflow `-bg` flag launches Nextflow in the background, detached from your terminal so that the workflow does not stop if you log out of your session. The logs are saved to a file.

Alternatively, you can use `screen` / `tmux` or similar tool to create a detached session which you can log back into at a later time.
Some HPC setups also allow you to run nextflow within a cluster job submitted your job scheduler (from where it submits more jobs).

## Nextflow memory requirements

In some cases, the Nextflow Java virtual machines can start to request a large amount of memory.
We recommend adding the following line to your environment to limit this (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```
