$title Backbone
$ontext
Backbone - chronological energy systems model
Copyright (C) 2016 - 2019  VTT Technical Research Centre of Finland

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
    Niina Helistö
    Dana Kirchem
    Ran Li
    Ciara O'Dwyer

This is a GAMS implementation of the Backbone energy system modelling framework
[1]. Features include:
- Based on Stochastic Model Predictive Control method [2].
- Time steps (t) can vary in length.
- Short term forecast stochasticity (f) and longer term statistical uncertainty (s).


GAMS command line arguments
¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨
--debug=[0|1|2]
    Set level of debugging information. Default is 0 when no extra information is
    saved or displayded. At level 1, file 'debug.gdx' containing all GAMS symbols
    is written at the end of execution. At level 2, debug information is written
    for each solve separately.

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

--input_file_gdx=<filename.gdx>
    Filename of the GDX input file. Defaults to 'inputData.gdx'.
    --input_file_gdx=<path> including the filename also works.

--input_file_excel=<path>
    Filename of the Excel input file including the path.
    When using this, make sure you have created 1_input_preparation.gms in the
    input directory and included the necessary lines there. See example from
    1_input_preparation_temp.gms.

--output_dir=<path>
    Directory to write output to. Defaults to './output'.

--output_file=<filename.gdx>
    Filename of the results file. Defaults to 'results.gdx'


References
----------
[1] N. Helistö et al., ‘Backbone---An Adaptable Energy Systems Modelling Framework’,
    Energies, vol. 12, no. 17, p. 3388, Sep. 2019. Available at:
    https://dx.doi.org/10.3390/en12173388.
[2] K. Nolde, M. Uhr, and M. Morari, ‘Medium term scheduling of a hydro-thermal
    system using stochastic model predictive control, ’ Automatica, vol. 44,
    no. 6, pp. 1585–1594, Jun. 2008.

==========================================================================
$offtext

* Check current GAMS version
$ife %system.gamsversion%<240 $abort GAMS distribution 24.0 or later required!

* Set default debugging level
$if not set debug $setglobal debug 0

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
Files log /''/, gdx /''/, f_info /'%output_dir%/info.txt'/;

* Include options file to control the solver
$include '%input_dir%/1_options.gms';

* Include an optional file for input data preparation
$ifthen exist '%input_dir%/1_input_preparation.gms'      // Optional input data preparation
    $$include '%input_dir%/1_input_preparation.gms';
$endif

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
// Macro for checking solve status (1 = normal completion)
$macro checkSolveStatus(mdl) \
    if(mdl.solveStat > 1 and (mdl.modelStat <> 1 or mdl.modelStat <> 8), \
        execError = execError + 1 \
    )

$include 'inc/3a_periodicInit.gms'  // Initialize modelling loop
loop(modelSolves(mSolve, tSolve)$(execError = 0),
    solveCount = solveCount + 1;
    $$include 'inc/3b_periodicLoop.gms'         // Update modelling loop
    $$include 'inc/3c_inputsLoop.gms'           // Read input data that is updated within the loop
    $$include 'inc/3d_setVariableLimits.gms'    // Set new variable limits (.lo and .up)
$iftheni.dummy not %dummy% == 'yes'
    $$include 'inc/3e_solve.gms'                // Solve model(s)
    $$include 'inc/3f_afterSolve.gms'           // Post-processing variables after the solve
    $$include 'inc/4a_outputVariant.gms'        // Store results from the loop
$endif.dummy
$ifthene.debug %debug%>1
        putclose gdx;
        put_utility 'gdxout' / '%output_dir%/' mSolve.tl:0 '-' tSolve.tl:0 '.gdx';
            execute_unload
            $$include defOutput/debugSymbols.inc
        ;
$endif.debug
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

$if not set output_file $setglobal output_file 'results.gdx'

execute_unload '%output_dir%/%output_file%',
    $$include 'defOutput/resultSymbols.inc'
;

$ife %debug%>0
execute_unload '%output_dir%/debug.gdx';
if(execError,
   putclose log "!!! Errors encountered: " execError:0:0/;
   abort "FAILED";
);
* === THE END =================================================================
