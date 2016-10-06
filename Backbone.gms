$title Backbone
$ontext
Backbone - chronological energy systems model
==========================================================================
Created by:
    Juha Kiviluoma <juha.kiviluoma@vtt.fi>
    Erkka Rinne <erkka.rinne@vtt.fi>
    Topi Rasku <topi.rasku@vtt.fi>

- Based on Stochastic Model Predictive Control method [1].
- Enables multiple different models (m) to be implemented by changing
  the temporal structure of the model.
- Time steps (t) can vary in length.
- Short term forecast stochasticity (f) and longer term statistical uncertainty (s).
- Can handle ramp based dispatch in addition to energy blocks.


GAMS command line arguments
¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨
--debug=[yes|no]
    Switch on/off debugging mode. In debug mode, writes ‘debug.gdx’
    with all symbols as well as a gdx file for each solution containing
    model parameters, variables and equations.

--dummy=[yes|no]
    Do not solve the model, just do preliminary calculations.
    For testing purposes.

--<name of model parameter>=<value>
    Set model parameter value. See file ‘inc/setting_sets.gms’ for available
    parameters.

--<name of model feature>=[yes|no]
    Switch model features on/off. See file ‘inc/setting_sets.gms’ for available
    features.


References
----------
[1] K. Nolde, M. Uhr, and M. Morari, ‘Medium term scheduling of a hydro-thermal
    system using stochastic model predictive control, ’ Automatica, vol. 44,
    no. 6, pp. 1585–1594, Jun. 2008.

$offtext


* Activate end of line comments and set comment character to '//'
$oneolcom
$eolcom //
$onempty   // Allow empty data definitions

* Output file streams
files log /''/, gdx, f_info /'output\info.txt'/;

options
    optca = 0
    optcr = 0.00001
    profile = 8
    solvelink = %Solvelink.Loadlibrary%
    bratio = 1
    solveopt = replace
    savepoint = 0
    threads = -1
$ifi not '%debug%' == 'yes'
    solprint = Silent
;


* === Definitions, sets, parameters and input data=============================
$include 'inc\1a_definitions.gms'   // Definitions for possible model settings
$include 'inc\1b_sets.gms'          // Set definitions used by the models
$include 'inc\1c_parameters.gms'    // Parameter definitions used by the models
$include 'inc\1d_results.gms'       // Parameter definitions for model results
$include 'inc\1e_inputs.gms'        // Load input data

* === Variables and equations =================================================
$include 'inc\2a_variables.gms'     // Define variables for the models
$include 'inc\2b_equations.gms'     // Define equations for the models

* === Model definition files ==================================================
$include 'input\3a_modelsInit.gms'  // Sets that are defined over the whole modelling loop

* === Simulation ==============================================================
loop(modelSolves(mSolve, tSolve),
    $$include 'input\3b_modelsLoop.gms'         // Set sets that define model scope
    $$include 'inc\3c_setVariableLimits.gms'    // Set new variable limits (.lo and .up)
    $$ifi '%debug%' == 'yes' execute_unload 'output\debug.gdx';   // Output debugging information
    $$include 'inc\3d_solve.gms'                // Solve model(s)
    put log;
    put schedule.resGen;
    put tSolveFirst;
    putclose log;

    $$include 'inc\4a_outputVariant.gms'  // Store results from the loop
    $$ifi '%debug%' == 'yes' execute_unload 'output\debug.gdx';   // Output debugging information
*    $$ifi.debug '%debug%' == 'yes'
*        putclose gdx;
*        put_utility 'gdxout' / 'output\'mSolve.tl:0, '-', tSolve.tl:0, '.gdx';
*            execute_unload
*            $$include defOutput\debugSymbols.inc
*        ;
*    $$endifi.debug
);

$if exist 'input\3z_modelsClose.gms' $include 'input\3z_modelsClose.gms';


* === Output ==================================================================
$echon "'StoSSch version' " > 'stosschver'
$call 'git describe --dirty=+ --always >> stosschver'
$include 'inc\4b_outputInvariant.gms'
$include 'inc\4c_outputQuickFile.gms'

* Post-process results
$if exist 'inc\4d_postProcess.gms' $include 'defOutput\4d_postProcess.gms'

execute_unload 'output\results.gdx',
    $$include 'defOutput\resultSymbols.inc'
;

*$ifi '%debug%' == 'yes' execute_unload 'output\debug.gdx';
execute_unload 'output\debug.gdx';

if(errorcount > 0, abort errorcount);
* === THE END =================================================================
