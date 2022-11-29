
$ontext
 AdditionalSetsAndParameters.inc is read in 1e_inputs before the input data gdx.
 This is a template file giving examples how this can be used to expand the model

* Creating new sets for additional data table in input data
* See 1b_sets.gms for further examples
Sets
	set1 "new input data set 1"   
	set2 "new input data set 2"   
;

* Creating new parameters for additional data table in input data
* See 1c_parameters.gms for further examples
Parameters
	p_gnuNewDataSet(grid, node, unit, set1) "New parameter table for gnu using previously created set1"   
;


* Creating new result tables
* See 1d_results.gms for further examples
* values for this result table can be calculated in 4d_postProcess.gms
* Alternatively, new result tables can be defined in 4d_postProcess.gms
Parameters
	r_newSumResultTable(unit) "New unit level sum of specific result needed for faster result processing"   
;

$offtext 