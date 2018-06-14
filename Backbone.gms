$title Backbone
$ontext
Backbone - chronological energy systems model
Copyright (C) 2016 - 2017  VTT Technical Research Centre of Finland

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
    Juha Kiviluoma <juha.kiviluoma@vtt.fi>
    Erkka Rinne <erkka.rinne@vtt.fi>
    Topi Rasku <topi.rasku@vtt.fi>
    Niina Helisto <niina.helisto@vtt.fi>

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

==========================================================================
$offtext


* Activate end of line comments and set comment character to '//'
$oneolcom
$eolcom //
$onempty   // Allow empty data definitions

* Output file streams
files log /''/, gdx, f_info /'output\info.txt'/;

options
optca = 0
optcr = 0.0004
*    profile = 8
    solvelink = %Solvelink.Loadlibrary%
*    bratio = 0.25
*    solveopt = merge
*    savepoint = 1
    threads = 1
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
$include 'defModels\schedule.gms'
$include 'defModels\building.gms'
$include 'defModels\invest.gms'

// Load model input parameters
$include 'input\modelsInit.gms'

* === Simulation ==============================================================
$include 'inc\3a_periodicInit.gms'  // Initialize modelling loop
loop(modelSolves(mSolve, tSolve),
    $$include 'inc\3b_inputsLoop.gms'           // Read input data that is updated within the loop
    $$include 'inc\3c_periodicLoop.gms'         // Update modelling loop
    $$include 'inc\3d_setVariableLimits.gms'    // Set new variable limits (.lo and .up)
    $$include 'inc\3e_solve.gms'                // Solve model(s)
    $$include 'inc\4a_outputVariant.gms'  // Store results from the loop
$iftheni.debug '%debug%' == 'yes'
        putclose gdx;
        put_utility 'gdxout' / 'output\'mSolve.tl:0, '-', tSolve.tl:0, '.gdx';
            execute_unload
            $$include defOutput\debugSymbols.inc
        ;
$endif.debug
);

$if exist 'input\3z_modelsClose.gms' $include 'input\3z_modelsClose.gms';

* === Output ==================================================================
$echon "'version' " > 'version'
$call 'git describe --dirty=+ --always >> version'
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
