include { MINIMAP2_ALIGN as MINIMAP2_POLISH_1 } from '../../modules/nf-core/minimap2/align/main'
include { RACON as RACON_1 } from '../../modules/nf-core/racon/main'


workflow POLISH_ASSEMBLY {
    take:
    ch_input    

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

    // Racon polishing
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