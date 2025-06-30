include { GENOMAD_DOWNLOAD } from '../../modules/nf-core/genomad/download/main'

workflow DOWNLOAD_GENOMAD_DATABASE {
    take:
        genomad_database_path 
    main:
        GenomadDatabasefileExists = file(genomad_database_path, checkIfExists: false)
        if (GenomadDatabasefileExists.exists() || !workflow.profile.contains('gcp')) {
            genomad_database_ch = Channel.fromPath(genomad_database_path)
                .map { path -> path.resolve('genomad_db') }
                .filter { it.exists() && it.isDirectory() }
                .ifEmpty { genomad_database_path }
        } else {
            GENOMAD_DOWNLOAD()
            genomad_database_ch = GENOMAD_DOWNLOAD.out.genomad_db
                .map { path -> path.resolve('genomad_db') }
        }
    emit:
        genomad_database_ch
}
