include { CAP3 } from '../../modules/local/cap3/main'
include { DIAMOND_BLASTX } from '../../modules/nf-core/diamond/blastx/main' 
include { PYTAXONKIT_LCA } from '../../modules/local/pytaxonkit/lca/main'
include { RNAVIRUS_FIND } from '../../modules/local/rnavirus_find/main'
include { SEQTK_SUBSEQ } from '../../modules/local/seqtk/subseq/main'
include { SEQKIT_RMDUP } from '../../modules/nf-core/seqkit/rmdup/main'
include { CHECKV_ENDTOEND } from '../../modules/nf-core/checkv/endtoend/main'
include { GENOMAD_ENDTOEND } from '../../modules/nf-core/genomad/endtoend/main'
include { DownloadDatabase } from '../../modules/local/downloaddatabase/main'
include { GUNZIP as GUNZIP_DESCOMPACT } from '../../modules/nf-core/gunzip/main'
include { DOWNLOAD_GENOMAD_DATABASE } from '../../subworkflows/download_genomad_database/main'
include { DOWNLOAD_DIAMOND_DATABASE } from '../../subworkflows/download_diamond_database/main'
include { DOWNLOAD_CHECKV_DATABASE } from '../../subworkflows/download_checkv_database/main'
include { DOWNLOAD_VIRSORTER2_DATABASE } from '../../subworkflows/download_virsorter2_database/main'
include { VIRSORTER2_RUN } from '../../modules/local/virsorter2/run/main'
include { CDHIT_CDHITEST as CDHIT_VIRUS } from '../../modules/nf-core/cdhit/cdhitest/main'
include { CAT_FASTA } from '../../modules/local/cat/fasta/main'

workflow  TAXONOMY {
    take:
        filtered_merged_fasta_ch
        taxonkit_database_ch
    main:
        
        genomad_database_ch = DOWNLOAD_GENOMAD_DATABASE(params.GENOMAD_DATABASE)
        genomad_contigs_ch = GENOMAD_ENDTOEND(filtered_merged_fasta_ch, genomad_database_ch.collect()).virus_fasta

        virsoter2_database_ch = DOWNLOAD_VIRSORTER2_DATABASE(params.VIRSORTER2_DATABASE)
        virsorter2_database_ch = VIRSORTER2_RUN(filtered_merged_fasta_ch, virsoter2_database_ch.collect(), "all").virsorter_fasta

        merged_virus_contigs = CAT_FASTA(
            genomad_contigs_ch
                .concat(virsorter2_database_ch)
                .groupTuple()
        ).contigs
        
        clustered_virus_contigs = CDHIT_VIRUS(merged_virus_contigs).fasta

        aligned_virus_fasta = CAP3(clustered_virus_contigs)

        diamond_db_ch = DOWNLOAD_DIAMOND_DATABASE(params.DIAMOND_DATABASE, params.RVDB_LINK)

        DIAMOND_BLASTX(aligned_virus_fasta.viral_transcripts, diamond_db_ch, "txt", "qseqid qlen sseqid slen stitle pident qcovhsp evalue bitscore staxids")

        taxonomic_dataframe = PYTAXONKIT_LCA(
            DIAMOND_BLASTX.out.txt, 
            taxonkit_database_ch.map{_meta, files -> files}.collect()
        )

        ictv_database = DownloadDatabase("https://ictv.global/sites/default/files/VMR/VMR_MSL40.v1.20250307.xlsx")
        ictv_database_ch = Channel.fromPath(ictv_database).collect()
        
        rna_virus_tsv_ch = RNAVIRUS_FIND(taxonomic_dataframe, ictv_database_ch)

        queries_ch = rna_virus_tsv_ch.virus_queries
            .combine(aligned_virus_fasta.viral_transcripts, by: 0)       
       
        extracted_virus_sequeces_ch = SEQTK_SUBSEQ(queries_ch)
        
        non_duplicated_sequences_ch = SEQKIT_RMDUP(extracted_virus_sequeces_ch.sequences)
        extracted_fasta_ch = GUNZIP_DESCOMPACT(non_duplicated_sequences_ch.fastx).gunzip

        checkv_database_ch = DOWNLOAD_CHECKV_DATABASE(params.CHECKV_DATABASE)
        checkv_output = CHECKV_ENDTOEND(extracted_fasta_ch, checkv_database_ch.collect())
    emit:
        quality_summary = checkv_output.quality_summary
        rna_virus_sequences = extracted_fasta_ch
        virus_table = rna_virus_tsv_ch.virus_table
}
