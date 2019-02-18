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

$gdxin  '%input_dir%/inputData.gdx'
$loaddc grid
$loaddc node
$loaddc flow
$loaddc unittype
$loaddc unit
$loaddc unitUnittype
$loaddc unit_fail
$loaddc fuel
$loaddc unitUnitEffLevel
$loaddc uFuel
$loaddc effLevelGroupUnit
$loaddc p_gn
$loaddc p_gnn
$loaddc p_gnu
$loaddc p_gnuBoundaryProperties
$loaddc p_unit
$loaddc ts_unit
$loaddc restype
$loaddc restypeDirection
$loaddc restypeReleasedForRealization
$loaddc p_nReserves
$loaddc p_nuReserves
$loaddc p_nnReserves
$loaddc p_nuRes2Res
$loaddc ts_reserveDemand
$loaddc p_gnBoundaryPropertiesForStates
$loaddc p_gnPolicy
$loaddc p_uFuel
$loaddc flowUnit
$loaddc gngnu_fixedOutputRatio
$loaddc gngnu_constrainedOutputRatio
$loaddc emission
$loaddc p_fuelEmission
$loaddc ts_cf
$loaddc ts_fuelPriceChange
$loaddc ts_influx
$loaddc ts_node
$loaddc t_invest
$loaddc p_storageValue
$loaddc group
$loaddc uGroup
$loaddc gnuGroup
$loaddc gn2nGroup
$loaddc gnGroup
$loaddc p_groupPolicy
$loaddc p_groupPolicy3D
$loaddc gnss_bound
$gdxin

$ifthen exist '%input_dir%/includeInputData_ext.inc'
   $$include '%input_dir%/includeInputData_ext.inc'
$endif

$ifthen exist '%input_dir%/changes.inc'
   $$include '%input_dir%/changes.inc'
$endif


* =============================================================================
* --- Initialize Unit Related Sets & Parameters Based on Input Data -----------
* =============================================================================


* --- Generate Unit Related Sets ----------------------------------------------

// Set of all existing gnu
gnu(grid, node, unit)${ p_gnu(grid, node, unit, 'maxGen')
                        or p_gnu(grid, node, unit, 'maxCons')
                        or p_gnu(grid, node, unit, 'unitSizeGen')
                        or p_gnu(grid, node, unit, 'unitSizeCons')
                        }
    = yes;
// Reduce the grid dimension
nu(node, unit) = sum(grid, gnu(grid, node, unit));

// Separation of gnu into inputs and outputs
gnu_output(gnu(grid, node, unit))${ p_gnu(grid, node, unit, 'maxGen')
                                    or p_gnu(grid, node, unit, 'unitSizeGen')
                                    }
    = yes;
gnu_input(gnu(grid, node, unit))${  p_gnu(grid, node, unit, 'maxCons')
                                    or p_gnu(grid, node, unit, 'unitSizeCons')
                                    }
    = yes;

// Units connecting gn-gn pairs
gn2gnu(grid, node_input, grid_, node_output, unit)${    gnu_input(grid, node_input, unit)
                                                        and gnu_output(grid_, node_output, unit)
                                                        }
    = yes;

// Units with minimum load requirements
unit_minload(unit)${    p_unit(unit, 'op00') > 0 // If the first defined operating point is between 0 and 1, then the unit is considered to have a min load limit
                        and p_unit(unit, 'op00') < 1
                        }
    = yes;

// Units with flows/fuels
unit_flow(unit)${ sum(flow, flowUnit(flow, unit)) }
    = yes;
unit_fuel(unit)${ sum(fuel, uFuel(unit, 'main', fuel)) }
    = yes;

// Units with investment variables
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
                                            or p_unit(unit, 'startCostHot')
                                            or p_unit(unit, 'startFuelConsHot')
                                            or p_unit(unit, 'startCostWarm')
                                            or p_unit(unit, 'startFuelConsWarm')
                                            or p_unit(unit, 'startColdAfterXhours')
                                            }
    = yes;


* --- Unit Related Parameters -------------------------------------------------

// Assume values for critical unit related parameters, if not provided by input data
// If the unit does not have efficiency set, it is 1
p_unit(unit, 'eff00')${ not p_unit(unit, 'eff00') }
    = 1;

// In case number of units has not been defined it is 1 except for units with investments allowed.
p_unit(unit, 'unitCount')${ not p_unit(unit, 'unitCount')
                            and not unit_investMIP(unit)
                            and not unit_investLP(unit)
                            }
    = 1;

// By default add outputs in order to get the total capacity of the unit
p_unit(unit, 'outputCapacityTotal')${ not p_unit(unit, 'outputCapacityTotal') }
    = sum(gnu_output(grid, node, unit), p_gnu(grid, node, unit, 'maxGen'));
p_unit(unit, 'unitOutputCapacityTotal')
    = sum(gnu_output(grid, node, unit), p_gnu(grid, node, unit, 'unitSizeGen'));

// Assume unit sizes based on given maximum capacity parameters and unit counts if able
p_gnu(grid, node, unit, 'unitSizeGen')${    p_gnu(grid, node, unit, 'maxGen')
                                            and p_unit(unit, 'unitCount')
                                            }
    = p_gnu(grid, node, unit, 'maxGen') / p_unit(unit, 'unitCount');  // If maxGen and unitCount are given, calculate unitSizeGen based on them.
p_gnu(grid, node, unit, 'unitSizeCons')${   p_gnu(grid, node, unit, 'maxCons')
                                            and p_unit(unit, 'unitCount')
                                            }
    = p_gnu(grid, node, unit, 'maxCons') / p_unit(unit, 'unitCount');  // If maxCons and unitCount are given, calculate unitSizeCons based on them.
p_gnu(grid, node, unit, 'unitSizeTot')
    = p_gnu(grid, node, unit, 'unitSizeGen') + p_gnu(grid, node, unit, 'unitSizeCons');

// Determine unit startup parameters based on data
// Hot startup parameters
p_uNonoperational(unitStarttype(unit, 'hot'), 'min')
    = p_unit(unit, 'minShutdownHours');
p_uNonoperational(unitStarttype(unit, 'hot'), 'max')
    = p_unit(unit, 'startWarmAfterXhours');
p_uStartup(unitStarttype(unit, 'hot'), 'cost')
    = p_unit(unit, 'startCostHot')
        * sum(gnu_output(grid, node, unit), p_gnu(grid, node, unit, 'unitSizeGen'));
p_uStartup(unitStarttype(unit, 'hot'), 'consumption')
    = p_unit(unit, 'startFuelConsHot')
        * sum(gnu_output(grid, node, unit), p_gnu(grid, node, unit, 'unitSizeGen'));

// Warm startup parameters
p_uNonoperational(unitStarttype(unit, 'warm'), 'min')
    = p_unit(unit, 'startWarmAfterXhours');
p_uNonoperational(unitStarttype(unit, 'warm'), 'max')
    = p_unit(unit, 'startColdAfterXhours');
p_uStartup(unitStarttype(unit, 'warm'), 'cost')
    = p_unit(unit, 'startCostWarm')
        * sum(gnu_output(grid, node, unit), p_gnu(grid, node, unit, 'unitSizeGen'));
p_uStartup(unitStarttype(unit, 'warm'), 'consumption')
    = p_unit(unit, 'startFuelConsWarm')
        * sum(gnu_output(grid, node, unit), p_gnu(grid, node, unit, 'unitSizeGen'));

// Cold startup parameters
p_uNonoperational(unitStarttype(unit, 'cold'), 'min')
    = p_unit(unit, 'startColdAfterXhours');
p_uStartup(unit, 'cold', 'cost')
    = p_unit(unit, 'startCostCold')
        * sum(gnu_output(grid, node, unit), p_gnu(grid, node, unit, 'unitSizeGen'));
p_uStartup(unit, 'cold', 'consumption')
    = p_unit(unit, 'startFuelConsCold')
        * sum(gnu_output(grid, node, unit), p_gnu(grid, node, unit, 'unitSizeGen'));

// Determine unit emission costs
p_unitFuelEmissionCost(unit_fuel, fuel, emission)${ sum(param_fuel, uFuel(unit_fuel, param_fuel, fuel)) }
    = p_fuelEmission(fuel, emission)
        / 1e3 // NOTE!!! Conversion to t/MWh from kg/MWh in data
        * sum(gnu_output(grid, node, unit_fuel),
            + p_gnPolicy(grid, node, 'emissionTax', emission)  // Weighted average of emission costs from different output energy types
                * [ + p_gnu(grid, node, unit_fuel, 'maxGen')
                    + p_gnu(grid, node, unit_fuel, 'unitSizeGen')${not p_gnu(grid, node, unit_fuel, 'maxGen')}
                    ] // END * p_gnPolicy
        ) // END sum(gnu_output)
        / sum(gnu_output(grid, node, unit_fuel), // Weighted average of emission costs from different output energy types
            + p_gnu(grid, node, unit_fuel, 'maxGen')
            + p_gnu(grid, node, unit_fuel, 'unitSizeGen')$(not p_gnu(grid, node, unit_fuel, 'maxGen'))
        ) // END sum(gnu_output)
;

// If the start-up fuel fraction is not defined, it equals 1
p_uFuel(uFuel(unit_fuel, 'startup', fuel), 'fixedFuelFraction')${ not p_uFuel(unit_fuel, 'startup', fuel, 'fixedFuelFraction') }
    = 1;

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

* --- Node States -------------------------------------------------------------

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
                    or gn_state(grid, node)
                    or sum((f, t), ts_influx(grid, node, f, t))
                    }
    = yes;

// Nodes with spill permitted
node_spill(node)${ sum((grid, spillLimits, useConstantOrTimeSeries), p_gnBoundaryPropertiesForStates(grid, node, spillLimits, useConstantOrTimeSeries)) }
    = yes;

// Assume values for critical node related parameters, if not provided by input data
// Boundary multiplier
p_gnBoundaryPropertiesForStates(gn(grid, node), param_gnBoundaryTypes, 'multiplier')${  not p_gnBoundaryPropertiesForStates(grid, node, param_gnBoundaryTypes, 'multiplier')
                                                                                        and sum(param_gnBoundaryProperties, p_gnBoundaryPropertiesForStates(grid, node, param_gnBoundaryTypes, param_gnBoundaryProperties))
    } = 1; // If multiplier has not been set, set it to 1 by default

* --- Other Node Properties ---------------------------------------------------

// Nodes with flows
flowNode(flow, node)${  sum((f, t), ts_cf(flow, node, f, t))
                        and sum(grid, gn(grid, node))
                        }
    = yes;

* =============================================================================
* --- Reserves Sets & Parameters ----------------------------------------------
* =============================================================================
// NOTE! Reserves can be disabled through the model settings file.
// The sets are disabled in "3a_periodicInit.gms" accordingly.

// Units with reserve provision capabilities
nuRescapable(restypeDirection(restype, up_down), nu(node, unit))
    $ { p_nuReserves(node, unit, restype, up_down)
      }
  = yes;

// Node-node connections with reserve transfer capabilities
restypeDirectionNodeNode(restypeDirection(restype, up_down), node, node_)
    $ { p_nnReserves(node, node_, restype, up_down)
      }
  = yes;

// Nodes with reserve requirements, units capable of providing reserves, or reserve capable connections
restypeDirectionNode(restypeDirection(restype, up_down), node)
    $ { p_nReserves(node, restype, up_down)
        or p_nReserves(node, restype, 'use_time_series')
        or p_nReserves(node, restype, 'Infeed2Cover')
        or sum(nu(node, unit), nuRescapable(restype, up_down, node, unit))
        or sum(gn2n(grid, node, to_node), restypeDirectionNodeNode(restype, up_down, node, to_node))
      }
  = yes;

// Assume values for critical reserve related parameters, if not provided by input data
// Reserve reliability assumed to be perfect if not provided in data
p_nuReserves(nu(node, unit), restype, 'reserveReliability')
    ${  not p_nuReserves(node, unit, restype, 'reserveReliability')
        and sum(up_down, nuRescapable(restype, up_down, node, unit))
        }
    = 1;

* =============================================================================
* --- Data Integrity Checks ---------------------------------------------------
* =============================================================================

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
);

* --- Check the integrity of efficiency approximation related data ------------

Option clear = tmp;
// Find the largest effLevel used in the data
tmp = smax(effLevelGroupUnit(effLevel, effSelector, unit), ord(effLevel));

loop( unit,
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
);

* --- Check the start-up fuel fraction related data ---------------------------

loop( unit_fuel(unit)${sum(fuel, uFuel(unit_fuel, 'startup', fuel))},
    if(sum(fuel, p_uFuel(unit, 'startup', fuel, 'fixedFuelFraction')) <> 1,
        put log '!!! Error occurred on unit ' unit.tl:0 /;
        put log '!!! Abort: The sum of fixedFuelFraction over start-up fuels needs to be one for all units using start-up fuels!' /;
        abort "The sum of 'fixedFuelFraction' over start-up fuels needs to be one for all units using start-up fuels!"
    );
);

* --- Check the shutdown time related data ------------------------------------

loop( unitStarttype(unit, starttypeConstrained),
    if(p_unit(unit, 'minShutdownHours') > p_unit(unit, 'startWarmAfterXhours')
        or p_unit(unit, 'startWarmAfterXhours') > p_unit(unit, 'startColdAfterXhours'),
        put log '!!! Error occurred on unit ', unit.tl:0 /;
        put log '!!! Abort: Units should have p_unit(unit, minShutdownHours) <= p_unit(unit, startWarmAfterXhours) <= p_unit(unit, startColdAfterXhours)!' /;
        abort "Units should have p_unit(unit, 'minShutdownHours') <= p_unit(unit, 'startWarmAfterXhours') <= p_unit(unit, 'startColdAfterXhours')!"
    );
);

* --- Check reserve structure data --------------------------------------------

// Check that reserve_length is long enough for properly commitment of reserves
loop( restypeDirectionNode(restype, up_down, node),
    if(p_nReserves(node, restype, 'reserve_length') < p_nReserves(node, restype, 'update_frequency') + p_nReserves(node, restype, 'gate_closure'),
        put log '!!! Error occurred on node ', node.tl:0 /;
        put log '!!! Abort: The reserve_length parameter should be longer than update_frequency + gate_closure to fix the reserves properly!' /;
        abort "The 'reserve_length' parameter should be longer than 'update_frequency' + 'gate_closure' to fix the reserves properly!"
    ); // END if
); // END loop(restypeDirectionNode)
