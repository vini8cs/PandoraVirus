include { SRATOOLS_PREFETCH } from './modules/nf-core/sratools/prefetch/main'
include { SRATOOLS_FASTERQDUMP } from './modules/nf-core/sratools/fasterqdump/main'
include { cleanMeta } from './modules/local/cleanmeta/main'
include { FASTP_CREATEADAPTERSFILE } from './modules/local/fastp/createadaptersfile/main'
include { FASTP } from './modules/nf-core/fastp/main'
include { PYTAXONKIT_GETAXONOMY } from './modules/local/pytaxonkit/getaxonomy/main'
include { NCBIDATASETS_DOWNLOAD } from './modules/local/ncbidatasets/download/main'
include { readFile } from './modules/local/readfile/main'
include { HISAT2_BUILD } from './modules/nf-core/hisat2/build/main'
include { HISAT2_ALIGN } from './modules/nf-core/hisat2/align/main'
include { MEGAHIT } from './modules/nf-core/megahit/main'
include { TRINITY } from './modules/nf-core/trinity/main' 
include { CAT_FASTA } from './modules/local/cat/fasta/main'
include { CDHIT_CDHITEST } from './modules/nf-core/cdhit/cdhitest/main'
include { SEQTK_SEQ } from './modules/nf-core/seqtk/seq/main'
include { QUAST } from './modules/nf-core/quast/main'
include { GENOMAD_ENDTOEND } from './modules/nf-core/genomad/endtoend/main'
include { CAP3 } from './modules/local/cap3/main'
include { DIAMOND_BLASTX } from './modules/nf-core/diamond/blastx/main' 
include { XZ_DECOMPRESS } from './modules/nf-core/xz/decompress/main'
include { PROCESSRVDB } from './modules/local/processrvdb/main'
include { UNTAR } from './modules/nf-core/untar/main'
include { DIAMOND_MAKEDB } from './modules/nf-core/diamond/makedb/main'
include { NCBIGENOMEDOWNLOAD } from './modules/nf-core/ncbigenomedownload/main'
include { WRITETOFILE } from './modules/local/writetofile/main'
include { PYTAXONKIT_LCA } from './modules/local/pytaxonkit/lca/main'
include { GUNZIP } from './modules/nf-core/gunzip/main'
include { 
    SPADES;
    SPADES as RNA_SPADES ;
    SPADES as META_SPADES ;
    SPADES as CORONA_SPADES ;
} from './modules/nf-core/spades/main'

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

    sra_ch = SRATOOLS_PREFETCH(samples_ch, [], [])
    SRATOOLS_FASTERQDUMP(sra_ch.sra, [], [])

    fastqc_ch = SRATOOLS_FASTERQDUMP.out.reads.map {
        meta, reads -> 
        def new_single_end = reads instanceof List ? false : true
        tuple([id: meta.id, single_end: new_single_end], reads)
    }

    adapter_sequences_ch = FASTP_CREATEADAPTERSFILE(fastqc_ch)
    
    filtered_fastq = FASTP(
        fastqc_ch,
        adapter_sequences_ch,
        Channel.value(false),
        Channel.value(false),
        Channel.value(false)
    )

    if (!params.host_fasta) {
        lineage_info_ch = PYTAXONKIT_GETAXONOMY(samples_ch.map{
        meta, _file -> tuple(meta, meta.host)})

        lineage = readFile(lineage_info_ch)

        lineages = lineage.species
            .concat(lineage.genus)
            .concat(lineage.family)
            .concat(lineage.order)

        lineages_filtered_ch = lineages.filter { _meta, file -> file != "Indeterminated" }
            .groupTuple()
            .map { meta, files -> tuple(meta, files[0]) }
        
        taxid_file = WRITETOFILE(lineages_filtered_ch)

        NCBIGENOMEDOWNLOAD(
            taxid_file.map { meta, _file -> meta },
            [],
            taxid_file.map { _meta, file -> file },
            "all"
        )
        fna_gz = NCBIGENOMEDOWNLOAD.out.fna
            .transpose()
            .filter { _meta, files -> !files.name.contains("rna") && !files.name.contains("cds")}.first()

        GUNZIP(fna_gz)

        fna = GUNZIP.out.gunzip

    } else {
        fna = Channel.fromPath(params.host_fasta)
            .map {file -> tuple([id: "host"], file)}
        }
    
    database_ch = HISAT2_BUILD(fna, [[],[]], [[],[]])
    HISAT2_ALIGN(filtered_fastq.reads, database_ch.index, [[],[]])
    mapped_fastq = HISAT2_ALIGN.out.fastq

    if ("megahit" in params.assembly_tool) {
        MEGAHIT(
            mapped_fastq.map { meta, file -> 
            meta.single_end ? tuple(meta, file, []) : tuple(meta, file[0], file[1])
        })
        contigs_megahit = MEGAHIT.out.contigs
    } else {
        contigs_megahit = Channel.empty()
    }

    if ("spades" in params.assembly_tool) {
        SPADES(mapped_fastq.map{meta, file -> tuple(meta, file, [], [])}, [], [])
        spades_contigs = SPADES.out.contigs
    } else {
        spades_contigs = Channel.empty()
    }
    
    if ("rnaspades" in params.assembly_tool) {
        RNA_SPADES(mapped_fastq.map{meta, file -> tuple(meta, file,[], [])}, [], [])
        rna_spades_contigs = RNA_SPADES.out.contigs
    } else {
        rna_spades_contigs = Channel.empty()
    }

    if ("trinity" in params.assembly_tool) {
        TRINITY(mapped_fastq)
        trinity_contigs = TRINITY.out.transcript_fasta
    } else {
        trinity_contigs = Channel.empty()
    }

    if ("metaspades" in params.assembly_tool) {
        META_SPADES(mapped_fastq.map{meta, file -> tuple(meta, file, [], [])}, [], [])
        metaspades_contigs = SPADES.out.contigs
    } else {
        metaspades_contigs = Channel.empty()
    }

    if ("coronaspades" in params.assembly_tool) {
        CORONA_SPADES(mapped_fastq.map{meta, file -> tuple(meta, file, [], [])}, [], [])
        coronaspades_contigs = SPADES.out.contigs
    } else {
        coronaspades_contigs = Channel.empty()
    }

    all_contigs_ch = contigs_megahit
        .concat(spades_contigs)
        .concat(rna_spades_contigs)
        .concat(trinity_contigs)
        .concat(metaspades_contigs)
        .concat(coronaspades_contigs)
        
    //talvez tenha que descompactar antes

    merged_contigs_ch = CAT_FASTA(all_contigs_ch.groupTuple())
    clustered_fasta_ch = CDHIT_CDHITEST(merged_contigs_ch.contigs)
    filtered_merged_fasta_ch = SEQTK_SEQ(clustered_fasta_ch.fasta)
    
    QUAST(all_contigs_ch
        .concat(filtered_merged_fasta_ch.fastx)
        .groupTuple(),
        [[],[]], [[], []] )
    
    QUAST.out.tsv

    GENOMAD_ENDTOEND(filtered_merged_fasta_ch.fastx, params.GENOMAD_DATABASE)

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
        nodes_ch = tar_ch.untar.filter{_meta, file -> file == "nodes.dmp"}
        names_ch = tar_ch.untar.filter{_meta, file -> file == "names.dmp"}

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
    
