include { CHECKV_DOWNLOADDATABASE } from '../../modules/nf-core/checkv/downloaddatabase/main'

workflow DOWNLOAD_CHECKV_DATABASE {

    take:
        checkv_database_path

    main:
        CheckvDatabasefileExists = file(checkv_database_path, checkIfExists: false)
        if (CheckvDatabasefileExists.exists() || !workflow.profile.contains('gcp')) {
        checkv_database_ch = Channel
            .fromPath(checkv_database_path)
            .map { path -> path.resolve('checkv-db-v1.5') }
            .filter { it.exists() && it.isDirectory() }
            .ifEmpty { checkv_database_path }
        } else {
            CHECKV_DOWNLOADDATABASE()
            checkv_database_ch = CHECKV_DOWNLOADDATABASE.out.checkv_db
                .map { path -> path.resolve('checkv-db-v1.5') }
        }

    emit:
        checkv_database_ch
}
