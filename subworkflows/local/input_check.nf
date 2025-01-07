workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    ch_versions = Channel.empty()

    // Create channel from input file
    ch_input = Channel.fromPath(samplesheet)
        .splitCsv(header:true, sep:',')
        .map { row -> 
            def meta = [:]
            meta.id = row.sample
            meta.single_end = true // Long reads are typically single-end
            meta.instrument_platform = row.instrument_platform ?: 'OXFORD_NANOPORE' // Default to ONT if not specified

            def reads = file(row.fastq, checkIfExists: true)

            return [ meta, reads ]
        }

    // Validate inputs
    ch_input = ch_input.map { meta, reads ->
        if (meta.instrument_platform != 'OXFORD_NANOPORE' && meta.instrument_platform != 'PACBIO') {
            error "ERROR: Unsupported instrument platform. Must be either 'OXFORD_NANOPORE' or 'PACBIO'. Found: ${meta.instrument_platform}"
        }
        if (!reads.name.endsWith('.fastq.gz') && !reads.name.endsWith('.fq.gz')) {
            error "ERROR: Long read files must be gzipped FASTQ. Found: ${reads}"
        }
        return [ meta, reads ]
    }

    emit:
    reads    = ch_input // channel: [ val(meta), path(reads) ]
    versions = ch_versions // channel: [ versions.yml ]
}