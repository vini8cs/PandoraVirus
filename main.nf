include { DOWNLOAD_AND_CLEAN } from './subworkflows/download_and_clean/main'
include { MAPPING } from './subworkflows/mapping/main'
include { ASSEMBLY } from './subworkflows/assembly/main'
include { GENOMAD_ENDTOEND } from './modules/nf-core/genomad/endtoend/main'
include { CAP3 } from './modules/local/cap3/main'
include { DIAMOND_BLASTX } from './modules/nf-core/diamond/blastx/main' 
include { XZ_DECOMPRESS } from './modules/nf-core/xz/decompress/main'
include { PROCESSRVDB } from './modules/local/processrvdb/main'
include { UNTAR } from './modules/nf-core/untar/main'
include { DIAMOND_MAKEDB } from './modules/nf-core/diamond/makedb/main'
include { FINDDMPFILES } from './modules/local/finddmpfiles/main'
include { PYTAXONKIT_LCA } from './modules/local/pytaxonkit/lca/main'



workflow {
    samples_ch = Channel
    .fromList(params.samples)
    .map {
        sample -> tuple([
            id: sample.sample_accession,
            host: sample.sample_host, 
            single_end: true //It's a workaround because SRATOOLS_FASTERQDUMP 
            //creates the file inside the folder, and pigz finds it. 
            //While an argument can change the output folder, a condition forces it back if it's a paired-end file.
            ], sample.sample_accession)
    }

    filtered_fastq = DOWNLOAD_AND_CLEAN(samples_ch)

    mapped_fastq = MAPPING(samples_ch, filtered_fastq)

    assembly_ch = ASSEMBLY(mapped_fastq)
    
    filtered_merged_fasta_ch = assembly_ch.fasta
    
    GENOMAD_ENDTOEND(filtered_merged_fasta_ch, params.GENOMAD_DATABASE)

    GENOMAD_ENDTOEND.out.virus_genes
    GENOMAD_ENDTOEND.out.virus_proteins

    aligned_virus_fasta = CAP3(GENOMAD_ENDTOEND.out.virus_fasta)
    
    DiamondDatabasefileExists = file(params.DIAMOND_DATABASE, checkIfExists: false)
    if (DiamondDatabasefileExists.exists()) {
        diamond_db_ch = Channel.fromPath(params.DIAMOND_DATABASE).map {file ->
            tuple([id: "db"], file)}
    } else {
        rvdb_db = file(params.RVDB_LINK)
        rvdb_db_ch = Channel.fromPath(rvdb_db).map {file -> tuple([id: "rvdb_db"], file)}
        processed_rvdb_ch = XZ_DECOMPRESS(rvdb_db_ch)
        
        taxdump_file = file("https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz")
        taxdump_ch = Channel.fromPath(taxdump_file).map {file -> tuple([id: "taxdump"], file)}
        tar_ch = UNTAR(taxdump_ch)

        FINDDMPFILES(tar_ch.untar)

        nodes_ch = FINDDMPFILES.out.nodes
        names_ch = FINDDMPFILES.out.names

        prot_accession2taxid_file = file("https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid/prot.accession2taxid.gz")
        prot_accession2taxid_ch = Channel.fromPath(prot_accession2taxid_file).map{file -> tuple([id: "prot_accession2taxid"], file)}

        DIAMOND_MAKEDB(
            processed_rvdb_ch.file,
            nodes_ch,
            names_ch,
            prot_accession2taxid_ch
        )

        diamond_db_ch = DIAMOND_MAKEDB.out.db

    }
    
    DIAMOND_BLASTX(aligned_virus_fasta.viral_transcripts, diamond_db_ch, "txt", "qseqid qlen sseqid slen stitle pident qcovhsp evalue bitscore")
    
    PYTAXONKIT_LCA(DIAMOND_BLASTX.out.txt)
}
    
