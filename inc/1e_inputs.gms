$ontext
This file is part of Backbone.

Backbone is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Backbone is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with Backbone.  If not, see <http://www.gnu.org/licenses/>.
$offtext


* =============================================================================
* --- Load Input Data ---------------------------------------------------------
* =============================================================================

* --- optional: translating input excel to gdx --------------------------------

* If input_file excel has been set in the command line arguments, then Gdxxrw will be run to convert the Excel into a GDX file
*   using the sheet defined by input_excel_index command line argument (default: 'INDEX').
$ifthen exist '%input_dir%/%input_file_excel%'
    $$call 'gdxxrw Input="%input_dir%/%input_file_excel%" Output="%input_dir%/%input_file_gdx%" Index=%input_excel_index%! %input_excel_checkdate%'
$elseif exist '%input_file_excel%'
    $$call 'gdxxrw Input="%input_file_excel%" Output="%input_dir%/%input_file_gdx%" Index=%input_excel_index%! %input_excel_checkdate%'
$elseif set input_file_excel
    $$abort 'Did not find input data excel from the given location, check path and spelling!'
$endif
$ife %system.errorlevel%>0 $abort gdxxrw failed! Check that your input Excel is valid and that your file path and file name are correct.

* --- locating input data gdx ------------------------------------------------

* setting path for input data gdx and inc files created when reading the data
* default assumptions input_dir = ./input,  input_file_gdx = inputData.gdx
* if %input_dir%/%input_file_gdx% exists
*        option --input_dir specifies alternative input directory. Can be relative reference. See backbone.gms
*        option --input_file_gdx specifies alternative input gdx name. See backbone.gms
*        input data inc files created to same folder
* else if %input_file_gdx% exists
*        --input_file_gdx= nameOfInputFile.gdx for input_file_gdx in ./input
*        --input_file_gdx=ABSOLUTE/PATH/nameOfInputFile.gdx for input_file_gdx not in input_dir
*        input data inc files created to ./input folder
* else go to no_input_gdx label

$ifthen exist '%input_dir%/%input_file_gdx%'
    $$setglobal inputDataGdx '%input_dir%/%input_file_gdx%'
    $$setglobal inputDataInc '%input_dir%/inputData.inc'
    $$setglobal inputDataInc_ '%input_dir%/inputData_.inc'
$elseif exist '%input_file_gdx%'
    $$setglobal inputDataGdx '%input_file_gdx%'
    $$setglobal inputDataInc 'input/inputData.inc'
    $$setglobal inputDataInc_ 'input/inputData_.inc'
$else
    put log '!!! Warning: No input data file found. Skipping reading input data gdx.' /;
    put log '!!! Warning: Will crash the model if alternative data is not given via 1e_scenChanges.gms or changes.inc' /;
    $$goto no_input_gdx
$endif

* --- importing data from the input data gdx ----------------------------------

* the new way to read input data breaks the model if input data gdx contains tables not predefined.
* Reading definitions for user given additional sets and parameters in the input data gdx.
$ifthen exist '%input_dir%/additionalSetsAndParameters.inc'
   $$include '%input_dir%/additionalSetsAndParameters.inc'
$endif


* Importing domains from the input data gdx.
* These can be empty, but must be given in the input data gdx.
* Domains can be supplemented in scen changes or in changes.inc.
$gdxin '%inputDataGdx%'
* Following three must contain values
$loaddcm grid
$loaddcm node
$loaddcm unit
* The rest must be included, but can be empty
$loaddcm emission
$loaddcm flow
$loaddcm unittype
$loaddcm restype
$loaddcm group
$gdxin

* In addition to domains, there is a current minimum dataset for any meaningful model.
* Following data tables must be included either in input data gdx or in data given
* in scen changes or changes.inc
*       p_unit
*       p_gn
*       p_gnu_io
*       effLevelGroupUnit
*       ts_influx (or other data table creating the energy demand)


* ---  Reading all other data present in the input data gdx.  -------------

* setting quote mark for unix or windows (MSNT)
$ SET QTE "'"
$ IFI %SYSTEM.FILESYS%==MSNT $SET QTE '"'

* query checking which data tables exists and writes the list to file inputDataInc
$hiddencall gdxdump %inputDataGdx%  NODATA > %inputDataInc%
* Using sed utility program to convert gdxdump output to a format that can be imported to backbone
* This does the following:
* - deletes lines of gdxdump output which do not start with dollar sign
* - changes various load commands to loaddcm commands
*$hiddencall sed %QTE%/^symbol not found:.*$/Id; /^\([^$]\|$\)/d; s/\$LOAD.. /\$LOADDCM /I%QTE% %inputDataInc% > %inputDataInc_%
$hiddencall sed %QTE%/^[$]/!d;  s/\$LOAD.. /\$LOADDCM /I%QTE%  %inputDataInc% > %inputDataInc_%
* importing data from the input data gdx as specified by the sed command output
$INCLUDE %inputDataInc_%
* closing the input file
$gdxin

* --- Processing alternative sources of input data ----------------------------

* jumping to here if no input gdx. Reading data from alternative sources (1e_scenchanges.inc and changes.inc)
* if input data existed, these alternative sources can be used to modify given data, e.g. when using multiple input files
* or running alternative scenarios.
$label no_input_gdx

* Read changes to inputdata through gdx files (e.g. node2.gdx, unit2.gdx, unit3.gdx)
$include 'inc/1e_scenChanges.gms'

* Reads changes or additions to the inputdata through changes.inc file.
$ifthen exist '%input_dir%/changes.inc'
   $$include '%input_dir%/changes.inc'
$endif


* --- Checking if there is necessary input data to proceed --------------------

$if not defined p_unit $abort 'Mandatory input data missing (p_unit), check inputData.gdx or alternative sources of input data'
$if not defined p_gn $abort 'Mandatory input data missing (p_gn), check inputData.gdx or alternative sources of input data'
$if not defined p_gnu_io $abort 'Mandatory input data missing (p_gnu_io), check inputData.gdx or alternative sources of input data'


* =============================================================================
* --- Preliminary adjustments and checks to data ------------------------------
* =============================================================================

* --- summing vertical ts input to default ones -------------------------------

// ts_influx_vert
$ifthen defined ts_influx_vert
// temporary node set of nodes in ts_influx_vert and ts_influx
option node_tmp < ts_influx_vert;
option node_tmp_ < ts_influx;

// checking that only one source of influx data for each node
loop(node_tmp(node),
    if(sum(node_tmp_(node), 1),
        put log '!!! Error on node ' node.tl:0 /;
        put log '!!! Abort: ts_inlux and ts_influx_vert defined for the same node!' /;
        abort "ts_inlux and ts_influx_vert defined for the same node!"
    );
);

// Adding vertical ts data to default
ts_influx(grid, node_tmp(node), f, t) = ts_influx(grid, node, f, t) + ts_influx_vert(t, grid, node, f);
$endif


// ts_cf_vert
$ifthen defined ts_cf_vert
// temporary node set of nodes in ts_cf_vert
option node_tmp < ts_cf_vert;
option node_tmp_ < ts_cf;

// checking that only one source of cf data each node
loop(node_tmp(node),
    if(sum(node_tmp_(node), 1),
        put log '!!! Error on node ' node.tl:0 /;
        put log '!!! Abort: ts_cf and ts_cf_vert defined for the same node!' /;
        abort "ts_cf and ts_cf_vert defined for the same node!"
    );
);

// Adding vertical ts data to default
ts_cf(flow, node_temp(node), f, t) = ts_cf(flow, node, f, t) + ts_cf_vert(t, flow, node, f);
$endif


* --- prechecking flow unit data ----------------------------------------------

// Units with flows/commodities
unit_flow(unit)${ sum(flow, flowUnit(flow, unit)) }
    = yes;

// few checks on flow unit input data
loop(unit_flow(unit),
    // Warn user and remove effLevelGroupUnit if flow unit has any
    if(sum(effLevelGroupUnit(effLevel, effSelector, unit), 1) > 0,
         put log '!!! Warning: Unit ', unit.tl:0, ' is flow unit, but has effLevels defined. Removing effLevelGroup data.' /;
        effLevelGroupUnit(effLevel, effSelector, unit) = no;
        );

    // Warn user and remove if flow unit has conversionCoeff parameter defined
    if(sum((grid, node, input_output), p_gnu_io(grid, node, unit, input_output, 'conversionCoeff')) > 0,
        put log '!!! Warning: Unit ', unit.tl:0, ' is flow unit, but has conversionCoeff parameter defined. Removing data.' /;
        p_gnu_io(grid, node, unit, input_output, 'conversionCoeff') = 0;
        );

    // Warn user and remove if flow unit has effXX or opXX parameters defined
    if(sum(op, p_unit(unit, op)) > 0,
         put log '!!! Warning: Unit ', unit.tl:0, ' is flow unit, but has opXX parameters defined. Removing op data.' /;
        p_unit(unit, op) = 0;
        );
    if(sum(eff, p_unit(unit, eff)) > 0,
         put log '!!! Warning: Unit ', unit.tl:0, ' is flow unit, but has effXX parameters defined. Removing eff data.' /;
        p_unit(unit, eff) = 0;
        );

); // END loop(unit_flow)


* =============================================================================
* --- Initialize Unit Related Sets & Parameters Based on Input Data -----------
* =============================================================================

* --- Generate Unit Related Sets ----------------------------------------------

p_gnu(grid, node, unit, param_gnu) = sum(input_output, p_gnu_io(grid, node, unit, input_output, param_gnu));

// Set of all existing gnu
gnu(grid, node, unit)${p_gnu(grid, node, unit, 'capacity')
                       or p_gnu(grid, node, unit, 'unitSize')
                       or p_gnu(grid, node, unit, 'conversionCoeff')
                      }
    = yes;

// Reduce the grid dimension
nu(node, unit) = sum(grid, gnu(grid, node, unit));
//p_gnu(grid, node, unit, 'capacity')$(p_gnu(grid, node, unit, 'capacity') = 0) = inf;

// Separation of gnu into inputs and outputs
gnu_output(gnu(grid, node, unit))${ p_gnu_io(grid, node, unit, 'output', 'capacity')
                                    or p_gnu_io(grid, node, unit, 'output', 'unitSize')
                                    or p_gnu_io(grid, node, unit, 'output', 'conversionCoeff')
                                    }
    = yes;
gnu_input(gnu(grid, node, unit))${  p_gnu_io(grid, node, unit, 'input', 'capacity')
                                    or p_gnu_io(grid, node, unit, 'input', 'unitSize')
                                    or p_gnu_io(grid, node, unit, 'input', 'conversionCoeff')
                                    }
    = yes;

// Units connecting gn-gn pairs
gn2gnu(grid, node_input, grid_, node_output, unit)${    gnu_input(grid, node_input, unit)
                                                        and gnu_output(grid_, node_output, unit)
                                                        }
    = yes;

// Units with minimum load requirements
unit_minLoad(unit)${    p_unit(unit, 'op00') > 0 // If the first defined operating point is between 0 and 1
                        and p_unit(unit, 'op00') < 1
                        // and if unit has online variable, then unit is considered to have minload
                        and sum(effLevel, sum(effOnline, effLevelGroupUnit(effLevel, effOnline, unit)))
                        }
    = yes;

// Units with investment variables
unit_invest(unit)$p_unit(unit, 'maxUnitCount') = yes;

unit_investLP(unit)${  not p_unit(unit, 'investMIP')
                       and p_unit(unit, 'maxUnitCount')
                        }
    = yes;
unit_investMIP(unit)${  p_unit(unit, 'investMIP')
                        and p_unit(unit, 'maxUnitCount')
                        }
    = yes;

// Units with special startup properties
// All units can cold start (default start category)
unitStarttype(unit, 'cold') = yes;
// Units with parameters regarding hot/warm starts
unitStarttype(unit, starttypeConstrained)${ p_unit(unit, 'startWarmAfterXhours')
                                            or sum(gnu(grid, node, unit), p_gnu(grid, node, unit, 'startCostHot'))
                                            or sum(gnu(grid, node, unit), p_gnu(grid, node, unit, 'startFuelConsHot'))
                                            or sum(gnu(grid, node, unit), p_gnu(grid, node, unit, 'startCostWarm'))
                                            or sum(gnu(grid, node, unit), p_gnu(grid, node, unit, 'startFuelConsWarm'))
                                            or p_unit(unit, 'startColdAfterXhours')
                                            }
    = yes;
// Units consuming energy from particular nodes in start-up
nu_startup(node, unit)$p_uStartupfuel(unit, node, 'fixedFuelFraction') = yes;

// Units with time series data enabled
unit_timeseries(unit)${ p_unit(unit, 'useTimeseries') or p_unit(unit, 'useTimeseriesAvailability') }
    = yes;

// formaing a set of units and their eq/gt constraints
option unitConstraint < ts_unitConstraintNode;
unitConstraint(unit, constraint)$sum(node$p_unitConstraintNode(unit, constraint, node), 1) = yes;

*// Units that have eq constraints between inputs and/or outputs
unit_eqConstrained(unit)${sum(eq_constraint(constraint), unitConstraint(unit, constraint)) } = yes;

// Units that have gt constraints between inputs and/or outputs
unit_gtConstrained(unit)${sum(gt_constraint(constraint), unitConstraint(unit, constraint)) } = yes;

// Units that have time series for eq or gt constraints between inputs and/or outputs
option tt < ts_unitConstraintNode;
unit_tsConstrained(unit)${sum((constraint, node, f, tt(t))$ts_unitConstraintNode(unit, constraint, node, f, t), 1) } = yes;


* --- Unit Related Parameters -------------------------------------------------

// Assume values for critical unit related parameters, if not provided by input data
// If the unit does not have efficiency set, it is 1. Except flow units.
p_unit(unit, 'eff00')${ not unit_flow(unit) and not p_unit(unit, 'eff00') and not p_unit(unit, 'eff01') and not p_unit(unit, 'eff02')}
    = 1;

// In case number of units has not been defined it is 1 except for units with investments allowed.
p_unit(unit, 'unitCount')${ not p_unit(unit, 'unitCount')
                            and not unit_investMIP(unit)
                            and not unit_investLP(unit)
                            }
    = 1;

// By default add outputs in order to get the total capacity of the unit
p_unit(unit, 'outputCapacityTotal')${ not p_unit(unit, 'outputCapacityTotal') }
    = sum(gnu_output(grid, node, unit), p_gnu(grid, node, unit, 'capacity'));
p_unit(unit, 'unitOutputCapacityTotal')
    = sum(gnu_output(grid, node, unit), p_gnu(grid, node, unit, 'unitSize'));

// Assume unit sizes based on given maximum capacity parameters and unit counts if able
p_gnu(gnu(grid, node, unit), 'unitSize')
    ${  not p_gnu(grid, node, unit, 'unitSize')
        and p_gnu(grid, node, unit, 'capacity')
        and p_unit(unit, 'unitCount')
        }
    = p_gnu(grid, node, unit, 'capacity') / p_unit(unit, 'unitCount'); // If capacity and unitCount are given, calculate unitSize based on them.

// Determine unit startup parameters based on data
// Hot startup parameters
p_uNonoperational(unitStarttype(unit, 'hot'), 'min')
    = p_unit(unit, 'minShutdownHours');
p_uNonoperational(unitStarttype(unit, 'hot'), 'max')
    = p_unit(unit, 'startWarmAfterXhours');
p_uStartup(unitStarttype(unit, 'hot'), 'cost')
    = sum(gnu(grid, node, unit), p_gnu(grid, node, unit, 'unitSize')
        * p_gnu(grid, node, unit, 'startCostHot'));
p_uStartup(unitStarttype(unit, 'hot'), 'consumption')
    = sum(gnu(grid, node, unit), p_gnu(grid, node, unit, 'unitSize')
        * p_gnu(grid, node, unit, 'startFuelConsHot'));

// Warm startup parameters
p_uNonoperational(unitStarttype(unit, 'warm'), 'min')
    = p_unit(unit, 'startWarmAfterXhours');
p_uNonoperational(unitStarttype(unit, 'warm'), 'max')
    = p_unit(unit, 'startColdAfterXhours');
p_uStartup(unitStarttype(unit, 'warm'), 'cost')
    = sum(gnu(grid, node, unit), p_gnu(grid, node, unit, 'unitSize')
        * p_gnu(grid, node, unit, 'startCostWarm'));
p_uStartup(unitStarttype(unit, 'warm'), 'consumption')
    = sum(gnu(grid, node, unit), p_gnu(grid, node, unit, 'unitSize')
        * p_gnu(grid, node, unit, 'startFuelConsWarm'));

// Cold startup parameters
p_uNonoperational(unitStarttype(unit, 'cold'), 'min')
    = p_unit(unit, 'startColdAfterXhours');
p_uStartup(unit, 'cold', 'cost')
    = sum(gnu(grid, node, unit), p_gnu(grid, node, unit, 'unitSize')
        * p_gnu(grid, node, unit, 'startCostCold'));
p_uStartup(unit, 'cold', 'consumption')
    = sum(gnu(grid, node, unit), p_gnu(grid, node, unit, 'unitSize')
        * p_gnu(grid, node, unit, 'startFuelConsCold'));

// Start-up fuel consumption per fuel
p_unStartup(unit, node, starttype)$p_uStartupfuel(unit, node, 'fixedFuelFraction')
    = p_uStartup(unit, starttype, 'consumption')
        * p_uStartupfuel(unit, node, 'fixedFuelFraction');

//shutdown cost parameters
p_uShutdown(unit, 'cost')
    = sum(gnu(grid, node, unit), p_gnu(grid, node, unit, 'unitSize')
        * p_gnu(grid, node, unit, 'shutdownCost'));

// Unit lifetime
loop(utAvailabilityLimits(unit, t, availabilityLimits),
    p_unit(unit, availabilityLimits) = ord(t)
); // END loop(ut)

* =============================================================================
* --- Generate Node Related Sets Based on Input Data --------------------------
* =============================================================================

* --- Node Connectivity -------------------------------------------------------

// Node pairs connected via transfer links
gn2n(grid, from_node, to_node)${    p_gnn(grid, from_node, to_node, 'transferCap')
                                    or p_gnn(grid, from_node, to_node, 'transferLoss')
                                    or p_gnn(grid, from_node, to_node, 'transferCapBidirectional')
                                    or p_gnn(grid, to_node, from_node, 'transferCapBidirectional')
                                    or p_gnn(grid, from_node, to_node, 'transferCapInvLimit')
                                    or p_gnn(grid, from_node, to_node, 'portion_of_transfer_to_reserve')
                                    }
    = yes;

// Node pairs with relatively bound states
gnn_boundState(grid, node, node_)${ p_gnn(grid, node, node_, 'boundStateMaxDiff') }
    = yes;

// Node pairs connected via energy diffusion
gnn_state(grid, node, node_)${  p_gnn(grid, node, node_, 'diffCoeff')
                                or gnn_boundState(grid, node, node_)
                                }
    = yes;

// Generate the set for transfer links where the order of the first node must be smaller than the order of the second node
Option clear = gn2n_directional;
gn2n_directional(gn2n(grid, node, node_))${ ord(node) < ord(node_) }
    = yes;
gn2n_directional(gn2n(grid, node, node_))${ ord(node) > ord(node_)
                                            and not gn2n(grid, node_, node)
                                            }
    = yes;

// Set for transfer links with investment possibility
Option clear = gn2n_directional_investLP;
Option clear = gn2n_directional_investMIP;
gn2n_directional_investLP(gn2n_directional(grid, node, node_))${ [p_gnn(grid, node, node_, 'transferCapInvLimit')
                                                                     or p_gnn(grid, node_, node, 'transferCapInvLimit')]
                                                                 and [not p_gnn(grid, node, node_, 'investMIP')
                                                                     and not p_gnn(grid, node_, node, 'investMIP')]
                                                                 }
    = yes;
gn2n_directional_investMIP(gn2n_directional(grid, node, node_))${ [p_gnn(grid, node, node_, 'transferCapInvLimit')
                                                                     or p_gnn(grid, node_, node, 'transferCapInvLimit')]
                                                                 and [p_gnn(grid, node, node_, 'investMIP')
                                                                     or p_gnn(grid, node_, node, 'investMIP')]
                                                                 }
    = yes;

// set for ramp constrained transfer links
gn2n_directional_rampConstrained(gn2n_directional(grid, node, node_))
             $  p_gnn(grid, node, node_, 'rampLimit')
    = yes;

* --- Timeseries parameters for node-node connections -------------------------

// Transfer links with time series enabled for certain parameters
gn2n_timeseries(grid, node, node_, 'availability')${p_gnn(grid, node, node_, 'useTimeseriesAvailability')}
    = yes;
gn2n_timeseries(grid, node, node_, 'transferLoss')${p_gnn(grid, node, node_, 'useTimeseriesLoss')}
    = yes;

* --- Node States -------------------------------------------------------------

// (grid, node) that has influx time series
option gn_influx < ts_influx;

// States with slack variables
gn_stateSlack(grid, node)${ sum((slack, useConstantOrTimeSeries), p_gnBoundaryPropertiesForStates(grid, node, slack, useConstantOrTimeSeries)) }
    = yes;

// Nodes with states
gn_state(grid, node)${  gn_stateSlack(grid, node)
                        or p_gn(grid, node, 'energyStoredPerUnitOfState')
                        or sum((stateLimits, useConstantOrTimeSeries), p_gnBoundaryPropertiesForStates(grid, node, stateLimits, useConstantOrTimeSeries))
                        or sum(useConstantOrTimeSeries, p_gnBoundaryPropertiesForStates(grid, node, 'reference', useConstantOrTimeSeries))
                        }
    = yes;

// Existing grid-node pairs
gn(grid, node)${    sum(unit, gnu(grid, node, unit))
                    or gn_influx(grid, node)
                    or gn_state(grid, node)
                    or sum(node_, gn2n(grid, node, node_))
                    or sum(node_, gn2n(grid, node_, node))
                    or sum(node_, gnn_state(grid, node, node_))
                    or sum(node_, gnn_state(grid, node_, node))
                    }
    = yes;

// Nodes with spill permitted
node_spill(node)${ sum((grid, spillLimits, useConstantOrTimeSeries), p_gnBoundaryPropertiesForStates(grid, node, spillLimits, useConstantOrTimeSeries)) }
    = yes;

// Nodes with balance and timeseries for boundary properties activated
gn_BoundaryType_ts(grid, node, param_gnBoundaryTypes)
    ${p_gn(grid, node, 'nodeBalance')
      and p_gnBoundaryPropertiesForStates(grid, node, param_gnBoundaryTypes, 'useTimeseries')
      }
    = yes;

// Assume values for critical node related parameters, if not provided by input data
// Boundary multiplier
p_gnBoundaryPropertiesForStates(gn(grid, node), param_gnBoundaryTypes, 'multiplier')${  not p_gnBoundaryPropertiesForStates(grid, node, param_gnBoundaryTypes, 'multiplier')
                                                                                        and sum(param_gnBoundaryProperties, p_gnBoundaryPropertiesForStates(grid, node, param_gnBoundaryTypes, param_gnBoundaryProperties))
    } = 1; // If multiplier has not been set, set it to 1 by default

* --- Node Classifications ----------------------------------------------------

// Nodes with flows
flowNode(flow, node)${  sum((f, t), ts_cf(flow, node, f, t))
                        and sum(grid, gn(grid, node))
                        }
    = yes;

* =============================================================================
* --- Initialize Price Related Sets & Parameters Based on Input Data -------
* =============================================================================

// checking nodes that have price data in two optional input data tables
option clear = node_tmp;
option node_tmp < ts_price;
option clear = node_tmp_;
option node_tmp_ < ts_priceChange;

// Process node prices depending on 'ts_price' if usePrice flag activated
loop(node_tmp(node) $ { sum(grid, p_gn(grid, node, 'usePrice'))},

    // Find the steps with changing node prices
    option clear = tt;
    tt(t)${ ts_price(node, t) } = yes;

    // If only up to a single value
    if({sum(tt, 1) <= 1 },
        p_price(node, 'useConstant') = 1; // Use a constant for node prices
        p_price(node, 'price') = sum(tt, ts_price(node, tt)) // Determine the price as the only value in the time series

    // If multiple values found, use time series. Values already given in input data.
    else
        p_price(node, 'useTimeSeries') = 1;
      ); // END if(sum(tt_))
); // END loop(node)

// Process node prices depending on 'ts_priceChange' if usePrice flag activated
loop(node_tmp_(node)$ { sum(grid, p_gn(grid, node, 'usePrice'))},

    // Find the steps with changing node prices
    option clear = tt;
    tt(t)${ ts_priceChange(node, t) } = yes;

    // If only up to a single value
    if({sum(tt, 1) <= 1 },
        p_price(node, 'useConstant') = 1; // Use a constant for node prices
        p_price(node, 'price') = sum(tt, ts_priceChange(node, tt)) // Determine the price as the only value in the time series

    // If multiple values found, use time series. Values processed in 3a_periodicInit
    else
        p_price(node, 'useTimeSeries') = 1;
      ); // END if(sum(tt_))
); // END loop(node)

loop(node_tmp(node),
    // Abort of input data for prices are given both ts_price and ts_priceChange
    if({node_tmp_(node)},
        put log '!!! Error occurred on ', node.tl:0 /;
        put log '!!! Abort: Node ', node.tl:0, ' has both ts_price and ts_priceChange' /;
        abort "Only ts_price or ts_priceChange can be given to a node"
    ); // END if
);

* =============================================================================
* --- Emission related Sets & Parameters --------------------------------------
* =============================================================================

// checking emissions that have price data in two optional input data tables
Option emission_priceData < ts_emissionPrice;
Option emission_priceChangeData < ts_emissionPriceChange;

// populating emissionGroup.
// Can use projection only once as the second time would overwrite. Using it to the most likely option.
Option emissionGroup < ts_emissionPrice;
emissionGroup(emission, group)${ sum(t, ts_emissionPriceChange(emission, group, t))
                                 or p_groupPolicyEmission(group, 'emissionCap', emission)
                               }
    = yes;

// Process emission group prices depending on 'ts_emissionPrice'
loop(emissionGroup(emission_priceData(emission), group),

    // Find the steps with changing node prices
    option clear = tt;
    tt(t)${ ts_emissionPrice(emission, group, t) } = yes;

    // If only up to a single value
    if(sum(tt, 1) <= 1,
        p_emissionPrice(emission, group, 'useConstant') = 1; // Use a constant for node prices
        p_emissionPrice(emission, group, 'price') = sum(tt, ts_emissionPrice(emission, group, tt)) // Determine the price as the only value in the time series

    // If multiple values found, use time series. Values already given in input data.
    else
        p_emissionPrice(emission, group, 'useTimeSeries') = 1;
      ); // END if(sum(tt))
); // END loop(emissionGroup)

// Process emission group prices depending on 'ts_emissionPriceChange'
loop(emissionGroup(emission_priceChangeData(emission), group),

    // Find the steps with changing node prices
    option clear = tt;
    tt(t)${ ts_emissionPriceChange(emission, group, t) } = yes;

    // If only up to a single value
    if(sum(tt, 1) <= 1,
        p_emissionPrice(emission, group, 'useConstant') = 1; // Use a constant for node prices
        p_emissionPrice(emission, group, 'price') = sum(tt, ts_emissionPriceChange(emission, group, tt)) // Determine the price as the only value in the time series

    // If multiple values found, use time series. Values processed in 3a_periodicInit
    else
        p_emissionPrice(emission, group, 'useTimeSeries') = 1;
      ); // END if(sum(tt))
); // END loop(emissionGroup)



* =============================================================================
* --- Reserves Sets & Parameters ----------------------------------------------
* =============================================================================
// NOTE! Reserves can be disabled through the model settings file.
// The sets are disabled in "3a_periodicInit.gms" accordingly.

* --- Correct values for critical reserve related parameters - Part 1 ---------

// Reserve activation duration assumed to be 1 hour if not provided in data
p_groupReserves(group, restype, 'reserve_activation_duration')
    ${  not p_groupReserves(group, restype, 'reserve_activation_duration')
        and p_groupReserves(group, restype, 'reserve_length')
        }
    = 1;
// Reserve reactivation time assumed to be 1 hour if not provided in data
p_groupReserves(group, restype, 'reserve_reactivation_time')
    ${  not p_groupReserves(group, restype, 'reserve_reactivation_time')
        and p_groupReserves(group, restype, 'reserve_length')
        }
    = 1;

* --- Copy reserve data and create necessary sets -----------------------------

// Copy data from p_groupReserves to p_gnReserves
p_gnReserves(grid, node, restype, param_policy) =
    sum(gnGroup(grid, node, group)${sum(restype_, p_groupReserves(group, restype_, 'reserve_length'))},
        p_groupReserves(group, restype, param_policy)
    );

// Units with reserve provision capabilities
gnuRescapable(restypeDirection(restype, up_down), gnu(grid, node, unit))
    $ { p_gnuReserves(grid, node, unit, restype, up_down)
      }
  = yes;

// Units with offline reserve provision capabilities
gnuOfflineRescapable(restype, gnu(grid, node, unit))
    $ { p_gnuReserves(grid, node, unit, restype, 'offlineReserveCapability')
      }
  = yes;

// Restypes with offline reserve provision possibility
offlineRes(restype)
    $ {sum(gnu(grid, node, unit),  p_gnuReserves(grid, node, unit, restype, 'offlineReserveCapability'))
      }
  = yes;

// Units with offline reserve provision possibility
offlineResUnit(unit)
    $ {sum((gn(grid, node), restype),  p_gnuReserves(grid, node, unit, restype, 'offlineReserveCapability'))
      }
  = yes;

// Node-node connections with reserve transfer capabilities
restypeDirectionGridNodeNode(restypeDirection(restype, up_down), gn2n(grid, node, node_))
    $ { p_gnnReserves(grid, node, node_, restype, up_down)
      }
  = yes;

// Nodes with reserve requirements, units capable of providing reserves, or reserve capable connections
restypeDirectionGridNode(restypeDirection(restype, up_down), gn(grid, node))
    $ { p_gnReserves(grid, node, restype, up_down)
        or p_gnReserves(grid, node, restype, 'useTimeSeries')
        or sum(gnu(grid, node, unit), p_gnuReserves(grid, node, unit, restype, 'portion_of_infeed_to_reserve'))
        or sum(gnu(grid, node, unit), gnuRescapable(restype, up_down, grid, node, unit))
        or sum(gn2n(grid, node, to_node), restypeDirectionGridNodeNode(restype, up_down, grid, node, to_node))
      }
  = yes;

// Groups with reserve requirements
restypeDirectionGroup(restypeDirection(restype, up_down), group)
    $ { p_groupReserves(group, restype, 'reserve_length')
      }
  = yes;
restypeDirectionGridNodeGroup(restypeDirection(restype, up_down), gnGroup(grid, node, group))
    $ { p_groupReserves(group, restype, 'reserve_length')
      }
  = yes;

* --- Correct values for critical reserve related parameters - Part 2 ---------

// Reserve reliability assumed to be perfect if not provided in data
p_gnuReserves(gnu(grid, node, unit), restype, 'reserveReliability')
    ${  not p_gnuReserves(grid, node, unit, restype, 'reserveReliability')
        and sum(up_down, gnuRescapable(restype, up_down, grid, node, unit))
        }
    = 1;

// Reserve provision overlap decreases the capacity of the overlapping category
loop(restype,
p_gnuReserves(gnu(grid, node, unit), restype, up_down)
    ${ gnuRescapable(restype, up_down, grid, node, unit) }
    = p_gnuReserves(grid, node, unit, restype, up_down)
        - sum(restype_${ p_gnuRes2Res(grid, node, unit, restype_, up_down, restype) },
            + p_gnuReserves(grid, node, unit, restype_, up_down)
                * p_gnuRes2Res(grid, node, unit, restype_, up_down, restype)
        ); // END sum(restype_)
);

* =============================================================================
* --- Policy related Sets & Parameters ----------------------------------------
* =============================================================================

// Filling a set of (group, param_policy) if there is series data
option groupPolicyTimeseries < ts_groupPolicy;




* =============================================================================
* --- Data Integrity Checks ---------------------------------------------------
* =============================================================================

* --- Check that nodes aren't assigned to multiple grids ----------------------

loop(node,
    if(sum(gn(grid, node), 1) > 1,
        put log '!!! Error occurred on node ' node.tl:0 /;
        loop(gn(grid, node),
               put log '!!! Error occurred on grid ' grid.tl:0 /;
        );
        put log '!!! Abort: Nodes cannot be assigned to multiple grids!' /;
        abort "Nodes cannot be assigned to multiple grids!"
    ); // END if(sum(gn))
); // END loop(node)

* --- Check that flow units have only one input or output ---------------------

loop(unit_flow(unit),
    if(sum(gnu(grid, node, unit), 1) > 1,
        put log '!!! Error occurred on unit ' unit.tl:0 /;
        put log '!!! Abort: Flow units cannot be assigned to multiple grids or nodes!' /;
        abort "Flow units cannot be assigned to multiple grids or nodes!"
    ); // END if(sum(gnu))
); // END loop(unit_flow)

* --- Check the integrity of node connection related data ---------------------

Option clear = count;
loop(gn2n(grid, node, node_),
    count = count + 1; // Count the gn2n indeces to make finding the errors easier.
    // Check if the bidirectional transfer parameter exists for this link.
    if(p_gnn(grid, node, node_, 'transferCapBidirectional'),
        // Check for conflicting bidirectional transfer capacities.
        if(p_gnn(grid, node, node_, 'transferCapBidirectional') <> p_gnn(grid, node_, node, 'transferCapBidirectional'),
            put log '!!! Error occurred on gn2n link ' node.tl:0 '-' node_.tl:0 /;
            put log '!!! Abort: Conflicting transferCapBidirectional parameters!' /;
            abort "Conflicting 'transferCapBidirectional' parameters!"
        );
        // Check for conflicting one-directional and bidirectional transfer capacities.
        if(p_gnn(grid, node, node_, 'transferCapBidirectional') < p_gnn(grid, node, node_, 'transferCap') OR (p_gnn(grid, node, node_, 'transferCapBidirectional') < p_gnn(grid, node_, node, 'transferCap')),
            put log '!!! Error occurred on gn2n link ' node.tl:0 '-' node_.tl:0 /;
            put log '!!! Abort: Parameter transferCapBidirectional must be greater than or equal to defined one-directional transfer capacities!' /;
            abort "Parameter 'transferCapBidirectional' must be greater than or equal to defined one-directional transfer capacities!"
        );
    );
    // Check if transfer ramprate limit exists for this link.
    if(p_gnn(grid, node, node_, 'rampLimit'),
        // Check for conflicting ramp limits
        if(   [p_gnn(grid, node, node_, 'rampLimit')>0] and [p_gnn(grid, node_, node, 'rampLimit')=0],
            put log '!!! Error occurred on gn2n link ' node.tl:0 '-' node_.tl:0 /;
            put log '!!! Abort: ' node.tl:0 '->' node_.tl:0 ' has rampLimit, but ' node_.tl:0 '->' node.tl:0 ' does not' /;
            abort "Conflicting transfer 'rampLimit' definitions!"
        );
        if(   [p_gnn(grid, node_, node, 'rampLimit')>0] and [p_gnn(grid, node, node_, 'rampLimit')=0],
            put log '!!! Error occurred on gn2n link ' node.tl:0 '-' node_.tl:0 /;
            put log '!!! Abort: ' node_.tl:0 '->' node.tl:0 ' has rampLimit, but ' node.tl:0 '->' node_.tl:0 ' does not' /;
            abort "Conflicting transfer 'rampLimit' definitions!"
        );
    );

    if(p_gnn(grid, node, node_, 'rampLimit'),
        // Check for conflicting ramp limits
        if(p_gnn(grid, node, node_, 'rampLimit')*p_gnn(grid, node, node_, 'transferCap') <> p_gnn(grid, node_, node, 'rampLimit')*p_gnn(grid, node_, node, 'transferCap'),
            put log '!!! Warning: ' node.tl:0 '-' node_.tl:0 ' rampLimit * transfCapacity is not equal to different directions. Will use values from ' node.tl:0 /;
        );
    );
);

* --- Check node balance and price related data -------------------------------

loop(node,
    // Give a warning if both nodeBalance and usePrice are false
    if(not sum(grid, p_gn(grid, node, 'nodeBalance') or p_gn(grid, node, 'usePrice')),
        put log '!!! Warning: Node ', node.tl:0, ' does not have nodeBalance or usePrice activated in p_gn' /;
    ); // END if
    // Give a warning if both nodeBalance and usePrice are true
    if(sum(grid, p_gn(grid, node, 'nodeBalance') and p_gn(grid, node, 'usePrice')),
        put log '!!! Warning: Node ', node.tl:0, ' has both nodeBalance or usePrice activated in p_gn' /;
    ); // END if
    // Give a warning if usePrice is true but there is no price data
    if(sum(grid, p_gn(grid, node, 'usePrice'))
       and not [p_price(node, 'price') or p_price(node, 'useTimeSeries')],
        put log '!!! Warning: Node ', node.tl:0, ' has usePrice activated in p_gn but there is no price data' /;
    ); // END if
); // END loop(node)

* --- Check the integrity of efficiency approximation related data ------------

Option clear = tmp;
// Find the largest effLevel used in the data
tmp = smax(effLevelGroupUnit(effLevel, effSelector, unit), ord(effLevel));

// Expand the effLevelGroupUnit when possible, abort if impossible
loop(effLevel${ord(effLevel)<=tmp},
    effLevelGroupUnit(effLevel, effSelector, unit)
        ${not sum(effLevelGroupUnit(effLevel, effSelector_, unit), 1)}
        = effLevelGroupUnit(effLevel - 1, effSelector, unit) // Expand previous (effLevel, effSelector) when applicable
    loop(unit${not unit_flow(unit) },
        If(not sum(effLevelGroupUnit(effLevel, effSelector, unit), 1),
            put log '!!! Error on unit ' unit.tl:0 /;
            put log '!!! Abort: Insufficient effLevelGroupUnit definitions!' /;
            abort "Insufficient effLevelGroupUnit definitions!"
        );
    );
);

loop( unit$ {not unit_flow(unit)},
    // Check that 'op' is defined correctly
    Option clear = count; // Initialize the previous op to zero
    loop( op,
        if (p_unit(unit, op) + 1${not p_unit(unit, op)} < count,
            put log '!!! Error occurred on unit ' unit.tl:0 /; // Display unit that causes error
            put log '!!! Abort: param_unit op must be defined as zero or positive and increasing!' /;
            abort "param_unit 'op's must be defined as zero or positive and increasing!";
        ); // END if(p_unit)
        count = p_unit(unit, op);
    ); // END loop(op)
    // Check that efficiency approximations have sufficient data

    // Check that directOnLP and directOnMIP units have least one opXX or hrXX defined
    loop(effLevelGroupUnit(effLevel, effDirectOn(effSelector), unit),
       if(sum(op, p_unit(unit, op)) + sum(hr, p_unit(unit, hr))= 0,
             put log '!!! Error occurred on unit ' unit.tl:0 /; // Display unit that causes error
             put log '!!! Abort: Units with online variable, e.g. DirectOnLP and DirectOnMIP, require efficiency definitions, check opXX (or hrXX) parameters' /;
             abort "Units with online variable, e.g. DirectOnLP and DirectOnMIP, require efficiency definitions, check opXX (or hrXX) parameters";
          );
    );

    // Check that if directOnLP and directOnMIP units are defined with op parameters (hr parameters alternative), those have sufficient values
    loop( effLevelGroupUnit(effLevel, effSelector, unit),
        loop( op__${p_unit(unit, op__) = smax(op, p_unit(unit, op))}, // Loop over the 'op's to find the last defined data point.
            loop( op_${p_unit(unit, op_) = smin(op${p_unit(unit, op)}, p_unit(unit, op))}, // Loop over the 'op's to find the first nonzero 'op' data point.
                if(effDirectOn(effSelector) AND ord(op__) = ord(op_) AND not p_unit(unit, 'section') AND not p_unit(unit, 'opFirstCross'),
                    put log '!!! Error occurred on unit ' unit.tl:0 /; // Display unit that causes error
                    put log '!!! Abort: directOn requires two efficiency data points with nonzero op or section or opFirstCross!' /;
                    abort "directOn requires two efficiency data points with nonzero 'op' or 'section' or 'opFirstCross'!";
                ); // END if(effDirectOn)
            ); // END loop(op_)
        ); // END loop(op__)
    ); // END loop(effLevelGroupUnit)

    // Check that if unit has opXX defined, there is matching effXX defined
    loop(effLevelGroupUnit(effLevel, effSelector, unit),
       loop(op $ p_unit(unit, op),
          if(sum(eff, p_unit(unit, eff)${ord(eff) = ord(op)}) = 0,
             put log '!!! Error occurred on unit ' unit.tl:0 /; // Display unit that causes error
             put log '!!! Abort: unit ', unit.tl:0, ' has ', op.tl:0, ' defined, but empty mathcing eff parameter'  /;
             abort "Each opXX requires mathcing effXX";
             );
       );
    );

    // give a warning if directOff unit has startcost defined
    if( {effLevelGroupUnit('level1', 'directOff', unit)
         and sum(gnu(grid, node, unit), sum(input_output, p_gnu_io(grid, node, unit, input_output, 'startCostCold'))) },
             put log '!!! Warning: unit (', unit.tl:0, ' has start costs, but is a directOff unit that disables start cost calculations' /;
    );

); //loop(unit)

* --- Check startupfuel fraction related data ----------------------------------------

loop( unit${sum(starttype$p_uStartup(unit, starttype, 'consumption'), 1)},
    if(sum(node, p_uStartupfuel(unit, node, 'fixedFuelFraction')) <> 1,
        put log '!!! Error occurred on unit ' unit.tl:0 /;
        put log '!!! Abort: The sum of fixedFuelFraction over start-up fuels needs to be one for all units using start-up fuels!' /;
        abort "The sum of 'fixedFuelFraction' over start-up fuels needs to be one for all units using start-up fuels!"
    );
);

option tt < ts_unitConstraintNode;
// checking that each constraint has at least two nodes defined
loop( unit${sum((constraint)$p_unitConstraint(unit, constraint), 1)},
     if({sum((constraint, node)$p_unitConstraintNode(unit, constraint, node), 1)
        +sum((constraint, node, f, tt(t))$ts_unitConstraintNode(unit, constraint, node, f, t), 1)} < 2,
        put log '!!! Error occurred on unit ' unit.tl:0 /;
        put log '!!! Abort: constraint requires at least two inputs or outputs!' /;
        abort "a constraint has to have more than one input or output!"
    ); // END if
); // END loop(unit)

// checking that none of the (node, unit) is defined both in p_unitConstraint and ts_unitConstraint
loop(nu(node, unit)${sum(constraint$p_unitConstraintNode(unit, constraint, node), 1)},
    if({sum((constraint)$p_unitConstraintNode(unit, constraint, node), 1) and
        sum((constraint, f, tt(t))$ts_unitConstraintNode(unit, constraint, node, f, t), 1)},
        put log '!!! Error occurred on (node, unit): (' node.tl:0 ',' unit.tl:0 ')'/;
        put log '!!! Abort: Constraint node for one unit cannot be defined in p_unitConstraintNode and in ts_unitConstraintNode!' /;
        abort "a constraint (unit, node) has been defined in p_unitConstraintNode and in ts_unitConstraintNode. Choose only one!"
    ); // END if
); // END loop(nu)

* --- Check the shutdown time related data ------------------------------------

loop( unitStarttype(unit, starttypeConstrained),
    if(p_unit(unit, 'minShutdownHours') > p_unit(unit, 'startWarmAfterXhours')
        or p_unit(unit, 'startWarmAfterXhours') > p_unit(unit, 'startColdAfterXhours'),
        put log '!!! Error occurred on unit ', unit.tl:0 /;
        put log '!!! Abort: Units should have p_unit(unit, minShutdownHours) <= p_unit(unit, startWarmAfterXhours) <= p_unit(unit, startColdAfterXhours)!' /;
        abort "Units should have p_unit(unit, 'minShutdownHours') <= p_unit(unit, 'startWarmAfterXhours') <= p_unit(unit, 'startColdAfterXhours')!"
    );
);

* --- Check emission related data ---------------------------------------------

loop(emissionGroup(emission, group),
    // Abort if input data for prices are given both ts_emissionPrice and ts_emissionPriceChange
    if({emission_priceData(emission) and emission_priceChangeData(emission)},
        put log '!!! Error occurred on emissionGroup ', group.tl:0, ', with emission ', emission.tl:0 /;
        put log '!!! Abort: EmissionGroup (', group.tl:0, ', ', emission.tl:0, ') has both ts_emissionPrice and ts_emissionPriceChange' /;
        abort "Only ts_emissionPrice or ts_emissionPriceChange can be given to an emissionGroup"
    ); // END if
); // END loop(emissionGroup)

// checking that invEmissionFactor
option gnu_tmp < p_gnuEmission;
loop(gnu_tmp(grid, node, unit),
    loop(emission$p_gnuEmission(grid, node, unit, emission, 'invEmissions'),
        if(not p_gnuEmission(grid, node, unit, emission, 'invEmissionsFactor'),
           put log '!!! Warning: (grid, node, unit, emission) (', grid.tl:0 ,',', node.tl:0 ,',', unit.tl:0 ,',', emission.tl:0 ,',', ') has invEmissions>0, but invEmissionsFactor is empty. Assuming 1.' /;
           p_gnuEmission(grid, node, unit, emission, 'invEmissionsFactor') = 1;
        ); // END if
    ); // END loop(emission)
); // END loop(gnu_tmp)


* --- Check reserve related data ----------------------------------------------

loop( restypeDirectionGroup(restype, up_down, group),
    // Check that reserve_length is long enough for proper commitment of reserves
    if(p_groupReserves(group, restype, 'reserve_length') < p_groupReserves(group, restype, 'update_frequency') + p_groupReserves(group, restype, 'gate_closure'),
        put log '!!! Error occurred on group ', group.tl:0 /;
        put log '!!! Abort: The reserve_length parameter should be longer than update_frequency + gate_closure to fix the reserves properly!' /;
        abort "The 'reserve_length' parameter should be longer than 'update_frequency' + 'gate_closure' to fix the reserves properly!"
    ); // END if
    // Check that the duration of reserve activation is less than the reserve reactivation time
    if(p_groupReserves(group, restype, 'reserve_reactivation_time') < p_groupReserves(group, restype, 'reserve_activation_duration'),
        put log '!!! Error occurred on group ', group.tl:0 /;
        put log '!!! Abort: The reserve_reactivation_time should be greater than or equal to the reserve_activation_duration!' /;
        abort "The reserve_reactivation_time should be greater than or equal to the reserve_activation_duration!"
    ); // END if
); // END loop(restypeDirectionGroup)

loop( restypeDirectionGridNode(restype, up_down, grid, node),
    // Check for each restype that a node does not belong to multiple groups
    if(sum(restypeDirectionGridNodeGroup(restype, up_down, grid, node, group), 1) > 1,
        put log '!!! Error occurred on node ', node.tl:0 /;
        put log '!!! Abort: For each reserve type, a node can belong to at maximum one reserve node group!' /;
        abort "For each reserve type, a node can belong to at maximum one reserve node group!"
    ); // END if
    // Check if there are units/interconnections connected to a node that does not belong to any restypeDirectionGroup
    if(sum(restypeDirectionGridNodeGroup(restype, up_down, grid, node, group), 1) < 1,
        put log '!!! Error occurred on node ', node.tl:0 /;
        put log '!!! Abort: A node with reserve provision/transfer capability has to belong to a reserve node group!' /;
        abort "A node with reserve provision/transfer capability has to belong to a reserve node group!"
    ); // END if
); // END loop(restypeDirectionGridNode)

// Check that reserve overlaps are possible
loop( (gnu(grid, node, unit), restypeDirection(restype, up_down)),
    if( p_gnuReserves(grid, node, unit, restype, up_down) < 0,
        put log '!!! Error occurred on unit ', unit.tl:0 /;
        put log '!!! Abort: Overlapping reserve capacities in p_gnuRes2Res can result in excess reserve production!' /;
        abort "Overlapping reserve capacities in p_gnuRes2Res can result in excess reserve production!"
    ); // END if(p_gnuReserves)
); // END loop((gnu,restypeDirection))

* --- Check investment related data -------------------------------------------

// Check that units with LP investment possibility have unitSize
loop( unit_investLP(unit),
    if(not sum(gnu(grid, node, unit), abs(p_gnu(grid, node, unit, 'unitSize'))),
        put log '!!! Error occurred on unit ', unit.tl:0 /;
        put log '!!! Abort: Unit is listed as an investment option but it has no unitSize!' /;
        abort "All units with investment possibility should have 'unitSize' in p_gnu!"
    ); // END if
); // END loop(unit_investLP)
// Check that units with MIP investment possibility have unitSize
loop( unit_investMIP(unit),
    if(not sum(gnu(grid, node, unit), abs(p_gnu(grid, node, unit, 'unitSize'))),
        put log '!!! Error occurred on unit ', unit.tl:0 /;
        put log '!!! Abort: Unit is listed as an investment option but it has no unitSize!' /;
        abort "All units with investment possibility should have 'unitSize' in p_gnu!"
    ); // END if
); // END loop(unit_investMIP)

* --- Check consistency of inputs for superposed node states -------------------

* no checking yet because node_superpos is not given in the gdx input


* =============================================================================
* --- Default values  ---------------------------------------------------------
* =============================================================================

* By default all nodes use forecasts for all timeseries
gn_forecasts(gn, timeseries) = yes;
gn_forecasts(flowNode, timeseries) = yes;
gn_forecasts(restype, node, 'ts_reserveDemand') = yes;

* By default all units use forecasts for all timeseries
unit_forecasts(unit, timeseries) = yes;
