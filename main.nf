include { DOWNLOAD_AND_CLEAN } from './subworkflows/download_and_clean/main'
include { MAPPING } from './subworkflows/mapping/main'
include { ASSEMBLY } from './subworkflows/assembly/main'
include { TAXONOMY } from './subworkflows/taxonomy/main'
include { PROCESS_TAXDUMP } from './subworkflows/process_taxdump/main'
include { PYTAXONKIT_CREATEDATABASE  } from './modules/local/pytaxonkit/createdatabase/main'


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

    TaxonkitDatabasefileExists = file(params.TAXONKIT_DATABASE, checkIfExists: false)
    if (TaxonkitDatabasefileExists.exists()) {
        taxonkit_database_ch = params.TAXONKIT_DATABASE
    } else {
        taxdump_output = PROCESS_TAXDUMP()
        taxonkit_database_ch = PYTAXONKIT_CREATEDATABASE(taxdump_output.dmp_ch).collect()
    }

    filtered_fastq = DOWNLOAD_AND_CLEAN(samples_ch)

    mapped_fastq = MAPPING(samples_ch, filtered_fastq, taxonkit_database_ch)

    assembly_ch = ASSEMBLY(mapped_fastq)
    
    filtered_merged_fasta_ch = assembly_ch.fasta
    
    TAXONOMY(filtered_merged_fasta_ch, taxonkit_database_ch)
    
}
    
