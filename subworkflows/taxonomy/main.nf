include { CAP3 } from '../../modules/local/cap3/main'
include { DIAMOND_BLASTX } from '../../modules/nf-core/diamond/blastx/main' 
include { XZ_DECOMPRESS } from '../../modules/nf-core/xz/decompress/main'
include { PROCESSRVDB } from '../../modules/local/processrvdb/main'
include { DIAMOND_MAKEDB } from '../../modules/nf-core/diamond/makedb/main'
include { PYTAXONKIT_LCA } from '../../modules/local/pytaxonkit/lca/main'
include { RNAVIRUS_FIND } from '../../modules/local/rnavirus_find/main'
include { SEQTK_SUBSEQ } from '../../modules/nf-core/seqtk/subseq/main'
include { SEQKIT_RMDUP } from '../../modules/nf-core/seqkit/rmdup/main'
include { CHECKV_DOWNLOADDATABASE } from '../../modules/nf-core/checkv/downloaddatabase/main'
include { CHECKV_ENDTOEND } from '../../modules/nf-core/checkv/endtoend/main'
include { GENOMAD_ENDTOEND } from '../../modules/nf-core/genomad/endtoend/main'
include { GENOMAD_DOWNLOAD } from '../../modules/nf-core/genomad/download/main'
include { DownloadDatabase } from '../../modules/local/downloaddatabase/main'
include { PROCESS_TAXDUMP as PROCESS_TAXDUMP_DIAMOND } from '../../subworkflows/process_taxdump/main'
include { GUNZIP as GUNZIP_DESCOMPACT } from '../../modules/nf-core/gunzip/main'


workflow  TAXONOMY {
    take:
        filtered_merged_fasta_ch
        taxonkit_database_ch
    main:
        
        GenomadDatabasefileExists = file(params.GENOMAD_DATABASE, checkIfExists: false)
        if (GenomadDatabasefileExists.exists()) {
            genomad_database_ch = Channel.fromPath(params.GENOMAD_DATABASE)
        } else {
            GENOMAD_DOWNLOAD()
            genomad_database_ch = GENOMAD_DOWNLOAD.out.genomad_db
        }

        GENOMAD_ENDTOEND(filtered_merged_fasta_ch, genomad_database_ch)
        GENOMAD_ENDTOEND.out.virus_genes
        GENOMAD_ENDTOEND.out.virus_proteins

        aligned_virus_fasta = CAP3(GENOMAD_ENDTOEND.out.virus_fasta)

        DiamondDatabasefileExists = file(params.DIAMOND_DATABASE, checkIfExists: false)
        if (DiamondDatabasefileExists.exists()) {
            diamond_db_ch = Channel.fromPath(params.DIAMOND_DATABASE).map {file ->
                tuple([id: "db"], file)}.collect()
        } else {
            
            rvdb_db = DownloadDatabase(params.RVDB_LINK)
            rvdb_db_ch = Channel.fromPath(rvdb_db).map {file -> tuple([id: "rvdb_db"], file)}
            decompressed_rvdb_ch = XZ_DECOMPRESS(rvdb_db_ch)
            processed_rvdb_ch = PROCESSRVDB(decompressed_rvdb_ch.file)
            
            taxdump_output = PROCESS_TAXDUMP_DIAMOND()
            prot_accession2taxid_file = DownloadDatabase("https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/prot.accession2taxid.gz")
            prot_accession2taxid_ch = Channel.fromPath(prot_accession2taxid_file)

            DIAMOND_MAKEDB(
                processed_rvdb_ch,
                prot_accession2taxid_ch,
                taxdump_output.nodes_ch.map{_meta, files -> files},
                taxdump_output.names_ch.map{_meta, files -> files}
            )

            diamond_db_ch = DIAMOND_MAKEDB.out.db.collect()
        }

        DIAMOND_BLASTX(aligned_virus_fasta.viral_transcripts, diamond_db_ch, "txt", "qseqid qlen sseqid slen stitle pident qcovhsp evalue bitscore staxids")

        taxonomic_dataframe = PYTAXONKIT_LCA(
            DIAMOND_BLASTX.out.txt, 
            taxonkit_database_ch.map{_meta, files -> files}.collect()
        )

        ictv_database = DownloadDatabase("https://ictv.global/sites/default/files/VMR/VMR_MSL40.v1.20250307.xlsx")
        ictv_database_ch = Channel.fromPath(ictv_database).collect()
        rna_virus_tsv_ch = RNAVIRUS_FIND(taxonomic_dataframe, ictv_database_ch)
        // TODO: Corrigir SEQTK_SUBSEQ in nf-core (fazer um PR) adicionando os dois valores ao mesmo meta

        queries_ch = rna_virus_tsv_ch.virus_queries
            .combine(aligned_virus_fasta.viral_transcripts, by: 0)       
       
        extracted_virus_sequeces_ch = SEQTK_SUBSEQ(queries_ch.map{meta, _filter_list, fasta -> tuple(meta, fasta)}, queries_ch.map{_meta, filter_list, _fasta -> filter_list})
        
        non_duplicated_sequences_ch = SEQKIT_RMDUP(extracted_virus_sequeces_ch.sequences)

        CheckvDatabasefileExists = file(params.CHECKV_DATABASE, checkIfExists: false)
        if (CheckvDatabasefileExists.exists()) {
        checkv_database_ch = Channel
            .fromPath("${params.CHECKV_DATABASE}/*", type: 'dir')
            .filter { file -> file.isDirectory() && file.name == 'genome_db' }
        } else {
            CHECKV_DOWNLOADDATABASE()
            checkv_database_ch = CHECKV_DOWNLOADDATABASE.out.checkv_db
        }

        extracted_fasta_ch = GUNZIP_DESCOMPACT(non_duplicated_sequences_ch.fastx).gunzip
        
        checkv_output = CHECKV_ENDTOEND(extracted_fasta_ch, checkv_database_ch.collect())
    emit:
        quality_summary = checkv_output.quality_summary
        rna_virus_sequences = non_duplicated_sequences_ch.fastx
        virus_table = rna_virus_tsv_ch.virus_table
}
