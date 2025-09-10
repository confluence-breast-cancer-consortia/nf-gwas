include { REGENIE_STEP2_RUN        } from '../../modules/local/regenie/regenie_step2_run' 
include { REGENIE_LOG_PARSER_STEP2 } from '../../modules/local/regenie/regenie_log_parser_step2'  

workflow REGENIE_STEP2 {

    take: 
    regenie_step1_out_ch
    imputed_plink2_ch
    genotypes_association_format
    phenotypes_file_validated
    covariates_file_validated
    condition_list_file
    run_interaction_tests

    main:
    if (!params.regenie_sample_file) {
        sample_file = []
    } else {
        sample_file = file(params.regenie_sample_file, checkIfExists: true)
    }

    // Add BGI file handling for BGEN format
    imputed_plink2_ch
        .map { filename, file1, file2, file3, range ->
            def bgi_file = null
            
            if (genotypes_association_format == 'bgen') {
                // Check if file2 is already a BGI file (from chunking)
                if (file2 && file2.toString().endsWith('.bgi')) {
                    bgi_file = file2
                } 
                // Check if file2 is an empty list (no chunking case)
                else if (!file2 || file2.toString() == '[]') {
                    // Construct BGI from BGEN filename
                    def potential_bgi = file("${file1}.bgi")
                    bgi_file = potential_bgi.exists() ? potential_bgi : file('NO_FILE')
                }
            } else {
                bgi_file = file('NO_FILE')
            }
            
            tuple(filename, file1, file2, file3, range, bgi_file)
        }
        .set { regenie_input_with_bgi }

    REGENIE_STEP2_RUN (
        regenie_step1_out_ch.collect(),
        regenie_input_with_bgi,
        genotypes_association_format,
        phenotypes_file_validated,
        sample_file,
        covariates_file_validated,
        condition_list_file,
        run_interaction_tests
    )

    if (run_interaction_tests){
        REGENIE_STEP2_RUN.out.regenie_step2_out_interaction
            .transpose()
            .map { prefix, fl -> tuple(RegenieUtil.getPhenotype(prefix, fl), fl) }
            .set { regenie_step2_out }
        } else {
            regenie_step2_out = REGENIE_STEP2_RUN.out.regenie_step2_out
    }

    regenie_step2_out_log = REGENIE_STEP2_RUN.out.regenie_step2_out_log
    
    REGENIE_LOG_PARSER_STEP2 (
        regenie_step2_out_log.collect()
    )

    regenie_step2_parsed_logs = REGENIE_LOG_PARSER_STEP2.out.regenie_step2_parsed_logs
   
    emit: 
    regenie_step2_parsed_logs
    regenie_step2_out

}