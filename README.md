
# PandoraVirus

PandoraVirus is a Nextflow pipeline designed to detect and identify RNA viruses from public data. This pipeline processes metagenomic samples to identify viral sequences and provides comprehensive results.

Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Pipeline Overview](#pipeline-overview)
- [Configuration](#configuration)
- [Output](#output)
- [License](#license)

## Installation

### Prerequisites
- [Nextflow](https://www.nextflow.io/)
- [Docker](https://www.docker.com/) or [Singularity](https://sylabs.io/singularity/)

### Install Docker

```bash
curl -fsSL https://get.docker.com | sudo sh
```

### Remove Docker

```bash
sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
```

### Setup Docker

```bash
sudo groupadd docker
sudo usermod -aG docker $USER
docker login
```

## Usage

To run the pipeline, use the following command:

```bash
nextflow run main.nf -params-file <path/to/json_file> [--profile "stub" -stub ] -bg
```
- `json.file` to insert your data:

```JSON
{
	"assembly_tool": ["megahit","rnaspades", "trinity", "spades"],
	"outdir": "/media/vini8cs/HD_vinicius1/benchmark/results",
	"host_fasta" : "",
	"minsize" : 500,
	"samples": [
	  {  
		"sample_accession": "SRR9705234",
        "sample_host" : "'Apis mellifera'"
	  },
	  {  
		"sample_accession": "SRR32267259",
        "sample_host": "'Homo sapiens'"
	  }
	]
  }
```
where:

- `assembly_tool`: A list of assembly tools that can be used to reconstruct genomes or transcriptomes from sequencing data.

- `outdir`: Specifies the output directory where the results will be saved

- `host_fasta`: Represent the path to a FASTA file containing the host genome sequence. If it's not provided, it will used `sample_host`to download host genome.

- `minsize`: Defines the minimum contig length (in base pairs) to be considered in the assembly process.

- `samples`: A list of dictionaries, where each dictionary represents a sequencing sample. Each sample contains:

    - `sample_accession`: The unique identifier for the sequencing data in the SRA (Sequence Read Archive) database.

    - `sample_host`: The host organism from which the sample was obtained.

## Pipeline Overview

The pipeline consists of several modules and subworkflows to process metagenomic samples:

- Download and Clean: Downloads sequencing data and performs quality control.
- Mapping: Maps the cleaned reads to reference genomes.
- Assembly: Assembles the mapped reads into contigs.
- Virus Detection: Identifies viral sequences from the assembled contigs.

## Configuration

The pipeline can be configured using the `params.config` file. Key parameters include:

- `outdir`: Specifies the output directory where the results of the pipeline will be stored.

- `TAXONKIT_DATABASE`: Path to the TaxonKit database directory, which is used for taxonomic classification. If the directory doesn't have any file, they will be downloaded automatically.

- `GENOMAD_DATABASE`: Path to the Genomad database, which is used for genome annotation. If the directory doesn't have any file, they will be downloaded automatically.

- `DIAMOND_DATABASE`: Path to the DIAMOND database, which is used for sequence alignment. If the file doesn't exist, it will be downloaded automatically.

- `CHECKV_DATABASE`: Path to the CheckV database, which is used for genome annotation. If the directory doesn't have any file, they will be downloaded automatically.

- `hisat2_build_memory`: Specifies the amount of memory allocated for building HISAT2 indices.

- `cpus_total`: Specifies the total number of CPUs available for the pipeline.

- `memory_max`: Specifies the maximum amount of memory available for the pipeline. 

## Output

The pipeline generates various output files, including:

- Quality control reports
- Mapped reads
- Assembled contigs
- Identified viral sequences
- Comprehensive analysis reports
- Contributing

Contributions are welcome! Please submit a pull request or open an issue to discuss any changes.

## License
This project is licensed under the MIT License. See the LICENSE file for details.
