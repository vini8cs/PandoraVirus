include { BLAST_UPDATEBLASTDB } from '../../modules/nf-core/blast/updateblastdb/main'

workflow METAGENOMICS {
    take:
        fasta
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

        
    emit:
        fasta
}
