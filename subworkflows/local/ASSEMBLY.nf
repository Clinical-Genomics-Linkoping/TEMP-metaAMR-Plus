include { FLYE as FLYE_META } from '../../modules/nf-core/flye/main'
include { QUAST } from '../../modules/nf-core/quast/main' 


workflow META_ASSEMBLY {

    take:
    reads

    main:
    ch_versions = Channel.empty()
    def mode = "--nano-hq" 
    

    // Run Flye with --meta option for metagenomic assembly
    ch_assembly = FLYE_META(
        reads,
        mode,
    ).fasta

    ch_versions = ch_versions.mix(FLYE_META.out.versions)
   
    // Run MetaQUAST for assembly quality evaluation
    QUAST(ch_assembly)
    ch_versions = ch_versions.mix(QUAST.out.versions)



    emit:
    ch_assembly  
    ch_versions      
    
}
