include { CHECKV_DOWNLOADDATABASE } from '../../modules/nf-core/checkv/downloaddatabase/main'

workflow DOWNLOAD_CHECKV_DATABASE {

    take:
        checkv_database_path

    main:
        CheckvDatabasefileExists = file(checkv_database_path, checkIfExists: false)
        if (CheckvDatabasefileExists.exists() || !workflow.profile.contains('gcp')) {
        checkv_database_ch = Channel
            .fromPath("${checkv_database_path}/*", type: 'dir')
            .filter { file -> file.isDirectory() && file.name == 'genome_db' }
        } else {
            CHECKV_DOWNLOADDATABASE()
            checkv_database_ch = CHECKV_DOWNLOADDATABASE.out.checkv_db
        }

    emit:
        checkv_database_ch
}
