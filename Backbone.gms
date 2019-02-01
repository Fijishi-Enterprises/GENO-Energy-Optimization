$title Backbone
$ontext
Backbone - chronological energy systems model
Copyright (C) 2016 - 2018  VTT Technical Research Centre of Finland

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

==========================================================================
Created by:
    Juha Kiviluoma
    Erkka Rinne
    Topi Rasku
    Niina Helisto

- Based on Stochastic Model Predictive Control method [1].
- Enables multiple different models (m) to be implemented by changing
  the temporal structure of the model. (MULTI-MODEL RUNS TO BE IMPLEMENTED)
- Time steps (t) can vary in length.
- Short term forecast stochasticity (f) and longer term statistical uncertainty (s).
- Can handle ramp based dispatch in addition to energy blocks. (TO BE IMPLEMENTED)


GAMS command line arguments
¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨
--debug=[yes|no]
    Switch on/off debugging mode. In debug mode, writes ‘debug.gdx’
    with all symbols as well as a gdx file for each solution containing
    model parameters, variables and equations.

--diag=[yes|no]
    Switch on/off diagnostics. Writes some additional diagnostic results in
    'results.gdx' about data updates and efficiency approximations.

--dummy=[yes|no]
    Do not solve the model, just do preliminary calculations.
    For testing purposes.

--penalty=<value>
    Changes the value of the penalty cost. Default penalty value is 1e9
    if not provided.

--input_dir=<path>
    Directory to read input from. Defaults to './input'.

--output_dir=<path>
    Directory to write output to. Defaults to './output'.


References
----------
[1] K. Nolde, M. Uhr, and M. Morari, ‘Medium term scheduling of a hydro-thermal
    system using stochastic model predictive control, ’ Automatica, vol. 44,
    no. 6, pp. 1585–1594, Jun. 2008.

==========================================================================
$offtext

* Default values for input and output dir
$if not set input_dir $setglobal input_dir 'input'
$if not set output_dir $setglobal output_dir 'output'

* Make sure output dir exists
$if not dexist %output_dir% $call 'mkdir %output_dir%'

* Activate end of line comments and set comment character to '//'
$oneolcom
$eolcom //
$onempty   // Allow empty data definitions

* Output file streams
files log /''/, gdx, f_info /'%output_dir%/info.txt'/;

* Include options file to control the solver
$include '%input_dir%/1_options.gms';

* === Libraries ===============================================================
$libinclude scenred2

* === Definitions, sets, parameters and input data=============================
$include 'inc/1a_definitions.gms'   // Definitions for possible model settings
$include 'inc/1b_sets.gms'          // Set definitions used by the models
$include 'inc/1c_parameters.gms'    // Parameter definitions used by the models
$include 'inc/1d_results.gms'       // Parameter definitions for model results
$include 'inc/1e_inputs.gms'        // Load input data

* === Variables and equations =================================================
$include 'inc/2a_variables.gms'                         // Define variables for the models
$include 'inc/2b_eqDeclarations.gms'                    // Equation declarations
$ifthen exist '%input_dir%/2c_alternative_objective.gms'      // Objective function - either the default or an alternative from input files
    $$include '%input_dir%/2c_alternative_objective.gms';
$else
    $$include 'inc/2c_objective.gms'
$endif
$include 'inc/2d_constraints.gms'                       // Define constraint equations for the models
$ifthen exist '%input_dir%/2e_additional_constraints.gms'
   $$include '%input_dir%/2e_additional_constraints.gms'      // Define additional constraints from the input data
$endif


* === Model definition files ==================================================
$include 'defModels/schedule.gms'
$include 'defModels/building.gms'
$include 'defModels/invest.gms'

// Load model input parameters
$include '%input_dir%/modelsInit.gms'


* === Simulation ==============================================================
$include 'inc/3a_periodicInit.gms'  // Initialize modelling loop
loop(modelSolves(mSolve, tSolve),
    solveCount = solveCount + 1;
    $$include 'inc/3b_periodicLoop.gms'         // Update modelling loop
    $$include 'inc/3c_inputsLoop.gms'           // Read input data that is updated within the loop
    $$include 'inc/3d_setVariableLimits.gms'    // Set new variable limits (.lo and .up)
$iftheni.dummy not %dummy% == 'yes'
    $$include 'inc/3e_solve.gms'                // Solve model(s)
    $$include 'inc/3f_afterSolve.gms'           // Post-processing variables after the solve
    $$include 'inc/4a_outputVariant.gms'        // Store results from the loop
$endif.dummy
$iftheni.debug '%debug%' == 'yes'
        putclose gdx;
        put_utility 'gdxout' / '%output_dir%/' mSolve.tl:0 '-' tSolve.tl:0 '.gdx';
            execute_unload
            $$include defOutput/debugSymbols.inc
        ;
$endif.debug
    if(execError, put log "!!! Errors encountered: " execError:0:0);
);

$if exist '%input_dir%/3z_modelsClose.gms' $include '%input_dir%/3z_modelsClose.gms';

* === Output ==================================================================
$echon "'version' " > 'version'
$call 'git describe --dirty=+ --always >> version'
$ifi not %dummy% == 'yes'
$include 'inc/4b_outputInvariant.gms'
$include 'inc/4c_outputQuickFile.gms'

* Post-process results
$if exist '%input_dir%/4d_postProcess.gms' $include '%input_dir%/4d_postProcess.gms'

execute_unload '%output_dir%/results.gdx',
    $$include 'defOutput/resultSymbols.inc'
;

$ifi '%debug%' == 'yes'
execute_unload '%output_dir%/debug.gdx';

if(errorcount > 0, abort errorcount);
* === THE END =================================================================
