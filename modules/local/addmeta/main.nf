def addMeta(reference_ch, new_item) {
    return reference_ch
        .map { meta, data, new_meta ->
            def meta_new = meta + [(new_item): new_meta.trim()]
            [meta_new, data]
        }
}
