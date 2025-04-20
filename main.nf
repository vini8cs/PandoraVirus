include { DOWNLOAD_AND_CLEAN } from './subworkflows/download_and_clean/main'
include { MAPPING } from './subworkflows/mapping/main'
include { ASSEMBLY } from './subworkflows/assembly/main'
include {TAXONOMY } from './subworkflows/taxonomy/main'
include { METAGENOMICS } from './subworkflows/metagenomics/main'

workflow {
    samples_ch = Channel
    .fromList(params.samples)
    .map {
        sample -> tuple([
            id: sample.sample_accession,
            host: sample?.sample_host ?: "", 
            single_end: true //It's a workaround because SRATOOLS_FASTERQDUMP 
            //creates the file inside the folder, and pigz finds it. 
            //While an argument can change the output folder, a condition forces it back if it's a paired-end file.
            ], sample.sample_accession)
    }

    filtered_fastq = DOWNLOAD_AND_CLEAN(samples_ch)

    mapped_fastq = MAPPING(samples_ch, filtered_fastq)

    assembly_ch = ASSEMBLY(mapped_fastq)

    if (params.BLASTN_DATABASE) {
       METAGENOMICS(assembly_ch.fasta)
    } 
    
    filtered_merged_fasta_ch = assembly_ch.fasta
    
    TAXONOMY(filtered_merged_fasta_ch)
    
}
    
