include { MINIMAP2_ALIGN as MINIMAP2_POLISH_1 } from '../../modules/nf-core/minimap2/align/main'
include { MINIMAP2_ALIGN as MINIMAP2_POLISH_2 } from '../../modules/nf-core/minimap2/align/main'
include { RACON as RACON_1 } from '../../modules/nf-core/racon/main'
include { RACON as RACON_2 } from '../../modules/nf-core/racon/main'

workflow POLISH_ASSEMBLY {
    take:
    reads    // channel: [ [ meta ], [ reads ] ]
    assembly // channel: [ [ meta ], [ assembly ] ]

    main:
    ch_versions = Channel.empty()

    // First Minimap2 alignment and Racon polishing cycle
    MINIMAP2_POLISH_1(reads, assembly.map { it[1] }, false, true, false)
    ch_versions = ch_versions.mix(MINIMAP2_POLISH_1.out.versions.first())

    ch_racon_input_1 = reads.join(assembly)
        .join(MINIMAP2_POLISH_1.out.paf)
        .map { meta, reads, assembly, paf -> [meta, reads, assembly, paf] }

    RACON_1(ch_racon_input_1, 1)
    ch_versions = ch_versions.mix(RACON_1.out.versions)

    // Second Minimap2 alignment and Racon polishing cycle
    MINIMAP2_POLISH_2(reads, RACON_1.out.improved_assembly.map { it[1] }, false, true, false)
    ch_versions = ch_versions.mix(MINIMAP2_POLISH_2.out.versions)

    ch_racon_input_2 = reads.join(RACON_1.out.improved_assembly)
        .join(MINIMAP2_POLISH_2.out.paf)
        .map { meta, reads, assembly, paf -> [meta, reads, assembly, paf] }

    RACON_2(ch_racon_input_2, 2)
    ch_versions = ch_versions.mix(RACON_2.out.versions)

    emit:
    polished_assembly_1 = RACON_1.out.improved_assembly
    polished_assembly_2 = RACON_2.out.improved_assembly
    versions            = ch_versions
   
}
