include { MEGAHIT } from '../../modules/nf-core/megahit/main'
include { TRINITY } from '../../modules/nf-core/trinity/main' 
include { CAT_FASTA } from '../../modules/local/cat/fasta/main'
include { CDHIT_CDHITEST } from '../../modules/nf-core/cdhit/cdhitest/main'
include { SEQTK_SEQ } from '../../modules/nf-core/seqtk/seq/main'
include { QUAST } from '../../modules/nf-core/quast/main'
include { 
    SPADES;
    SPADES as RNA_SPADES ;
    SPADES as META_SPADES ;
    SPADES as CORONA_SPADES ;
} from '../../modules/nf-core/spades/main'

workflow ASSEMBLY {
    take:
        mapped_fastq
    main:
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
            paired_fastq = mapped_fastq.filter { meta, _file -> meta.single_end == false }
            META_SPADES(paired_fastq.map{meta, file -> tuple(meta, file, [], [])}, [], [])
            metaspades_contigs = META_SPADES.out.contigs
        } else {
            metaspades_contigs = Channel.empty()
        }

        if ("coronaspades" in params.assembly_tool) {
            CORONA_SPADES(mapped_fastq.map{meta, file -> tuple(meta, file, [], [])}, [], [])
            coronaspades_contigs = CORONA_SPADES.out.contigs
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

    emit:
        fasta = filtered_merged_fasta_ch.fastx
        assembly_report = QUAST.out.tsv

}
