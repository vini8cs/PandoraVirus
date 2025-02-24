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
include { 
    SPADES;
    SPADES as RNA_SPADES ;
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
        
        NCBIDATASETS_DOWNLOAD(
            lineages_filtered_ch, Channel.value(params.host_dna_type)
        )
        fna = NCBIDATASETS_DOWNLOAD.out.fna.view()
    
    } else {
        host_fna = Channel.fromPath(params.host_fasta)
        }
    
    database_ch = HISAT2_BUILD(fna, [[],[]], [[],[]])
    HISAT2_ALIGN(filtered_fastq.reads, database_ch.index, [[],[]])
    mapped_fastq = HISAT2_ALIGN.out.fastq

    if ("megahit" in params.assembly_tool) {
        MEGAHIT(mapped_fastq.filter {meta, _file -> !meta.single_end})
        contigs_megahit = MEGAHIT.out.contigs
    }

    if ("spades" in params.assembly_tool) {
        SPADES(mapped_fastq.map{meta, file -> tuple(meta, file, [], [])}, [], [])
    } 
    
    if ("rnaspades" in params.assembly_tool) {
        RNA_SPADES(mapped_fastq.map{meta, file -> tuple(meta, file,[], [])}, [], [])
        rna_spades_contigs = RNA_SPADES.out.contigs.view()
    }
    
}
    
