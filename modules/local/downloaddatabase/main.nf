def DownloadDatabase(link) {
    def database
    if (workflow.profile.contains('stub')) {
        database = new URL(link).getPath().tokenize('/')[-1]
        new File("/tmp/${database}").text = ''
    } else {
        database = file(link)
    }
    return database
}
