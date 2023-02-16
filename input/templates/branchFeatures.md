This branch contains code for the multi-objective optimisation of costs, emissions and thermal comfort. It has two main parts:
 - new optional files for objectives and constraints in the input/templates directory (always use all the files with one prefix of COST, EMISSION, COMFORT or AUGMECON)
 - som new definitions in the defOutput and inc directories

Some issues have to be addressed before merging:
 - Compatibility with v3 (in particular for emissions!)
 - Currently, some variable definitions are done in the optional objective and constraint files (like v_temp_diff_plus and ..._minus). However, these are needed to calculate r_totalDiscomfort, which is integrated in the mandatory inc directory. This will lead to errors when running Backbone without the optional files.
 - Generally, we need to decide, how to integrate the changes. Can everything be made optional or should we include part of the code in the mandatory files?
