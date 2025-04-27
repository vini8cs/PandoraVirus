include { BLAST_UPDATEBLASTDB } from '../../modules/nf-core/blast/updateblastdb/main'
include { BLAST_BLASTN } from '../../modules/nf-core/blast/blastn/main'
include { PYTAXONKIT_LCA as PYTAXONKIT_LCA_METAGENOMICS } from '../../modules/local/pytaxonkit/lca/main'

workflow METAGENOMICS {
    take:
        fasta
        taxonkit_database_ch
    main:
        BlastDatabasefileExists = file(params.BLASTN_DATABASE, checkIfExists: false)
        if (BlastDatabasefileExists.exists()) {
            blast_db = Channel.fromPath(params.BLASTN_DATABASE).map { file ->
                tuple([id: "db"], file)
            }
        } else {
            blast_name = Channel.of(params.BLASTN_DATABASE_NAME).map { file ->
                tuple([id: "db"], file)
            }
            BLAST_UPDATEBLASTDB(blast_name)
            blast_db = BLAST_UPDATEBLASTDB.out.db
        }

        report_output_ch = BLAST_BLASTN(fasta, blast_db)

        PYTAXONKIT_LCA_METAGENOMICS(
            report_output_ch,
            taxonkit_database_ch
        )

        
    emit:
        fasta
}
