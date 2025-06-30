# PandoraVirus

PandoraVirus is a Nextflow pipeline for detecting and identifying RNA viruses from public sequencing data. It automates the processing of metagenomic samples, enabling the identification, annotation, and reporting of viral sequences with minimal user intervention.

<!-- vscode-markdown-toc -->
* 1. [Installation](#Installation)
	* 1.1. [Prerequisites](#Prerequisites)
	* 1.2. [Install Docker](#InstallDocker)
	* 1.3. [Remove Docker](#RemoveDocker)
	* 1.4. [Setup Docker](#SetupDocker)
* 2. [Usage](#Usage)
* 3. [Pipeline Overview](#PipelineOverview)
* 4. [Configuration](#Configuration)
* 5. [Parameters](#Parameters)
* 6. [Output](#Output)
* 7. [Running on Google Cloud Platform (GCP)](#RunningonGoogleCloudPlatformGCP)
	* 7.1. [Example command](#Examplecommand)
	* 7.2. [Required changes in `params.config`](#Requiredchangesinparams.config)
* 8. [Contributing](#Contributing)
* 9. [License](#License)

<!-- vscode-markdown-toc-config
	numbering=true
	autoSave=true
	/vscode-markdown-toc-config -->
<!-- /vscode-markdown-toc -->


##  1. <a name='Installation'></a>Installation

###  1.1. <a name='Prerequisites'></a>Prerequisites
- [Nextflow](https://www.nextflow.io/) (>=24.04.4)
- [Docker](https://www.docker.com/)
###  1.2. <a name='InstallDocker'></a>Install Docker

```bash
curl -fsSL https://get.docker.com | sudo sh
```

###  1.3. <a name='RemoveDocker'></a>Remove Docker

```bash
sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
```

###  1.4. <a name='SetupDocker'></a>Setup Docker

```bash
sudo groupadd docker
sudo usermod -aG docker $USER
docker login
```

##  2. <a name='Usage'></a>Usage

To run the pipeline, use the following command:

```bash
nextflow run main.nf -params-file <path/to/json_file> [-bg]
```
- `bg`: run in backgroud [optional]
- `json.file` to insert your data:

```json
{
	"assembly_tool": ["megahit", "rnaspades", "trinity", "spades"],
	"outdir": "/media/vini8cs/HD_vinicius1/benchmark/results",
	"host_fasta": "",
	"minsize": 500,
	"samples": [
		{
			"sample_accession": "SRR9705234",
			"sample_host": "'Apis mellifera'"
		},
		{
			"sample_accession": "SRR32267259",
			"sample_host": "'Homo sapiens'"
		}
	]
}
```
where:

- `assembly_tool`: List of assembly tools to reconstruct genomes or transcriptomes from sequencing data.
- `outdir`: Output directory for results.
- `host_fasta`: Path to a FASTA file containing the host genome sequence. If not provided, `sample_host` will be used to download the host genome.
- `minsize`: Minimum contig length (in base pairs) to be considered in the assembly process.
- `samples`: List of sequencing samples, each with:
		- `sample_accession`: SRA identifier for the sequencing data.
		- `sample_host`: Host organism from which the sample was obtained.

##  3. <a name='PipelineOverview'></a>Pipeline Overview

The pipeline consists of several modules and subworkflows to process metagenomic samples:

- **Download and Clean**: Downloads sequencing data and performs quality control.
- **Mapping**: Maps the cleaned reads to reference genomes.
- **Assembly**: Assembles the mapped reads into contigs.
- **Virus Detection**: Identifies viral sequences from the assembled contigs.
- **Clustering and Filtering**: Clusters contigs and filters based on identity and word size.
- **Viral Annotation**: Annotates viral contigs using external databases (e.g., RVDB, Genomad, DIAMOND, CheckV).
- **Reporting**: Generates comprehensive analysis reports.

##  4. <a name='Configuration'></a>Configuration

The pipeline can be configured using the `params.config` file. Key parameters include:

- `outdir`: Output directory for pipeline results.
- `TAXONKIT_DATABASE`: Path to the TaxonKit database directory.
- `GENOMAD_DATABASE`: Path to the Genomad database directory.
- `DIAMOND_DATABASE`: Path to the DIAMOND database file.
- `CHECKV_DATABASE`: Path to the CheckV database folder.
- `VIRSORTER2_DATABASE`: Path to the VirSorter2 database folder.
- `EMAIL`: Email address for NCBI notifications.
- `hisat2_build_memory`: Memory allocated for building HISAT2 indices (default: `4 GB`).
- `cpus_total`: Total number of CPUs available for the pipeline (default: `32`).
- `memory_max`: Maximum amount of memory available for the pipeline (default: `90`).

> **Note:** You do not need to specify paths to existing databases. Simply provide the directory where you want each database to be stored or the filename, and the pipeline will automatically download and set up the required databases for you.

##  5. <a name='Parameters'></a>Parameters

Additional parameters for fine-tuning the pipeline:

- `publish_dir_mode`: How output files are published (`copy` by default).
- `debug`: Enable debug mode (`false` by default).
- `save_unaligned_host_fastq`: Save unaligned host FASTQ files (`false` by default).
- `RVDB_LINK`: URL to the RVDB protein database (default: `https://rvdb-prot.pasteur.fr/files/U-RVDBv29.0-prot_clustered.fasta.xz`). You can use either the clustered or unclustered version, but it is recommended to always use the latest clustered release for optimal performance and accuracy.
- `virsort2_minsize`: Minimum contig size for VirSorter2 (default: `1500` bp).
- `virsorter2_virus_groups`: Virus groups for VirSorter2 (`'dsDNAphage,NCLDV,RNA,ssDNA,lavidaviridae'`).
- `virsorter2_minscore`: Minimum score threshold for VirSorter2 (`0.5`).
- `cd_hit_word_size`: Word size for CD-HIT clustering (`9`).
- `cd_hit_identity`: Sequence identity threshold for CD-HIT clustering (`0.99`).

##  6. <a name='Output'></a>Output

The pipeline generates various output files, including:

- Quality control reports
- Mapped reads
- Assembled contigs
- Identified viral sequences
- Clustered and filtered contigs
- Viral annotation results
- Comprehensive analysis reports

##  7. <a name='RunningonGoogleCloudPlatformGCP'></a>Running on Google Cloud Platform (GCP)

To run PandoraVirus on GCP, use the `gcp` profile, which configures the pipeline to use Google Batch and cloud storage. Before running, upload all required databases to your Google Cloud Storage (GCS) bucket, as the pipeline will not download them automatically in this mode.

###  7.1. <a name='Examplecommand'></a>Example command

```bash
nextflow run main.nf -profile gcp -params-file <path/to/json_file> [-bg]
```

###  7.2. <a name='Requiredchangesinparams.config'></a>Required changes in `params.config`

Update the following parameters to point to your GCS buckets and GCP project:

- `TAXONKIT_DATABASE`: Path to the TaxonKit database directory in your GCS bucket (e.g., `gs://pandoravirus-gcp-database/.taxonkit`).
- `GENOMAD_DATABASE`: Path to the Genomad database directory in your GCS bucket (e.g., `gs://pandoravirus-gcp-database/genomad/genomad_db`).
- `DIAMOND_DATABASE`: Path to the DIAMOND database file in your GCS bucket (e.g., `gs://pandoravirus-gcp-database/rvdb/RVDB.dmnd`).
- `CHECKV_DATABASE`: Path to the CheckV database folder in your GCS bucket (e.g., `gs://pandoravirus-gcp-database/checkv/checkv_db/checkv-db-v1.5`).
- `VIRSORTER2_DATABASE`: Path to the VirSorter2 database folder in your GCS bucket (e.g., `gs://pandoravirus-gcp-database/virsorter_database`).
- `EMAIL`: Your email address for NCBI notifications.
- `hisat2_build_memory`: Memory allocated for building HISAT2 indices (default: `4 GB`).
- `cpus_total`: Total number of CPUs available for the pipeline (default: `32`).
- `memory_max`: Maximum amount of memory available for the pipeline (default: `90`).
- `PROJECT`: Your Google Cloud project ID.
- `REGION`: Your Google Cloud region.
- `spot`: Whether to use preemptible (spot) instances (`false` by default).
- `WORKDIR`: Path to the working directory in your GCS bucket for pipeline intermediate files (e.g., `gs://pandoravirus-workdir/workdir`).

**Note:** Replace the example values with your actual GCP project, region, and bucket paths. Ensure all referenced databases are uploaded to GCS before running the pipeline.

##  8. <a name='Contributing'></a>Contributing

Contributions are welcome! Please submit a pull request or open an issue to discuss any changes.

##  9. <a name='License'></a>License

This project is licensed under the MIT License. See the LICENSE file for details.
