process FASTP_CREATEADAPTERSFILE {
    tag "$meta.id"
    label 'process_low'
    debug params.debug
    container 'quay.io/nf-core/ubuntu:20.04'
    
    input:
    tuple val(meta), path(fastq)
    
    output:
    path('adapter_sequences.fasta'), emit: adapter_sequences
    script:
    """
        declare -A adapter_sequences
        adapter_sequences=(
            ["Illumina_Universal_Adapter"]="AGATCGGAAGAG"
            ["Illumina_Small_RNA_3_Adapter"]="TGGAATTCTCGG"
            ["Illumina_Small_RNA_5_Adapter"]="GATCGTCGGACT"
            ["Nextera_Transposase_Sequence"]="CTGTCTCTTATA"
        )

        {
            for adapter_name in "\${!adapter_sequences[@]}"; do
                echo ">\${adapter_name}"
                echo "\${adapter_sequences[\$adapter_name]}"
            done
        } > adapter_sequences.fasta
    """
    stub:
    """
        declare -A adapter_sequences
        adapter_sequences=(
            ["Illumina_Universal_Adapter"]="AGATCGGAAGAG"
            ["Illumina_Small_RNA_3_Adapter"]="TGGAATTCTCGG"
            ["Illumina_Small_RNA_5_Adapter"]="GATCGTCGGACT"
            ["Nextera_Transposase_Sequence"]="CTGTCTCTTATA"
        )

        {
            for adapter_name in "\${!adapter_sequences[@]}"; do
                echo ">\${adapter_name}"
                echo "\${adapter_sequences[\$adapter_name]}"
            done
        } > adapter_sequences.fasta
    """
}
