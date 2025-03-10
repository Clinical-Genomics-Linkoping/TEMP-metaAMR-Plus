include { MINIMAP2_ALIGN as MINIMAP2_POLISH_1 } from '../../modules/nf-core/minimap2/align/main'
include { MINIMAP2_ALIGN as MINIMAP2_POLISH_2 } from '../../modules/nf-core/minimap2/align/main'
include { RACON as RACON_1 } from '../../modules/nf-core/racon/main'
include { RACON as RACON_2 } from '../../modules/nf-core/racon/main'


workflow POLISH_ASSEMBLY {
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
}