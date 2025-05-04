include { MINIMAP2_ALIGN as MINIMAP2_POLISH_1 } from '../../modules/nf-core/minimap2/align/main'
//include { MINIMAP2_ALIGN as MINIMAP2_POLISH_2 } from '../../modules/nf-core/minimap2/align/main'
include { RACON as RACON_1 } from '../../modules/nf-core/racon/main'
//include { RACON as RACON_2 } from '../../modules/nf-core/racon/main'


/*workflow POLISH_ASSEMBLY {
    take:
    reads    // channel: [ [ meta ], [ reads ] ]  // Expecting compressed .gz files
    assembly // channel: [ [ meta ], [ assembly ] ]  // Expecting compressed .gz files

    main:
    ch_versions = Channel.empty()

    // Ensure input assemblies are in .gz format within the work directory
    ch_prepped_assembly = assembly.map { meta, assembly_file ->
        println "Debug: Preparing assembly for ${meta.id}"
        def final_assembly = file("${workDir}/${meta.id}.assembly.fasta.gz")

        if (!assembly_file.name.endsWith(".gz")) {
            println "Debug: Compressing assembly file for ${meta.id}"
            "gzip -c ${assembly_file} > ${final_assembly}".execute().waitFor()
        } else {
            assembly_file.copyTo(final_assembly)
        }

        println "Debug: Prepared assembly file for ${meta.id}: ${final_assembly.toAbsolutePath()}"
        assert final_assembly.exists() : "Assembly file ${final_assembly.toAbsolutePath()} does not exist"

        return [meta, final_assembly]
    }

    // First Minimap2 alignment
    MINIMAP2_POLISH_1(reads, ch_prepped_assembly.map { it[1] }, false, true, false)
    ch_versions = ch_versions.mix(MINIMAP2_POLISH_1.out.versions.first())
 
     // Add a small delay to allow for file system operations
    ch_minimap2_output = MINIMAP2_POLISH_1.out.paf
        .map { it -> sleep(100); it }

    
    // Debug: View Minimap2 output
    MINIMAP2_POLISH_1.out.paf.view { meta, paf -> "Debug: MINIMAP2_POLISH_1 output for ${meta.id}: ${paf}" }

    ch_racon_input_1 = reads.join(ch_prepped_assembly)
    .join(MINIMAP2_POLISH_1.out.paf.filter { it[1].size() > 0 })  // Ensures only valid PAF files are passed
    .map { meta, reads, assembly, paf -> 
        println "Debug: RACON_1 input for ${meta.id}: reads=${reads}, assembly=${assembly}, paf=${paf}"
        assert reads.exists() : "Reads file ${reads} does not exist"
        assert assembly.exists() : "Assembly file ${assembly} does not exist"
        assert paf.exists() : "PAF file ${paf} does not exist"
        [meta, reads, assembly, paf] 
    }
    // First Racon polishing cycle
    RACON_1(ch_racon_input_1, 1)
    ch_versions = ch_versions.mix(RACON_1.out.versions)

    // Debug: View Racon 1 output
    RACON_1.out.improved_assembly.view { meta, assembly -> "Debug: RACON_1 output for ${meta.id}: ${assembly}" }

    // Ensure Racon 1 output is compressed
    ch_racon1_gzipped = RACON_1.out.improved_assembly.map { meta, racon1_fasta ->
        println "Debug: Compressing Racon 1 output for ${meta.id}"
        def racon1_gz = file("${workDir}/${meta.id}.racon1.fasta.gz")

        if (!racon1_fasta.name.endsWith(".gz")) {
            "gzip -c ${racon1_fasta} > ${racon1_gz}".execute().waitFor()
        } else {
            racon1_fasta.copyTo(racon1_gz)
        }

        println "Debug: Compressed Racon 1 output for ${meta.id}: ${racon1_gz.toAbsolutePath()}"
        assert racon1_gz.exists() : "Racon 1 output file ${racon1_gz.toAbsolutePath()} does not exist"

        return [meta, racon1_gz]
    }

    // Second Minimap2 alignment
    MINIMAP2_POLISH_2(reads, ch_racon1_gzipped.map { it[1] }, false, true, false)
    ch_versions = ch_versions.mix(MINIMAP2_POLISH_2.out.versions)

    // Debug: View Minimap2 second output
    MINIMAP2_POLISH_2.out.paf.view { meta, paf -> "Debug: MINIMAP2_POLISH_2 output for ${meta.id}: ${paf}" }

    ch_racon_input_2 = reads.join(ch_racon1_gzipped)
        .join(MINIMAP2_POLISH_2.out.paf)
        .map { meta, reads, assembly, paf -> 
            println "Debug: RACON_2 input for ${meta.id}: reads=${reads}, assembly=${assembly}, paf=${paf}"
            assert reads.exists() : "Reads file ${reads} does not exist"
            assert assembly.exists() : "Assembly file ${assembly} does not exist"
            assert paf.exists() : "PAF file ${paf} does not exist"
            [meta, reads, assembly, paf] 
        }

    // Second Racon polishing cycle
    RACON_2(ch_racon_input_2, 2)
    ch_versions = ch_versions.mix(RACON_2.out.versions)

    // Debug: View Racon 2 output
    RACON_2.out.improved_assembly.view { meta, assembly -> "Debug: RACON_2 output for ${meta.id}: ${assembly}" }

    // Ensure Racon 2 output is compressed
    ch_racon2_gzipped = RACON_2.out.improved_assembly.map { meta, racon2_fasta ->
        println "Debug: Compressing Racon 2 output for ${meta.id}"
        def racon2_gz = file("${workDir}/${meta.id}.racon2.fasta.gz")

        if (!racon2_fasta.name.endsWith(".gz")) {
            "gzip -c ${racon2_fasta} > ${racon2_gz}".execute().waitFor()
        } else {
            racon2_fasta.copyTo(racon2_gz)
        }

        println "Debug: Compressed Racon 2 output for ${meta.id}: ${racon2_gz.toAbsolutePath()}"
        assert racon2_gz.exists() : "Racon 2 output file ${racon2_gz.toAbsolutePath()} does not exist"

        return [meta, racon2_gz]
    }

    // Emit both rounds of polished assemblies
    emit:
    polished_assembly_1 = ch_racon1_gzipped
    polished_assembly_2 = ch_racon2_gzipped
    versions            = ch_versions
}*/
/*workflow POLISH_ASSEMBLY {
    take:
    ch_input    // channel: [ [ meta ], [ reads ], [ assembly ] ]

    main:
    ch_versions = Channel.empty()

    // Ensure input assemblies are in .gz format within the work directory
    ch_prepped_assembly = ch_input.map { meta, reads, assembly_file ->
        println "Debug: Preparing assembly for ${meta.id}"
        def final_assembly = file("${workDir}/${meta.id}.assembly.fasta.gz")

        if (assembly_file instanceof ArrayList) {
            assembly_file = assembly_file[0]  // Take the first element if it's a list
        }

        if (!assembly_file.name.endsWith(".gz")) {
            println "Debug: Compressing assembly file for ${meta.id}"
            "gzip -c ${assembly_file} > ${final_assembly}".execute().waitFor()
        } else {
            assembly_file.copyTo(final_assembly)
        }

        println "Debug: Prepared assembly file for ${meta.id}: ${final_assembly.toAbsolutePath()}"
        assert final_assembly.exists() : "Assembly file ${final_assembly.toAbsolutePath()} does not exist"

        return [meta, reads, final_assembly]
    }

    // First Minimap2 alignment
    MINIMAP2_POLISH_1(ch_prepped_assembly.map { meta, reads, assembly -> [meta, reads] }, 
                      ch_prepped_assembly.map { meta, reads, assembly -> assembly }, 
                      false, true, false)
    ch_versions = ch_versions.mix(MINIMAP2_POLISH_1.out.versions.first())
 
    // Add a small delay to allow for file system operations
    ch_minimap2_output = MINIMAP2_POLISH_1.out.paf
        .map { it -> sleep(100); it }

    // Debug: View Minimap2 output
    ch_minimap2_output.view { meta, paf -> "Debug: MINIMAP2_POLISH_1 output for ${meta.id}: ${paf}" }

    ch_racon_input_1 = ch_prepped_assembly
    .join(ch_minimap2_output)
    .map { meta, reads, assembly, paf -> 
        println "Debug: RACON_1 input for ${meta.id}: reads=${reads}, assembly=${assembly}, paf=${paf}"
        
        // Handle case where reads or assembly might be a list
        def read_file = reads instanceof List ? reads[0] : reads
        def assembly_file = assembly instanceof List ? assembly[0] : assembly
        def paf_file = paf instanceof List ? paf[0] : paf
        
        assert read_file.exists() : "Reads file ${read_file} does not exist"
        assert assembly_file.exists() : "Assembly file ${assembly_file} does not exist"
        assert paf_file.exists() : "PAF file ${paf_file} does not exist"
        
        [meta, read_file, assembly_file, paf_file] 
    }

    // First Racon polishing cycle
    RACON_1(ch_racon_input_1, 1)
    ch_versions = ch_versions.mix(RACON_1.out.versions)

    // Debug: View Racon 1 output
    RACON_1.out.improved_assembly.view { meta, assembly -> "Debug: RACON_1 output for ${meta.id}: ${assembly}" }

    // Ensure Racon 1 output is compressed
    ch_racon1_gzipped = RACON_1.out.improved_assembly.map { meta, racon1_fasta ->
        println "Debug: Compressing Racon 1 output for ${meta.id}"
        def racon1_gz = file("${workDir}/${meta.id}.racon1.fasta.gz")

        if (!racon1_fasta.name.endsWith(".gz")) {
            "gzip -c ${racon1_fasta} > ${racon1_gz}".execute().waitFor()
        } else {
            racon1_fasta.copyTo(racon1_gz)
        }

        println "Debug: Compressed Racon 1 output for ${meta.id}: ${racon1_gz.toAbsolutePath()}"
        assert racon1_gz.exists() : "Racon 1 output file ${racon1_gz.toAbsolutePath()} does not exist"

        return [meta, racon1_gz]
    }

    // Second Minimap2 alignment
    MINIMAP2_POLISH_2(ch_prepped_assembly.map { meta, reads, assembly -> [meta, reads] },
                      ch_racon1_gzipped.map { meta, assembly -> assembly },
                      false, true, false)
    ch_versions = ch_versions.mix(MINIMAP2_POLISH_2.out.versions)

    // Debug: View Minimap2 second output
    MINIMAP2_POLISH_2.out.paf.view { meta, paf -> "Debug: MINIMAP2_POLISH_2 output for ${meta.id}: ${paf}" }

    ch_racon_input_2 = ch_prepped_assembly
        .join(ch_racon1_gzipped)
        .join(MINIMAP2_POLISH_2.out.paf)
        .map { meta, reads, assembly, racon1_assembly, paf -> 
            println "Debug: RACON_2 input for ${meta.id}: reads=${reads}, assembly=${racon1_assembly}, paf=${paf}"
            assert reads.exists() : "Reads file ${reads} does not exist"
            assert racon1_assembly.exists() : "Assembly file ${racon1_assembly} does not exist"
            assert paf.exists() : "PAF file ${paf} does not exist"
            [meta, reads, racon1_assembly, paf] 
        }

    // Second Racon polishing cycle
    RACON_2(ch_racon_input_2, 2)
    ch_versions = ch_versions.mix(RACON_2.out.versions)

    // Debug: View Racon 2 output
    RACON_2.out.improved_assembly.view { meta, assembly -> "Debug: RACON_2 output for ${meta.id}: ${assembly}" }

    // Ensure Racon 2 output is compressed
    ch_racon2_gzipped = RACON_2.out.improved_assembly.map { meta, racon2_fasta ->
        println "Debug: Compressing Racon 2 output for ${meta.id}"
        def racon2_gz = file("${workDir}/${meta.id}.racon2.fasta.gz")

        if (!racon2_fasta.name.endsWith(".gz")) {
            "gzip -c ${racon2_fasta} > ${racon2_gz}".execute().waitFor()
        } else {
            racon2_fasta.copyTo(racon2_gz)
        }

        println "Debug: Compressed Racon 2 output for ${meta.id}: ${racon2_gz.toAbsolutePath()}"
        assert racon2_gz.exists() : "Racon 2 output file ${racon2_gz.toAbsolutePath()} does not exist"

        return [meta, racon2_gz]
    }

    // Emit both rounds of polished assemblies
    emit:
    polished_assembly_1 = ch_racon1_gzipped
    polished_assembly_2 = ch_racon2_gzipped
    versions            = ch_versions
}*/
/*
workflow POLISH_ASSEMBLY {
    take:
    ch_input    // channel: [ [ meta ], [ reads ], [ assembly ] ]

    main:
    ch_versions = Channel.empty()

    // Ensure input assemblies are in .gz format within the work directory
    ch_prepped_assembly = ch_input.map { meta, reads, assembly_file ->
        println "Debug: Preparing assembly for ${meta.id}"
        def final_assembly = file("${workDir}/${meta.id}.assembly.fasta.gz")

        if (assembly_file instanceof ArrayList) {
            assembly_file = assembly_file[0]  // Take the first element if it's a list
        }

        if (!assembly_file.name.endsWith(".gz")) {
            println "Debug: Compressing assembly file for ${meta.id}"
            "gzip -c ${assembly_file} > ${final_assembly}".execute().waitFor()
        } else {
            assembly_file.copyTo(final_assembly)
        }

        println "Debug: Prepared assembly file for ${meta.id}: ${final_assembly.toAbsolutePath()}"
        assert final_assembly.exists() : "Assembly file ${final_assembly.toAbsolutePath()} does not exist"

        return [meta, reads, final_assembly]
    }

    // First Minimap2 alignment
    MINIMAP2_POLISH_1(ch_prepped_assembly.map { meta, reads, assembly -> [meta, reads] },
                      ch_prepped_assembly.map { meta, reads, assembly -> assembly },
                      false, true, false)
    ch_versions = ch_versions.mix(MINIMAP2_POLISH_1.out.versions.first())

    // Random sleep 100–400 ms for race condition protection
    ch_minimap2_output = MINIMAP2_POLISH_1.out.paf
        .map { sleep((new Random().nextInt(301)) + 100); it }

    ch_minimap2_output.view { meta, paf -> "Debug: MINIMAP2_POLISH_1 output for ${meta.id}: ${paf}" }

    ch_racon_input_1 = ch_prepped_assembly
        .join(ch_minimap2_output)
        .map { meta, reads, assembly, paf ->
            println "Debug: RACON_1 input for ${meta.id}: reads=${reads}, assembly=${assembly}, paf=${paf}"

            def read_file     = reads instanceof List ? reads[0] : reads
            def assembly_file = assembly instanceof List ? assembly[0] : assembly
            def paf_file      = paf instanceof List ? paf[0] : paf

            assert read_file.exists() : "Reads file ${read_file} does not exist"
            assert assembly_file.exists() : "Assembly file ${assembly_file} does not exist"
            assert paf_file.exists() : "PAF file ${paf_file} does not exist"

            [meta, read_file, assembly_file, paf_file]
        }

    RACON_1(ch_racon_input_1, 1)
    ch_versions = ch_versions.mix(RACON_1.out.versions)

    RACON_1.out.improved_assembly.view { meta, assembly -> "Debug: RACON_1 output for ${meta.id}: ${assembly}" }

    ch_racon1_gzipped = RACON_1.out.improved_assembly.map { meta, racon1_fasta ->
        println "Debug: Compressing Racon 1 output for ${meta.id}"
        def racon1_gz = file("${workDir}/${meta.id}.racon1.fasta.gz")

        if (!racon1_fasta.name.endsWith(".gz")) {
            "gzip -c ${racon1_fasta} > ${racon1_gz}".execute().waitFor()
        } else {
            racon1_fasta.copyTo(racon1_gz)
        }

        println "Debug: Compressed Racon 1 output for ${meta.id}: ${racon1_gz.toAbsolutePath()}"
        assert racon1_gz.exists() : "Racon 1 output file ${racon1_gz.toAbsolutePath()} does not exist"

        return [meta, racon1_gz]
    }

    // Second Minimap2 alignment
    MINIMAP2_POLISH_2(ch_prepped_assembly.map { meta, reads, assembly -> [meta, reads] },
                      ch_racon1_gzipped.map { meta, assembly -> assembly },
                      false, true, false)
    ch_versions = ch_versions.mix(MINIMAP2_POLISH_2.out.versions)

    // Add random delay to PAF output to avoid race condition
    ch_minimap2_output_2 = MINIMAP2_POLISH_2.out.paf
        .map { sleep((new Random().nextInt(301)) + 100); it }

    ch_minimap2_output_2.view { meta, paf -> "Debug: MINIMAP2_POLISH_2 output for ${meta.id}: ${paf}" }

    ch_racon_input_2 = ch_prepped_assembly
        .join(ch_racon1_gzipped)
        .join(ch_minimap2_output_2)
        .map { meta, reads, assembly, racon1_assembly, paf ->
            println "Debug: RACON_2 input for ${meta.id}: reads=${reads}, assembly=${racon1_assembly}, paf=${paf}"
            assert reads.exists() : "Reads file ${reads} does not exist"
            assert racon1_assembly.exists() : "Assembly file ${racon1_assembly} does not exist"
            assert paf.exists() : "PAF file ${paf} does not exist"
            [meta, reads, racon1_assembly, paf]
        }

    RACON_2(ch_racon_input_2, 2)
    ch_versions = ch_versions.mix(RACON_2.out.versions)

    RACON_2.out.improved_assembly.view { meta, assembly -> "Debug: RACON_2 output for ${meta.id}: ${assembly}" }

    ch_racon2_gzipped = RACON_2.out.improved_assembly.map { meta, racon2_fasta ->
        println "Debug: Compressing Racon 2 output for ${meta.id}"
        def racon2_gz = file("${workDir}/${meta.id}.racon2.fasta.gz")

        if (!racon2_fasta.name.endsWith(".gz")) {
            "gzip -c ${racon2_fasta} > ${racon2_gz}".execute().waitFor()
        } else {
            racon2_fasta.copyTo(racon2_gz)
        }

        println "Debug: Compressed Racon 2 output for ${meta.id}: ${racon2_gz.toAbsolutePath()}"
        assert racon2_gz.exists() : "Racon 2 output file ${racon2_gz.toAbsolutePath()} does not exist"

        return [meta, racon2_gz]
    }

    emit:
    polished_assembly_1 = ch_racon1_gzipped
    polished_assembly_2 = ch_racon2_gzipped
    versions            = ch_versions
}
*/
/*
workflow POLISH_ASSEMBLY {
    take:
    ch_input    // channel: [ [ meta ], [ reads ], [ assembly ] ]

    main:
    ch_versions = Channel.empty()

    // Ensure input assemblies are in .gz format within the work directory
    ch_prepped_assembly = ch_input.map { meta, reads, assembly_file ->
        println "Debug: Preparing assembly for ${meta.id}"
        def final_assembly = file("${workDir}/${meta.id}.assembly.fasta.gz")

        if (assembly_file instanceof ArrayList) {
            assembly_file = assembly_file[0]  // Take the first element if it's a list
        }

        if (!assembly_file.name.endsWith(".gz")) {
            println "Debug: Compressing assembly file for ${meta.id}"
            "gzip -c ${assembly_file} > ${final_assembly}".execute().waitFor()
        } else {
            assembly_file.copyTo(final_assembly)
        }

        println "Debug: Prepared assembly file for ${meta.id}: ${final_assembly.toAbsolutePath()}"
        assert final_assembly.exists() : "Assembly file ${final_assembly.toAbsolutePath()} does not exist"

        return [meta, reads, final_assembly]
    }

    // First Minimap2 alignment
    MINIMAP2_POLISH_1(ch_prepped_assembly.map { meta, reads, assembly -> [meta, reads] }, 
                      ch_prepped_assembly.map { meta, reads, assembly -> assembly }, 
                      false, true, false)
    ch_versions = ch_versions.mix(MINIMAP2_POLISH_1.out.versions.first())

    // Add a small per-sample delay to ensure outputs are ready
    ch_minimap2_output = MINIMAP2_POLISH_1.out.paf
        .map { it -> sleep(100); it }

    // Debug: View Minimap2 output
    ch_minimap2_output.view { meta, paf -> "Debug: MINIMAP2_POLISH_1 output for ${meta.id}: ${paf}" }

    ch_racon_input_1 = ch_prepped_assembly
        .join(ch_minimap2_output)
        .map { meta, reads, assembly, paf -> 
            println "Debug: RACON_1 input for ${meta.id}: reads=${reads}, assembly=${assembly}, paf=${paf}"
            def read_file = reads instanceof List ? reads[0] : reads
            def assembly_file = assembly instanceof List ? assembly[0] : assembly
            def paf_file = paf instanceof List ? paf[0] : paf

            assert read_file.exists() : "Reads file ${read_file} does not exist"
            assert assembly_file.exists() : "Assembly file ${assembly_file} does not exist"
            assert paf_file.exists() : "PAF file ${paf_file} does not exist"

            [meta, read_file, assembly_file, paf_file] 
        }

    // First Racon polishing cycle
    RACON_1(ch_racon_input_1, 1)
    ch_versions = ch_versions.mix(RACON_1.out.versions)

    // Debug: View Racon 1 output
    RACON_1.out.improved_assembly.view { meta, assembly -> "Debug: RACON_1 output for ${meta.id}: ${assembly}" }

    // Ensure Racon 1 output is compressed
    ch_racon1_gzipped = RACON_1.out.improved_assembly.map { meta, racon1_fasta ->
        println "Debug: Compressing Racon 1 output for ${meta.id}"
        def racon1_gz = file("${workDir}/${meta.id}.racon1.fasta.gz")

        if (!racon1_fasta.name.endsWith(".gz")) {
            "gzip -c ${racon1_fasta} > ${racon1_gz}".execute().waitFor()
        } else {
            racon1_fasta.copyTo(racon1_gz)
        }

        println "Debug: Compressed Racon 1 output for ${meta.id}: ${racon1_gz.toAbsolutePath()}"
        assert racon1_gz.exists() : "Racon 1 output file ${racon1_gz.toAbsolutePath()} does not exist"

        return [meta, racon1_gz]
    }

    // Second Minimap2 alignment
    MINIMAP2_POLISH_2(ch_prepped_assembly.map { meta, reads, assembly -> [meta, reads] },
                      ch_racon1_gzipped.map { meta, assembly -> assembly },
                      false, true, false)
    ch_versions = ch_versions.mix(MINIMAP2_POLISH_2.out.versions)

    // Debug: View Minimap2 second output
    MINIMAP2_POLISH_2.out.paf.view { meta, paf -> "Debug: MINIMAP2_POLISH_2 output for ${meta.id}: ${paf}" }

    // Add a small per-sample delay to ensure second Minimap2 outputs are ready
    ch_minimap2_polish2_output = MINIMAP2_POLISH_2.out.paf
        .map { it -> sleep(100); it }

    ch_racon_input_2 = ch_prepped_assembly
        .join(ch_racon1_gzipped)
        .join(ch_minimap2_polish2_output)
        .map { meta, reads, assembly, racon1_assembly, paf -> 
            println "Debug: RACON_2 input for ${meta.id}: reads=${reads}, assembly=${racon1_assembly}, paf=${paf}"
            assert reads.exists() : "Reads file ${reads} does not exist"
            assert racon1_assembly.exists() : "Assembly file ${racon1_assembly} does not exist"
            assert paf.exists() : "PAF file ${paf} does not exist"
            [meta, reads, racon1_assembly, paf] 
        }

    // Second Racon polishing cycle
    RACON_2(ch_racon_input_2, 2)
    ch_versions = ch_versions.mix(RACON_2.out.versions)

    // Debug: View Racon 2 output
    RACON_2.out.improved_assembly.view { meta, assembly -> "Debug: RACON_2 output for ${meta.id}: ${assembly}" }

    // Ensure Racon 2 output is compressed
    ch_racon2_gzipped = RACON_2.out.improved_assembly.map { meta, racon2_fasta ->
        println "Debug: Compressing Racon 2 output for ${meta.id}"
        def racon2_gz = file("${workDir}/${meta.id}.racon2.fasta.gz")

        if (!racon2_fasta.name.endsWith(".gz")) {
            "gzip -c ${racon2_fasta} > ${racon2_gz}".execute().waitFor()
        } else {
            racon2_fasta.copyTo(racon2_gz)
        }

        println "Debug: Compressed Racon 2 output for ${meta.id}: ${racon2_gz.toAbsolutePath()}"
        assert racon2_gz.exists() : "Racon 2 output file ${racon2_gz.toAbsolutePath()} does not exist"

        return [meta, racon2_gz]
    }

    // Emit both rounds of polished assemblies
    emit:
    polished_assembly_1 = ch_racon1_gzipped
    polished_assembly_2 = ch_racon2_gzipped
    versions            = ch_versions
}*/
workflow POLISH_ASSEMBLY {
    take:
    ch_input    // channel: [ [ meta ], [ reads ], [ assembly ] ]

    main:
    ch_versions = Channel.empty()

    // Ensure input assemblies are .gz compressed
    ch_prepped_assembly = ch_input.map { meta, reads, assembly_file ->
        println "Debug: Preparing assembly for ${meta.id}"
        def final_assembly = file("${workDir}/${meta.id}.assembly.fasta.gz")

        if (!assembly_file.name.endsWith(".gz")) {
            println "Debug: Compressing assembly file for ${meta.id}"
            "gzip -c ${assembly_file} > ${final_assembly}".execute().waitFor()
        } else {
            assembly_file.copyTo(final_assembly)
        }

        assert final_assembly.exists() : "Assembly file ${final_assembly.toAbsolutePath()} does not exist"

        return [meta, reads, final_assembly]
    }

    // First Minimap2 alignment
    MINIMAP2_POLISH_1(
        ch_prepped_assembly.map { meta, reads, assembly -> [meta, reads] },
        ch_prepped_assembly.map { meta, reads, assembly -> assembly },
        false, true, false
    )
    ch_versions = ch_versions.mix(MINIMAP2_POLISH_1.out.versions.first())

    ch_minimap2_output = MINIMAP2_POLISH_1.out.paf
        .map { it -> sleep(100); it }

    // Prepare input for Racon 1
    ch_racon_input_1 = ch_prepped_assembly
        .join(ch_minimap2_output)
        .map { meta, reads, assembly, paf ->
            [meta, reads instanceof List ? reads[0] : reads, assembly, paf]
        }

    // First (and final) Racon polishing
    RACON_1(ch_racon_input_1, 1)
    ch_versions = ch_versions.mix(RACON_1.out.versions)

    ch_racon1_gzipped = RACON_1.out.improved_assembly.map { meta, racon1_fasta ->
        println "Debug: Compressing Racon1 output for ${meta.id}"
        def racon1_gz = file("${workDir}/${meta.id}.racon1.fasta.gz")

        if (!racon1_fasta.name.endsWith(".gz")) {
            "gzip -c ${racon1_fasta} > ${racon1_gz}".execute().waitFor()
        } else {
            racon1_fasta.copyTo(racon1_gz)
        }

        assert racon1_gz.exists() : "Racon1 output file ${racon1_gz.toAbsolutePath()} does not exist"

        return [meta, racon1_gz]
    }

    emit:
    polished_assembly_1 = ch_racon1_gzipped
    versions            = ch_versions
}