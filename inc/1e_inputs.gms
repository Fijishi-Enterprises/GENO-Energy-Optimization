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

$gdxin  'input/inputData.gdx'
$loaddc grid
$loaddc node
$loaddc flow
$loaddc unittype
$loaddc unit
$loaddc unitUnittype
$loaddc fuel
$loaddc unitUnit_aggregate
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
$loaddc ts_nodeState
$loaddc t_invest
$loaddc group
$loaddc uGroup
$loaddc gnuGroup
$loaddc gn2nGroup
$loaddc gnGroup
$loaddc p_groupPolicy
$loaddc p_groupPolicy3D
$gdxin

$ontext
 * Load stochastic scenarios
 $batinclude 'inc/gdxload_fluctuation.inc' wind
 $batinclude 'inc/gdxload_fluctuation.inc' solar
 $ifthen exist 'input/scenarios_hydro.gdx'
    $$gdxin 'input/scenarios_hydro.gdx'
 $endif
 $gdxin
$offtext
$ifthen exist 'input/changes.inc'
   $$include 'input/changes.inc'
$endif


* =============================================================================
* --- Initialize Unit Related Sets & Parameters Based on Input Data -----------
* =============================================================================

* --- Unit Aggregation --------------------------------------------------------

// Define unit aggregation sets
unit_aggregate(unit)${ sum(unit_, unitUnit_aggregate(unit, unit_)) }
    = yes; // Set of aggregate units
unit_noAggregate(unit)${ unit(unit) - unit_aggregate(unit) - sum(unit_, unitUnit_aggregate(unit_, unit))}
    = yes; // Set of units that are not aggregated into any aggregate, or are not aggregates themselves

// Process data for unit aggregations
// Aggregate maxGen as the sum of aggregated maxGen
p_gnu(grid, node, unit_aggregate(unit), 'maxGen')
    = sum(unit_${unitUnit_aggregate(unit, unit_)},
        + p_gnu(grid, node, unit_, 'maxGen')
        );
// Aggregate maxCons as the sum of aggregated maxCons
p_gnu(grid, node, unit_aggregate(unit), 'maxCons')
    = sum(unit_${unitUnit_aggregate(unit, unit_)},
        + p_gnu(grid, node, unit_, 'maxCons')
        );

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

// Units with reserve provision capabilities
nuRescapable(restypeDirection(restype, up_down), nu(node, unit))${ p_nuReserves(node, unit, restype, up_down) }
    = yes;

// Units with minimum load requirements
unit_minload(unit)${    p_unit(unit, 'op00') > 0 // If the first defined operating point is between 0 and 1, then the unit is considered to have a min load limit
                        and p_unit(unit, 'op00') < 1
                        }
    = yes;

// Units with online variables in the effLevel 'level1'
unit_online(unit)${ sum(effSelector$effOnline(effSelector), effLevelGroupUnit('level1', effSelector, unit)) }
    = yes;
unit_online_LP(unit)${ sum(effSelector, effLevelGroupUnit('level1', 'directOnLP', unit)) }
    = yes;
unit_online_MIP(unit) = unit_online(unit) - unit_online_LP(unit);

// Units with flows/fuels
unit_flow(unit)${ sum(flow, flowUnit(flow, unit)) }
    = yes;
unit_fuel(unit)${ sum(fuel, uFuel(unit, 'main', fuel)) }
    = yes;

// Units with special startup properties
// All units can cold start (default start category)
// NOTE! Juha needs to check why not all units can cold start
unitStarttype(unit, starttype('cold'))${ p_unit(unit, 'startCostCold')
                                         or p_unit(unit, 'startFuelConsCold')
                                         or p_unit(unit, 'rampSpeedToMinLoad')
                                       }
    = yes;
// Units with parameters regarding hot/warm starts
unitStarttype(unit, starttypeConstrained)${ p_unit(unit, 'startWarmAfterXhours')
                                            or p_unit(unit, 'startCostHot')
                                            or p_unit(unit, 'startFuelConsHot')
                                            or p_unit(unit, 'startCostWarm')
                                            or p_unit(unit, 'startFuelConsWarm')
                                            or p_unit(unit, 'startColdAfterXhours')
                                            }
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
gn(grid, node)${    sum(unit, gnu(grid, node, unit)
                    or gn_state(grid, node))
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

// Nodes with reserve requirements
restypeDirectionNode(restypeDirection(restype, up_down), node)${    p_nReserves(node, restype, up_down)
                                                                    or p_nReserves(node, restype, 'use_time_series')
                                                                    }
    = yes;

// Assume values for critical reserve related parameters, if not provided by input data
// Reserve contribution "reliability" assumed to be perfect if not provided in data
p_nuReserves(nu(node, unit), restype, 'reserveContribution')${  not p_nuReserves(node, unit, restype, 'reserveContribution')
                                                                and sum(up_down, nuRescapable(restype, up_down, node, unit))
                                                                }
    = 1;

* =============================================================================
* --- Data Integrity Checks ---------------------------------------------------
* =============================================================================

* Check the integrity of node connection related data
Option clear = count;
loop(gn2n(grid, node, node_),
    count = count + 1; // Count the gn2n indeces to make finding the errors easier.
    // Check if the bidirectional transfer parameter exists for this link.
    if(p_gnn(grid, node, node_, 'transferCapBidirectional'),
        // Check for conflicting bidirectional transfer capacities.
        if(p_gnn(grid, node, node_, 'transferCapBidirectional') <> p_gnn(grid, node_, node, 'transferCapBidirectional'),
            put log '!!! Error occurred on gn2n link #' count;
            abort "Conflicting 'transferCapBidirectional' parameters!"
        );
        // Check for conflicting one-directional and bidirectional transfer capacities.
        if(p_gnn(grid, node, node_, 'transferCapBidirectional') < p_gnn(grid, node, node_, 'transferCap') OR (p_gnn(grid, node, node_, 'transferCapBidirectional') < p_gnn(grid, node_, node, 'transferCap')),
            put log '!!! Error occurred on gn2n link #' count;
            abort "Parameter 'transferCapBidirectional' must be greater than or equal to defined one-directional transfer capacities!"
        );
    );
);

* Check the integrity of efficiency approximation related data
Option clear = tmp; // Log the unit index for finding the error easier.
loop( unit,
    tmp = ord(unit); // Increase the unit counter
    // Check that 'op' is defined correctly
    Option clear = count; // Initialize the previous op to zero
    loop( op,
        abort${p_unit(unit, op) + 1${not p_unit(unit, op)} < count} "param_unit 'op's must be defined as zero or positive and increasing!", tmp, count;
        count = p_unit(unit, op);
    );
    // Check that efficiency approximations have sufficient data
    loop( effLevelGroupUnit(effLevel, effSelector, unit),
        loop( op__${p_unit(unit, op__) = smax(op, p_unit(unit, op))}, // Loop over the 'op's to find the last defined data point.
            // Lambda  - Has been commented out, since it is ok to improve the efficiency curve by using extra lambda points.
            //loop( lambda${sameas(lambda, effSelector)}, // Loop over the lambdas to find the 'magnitude' of the approximation
                //display count_lambda, count_lambda2, unit.tl;
            //    if(ord(lambda) > ord(op__), put log '!!! Error occurred on unit ' unit.tl:25 ' with effLevel ' effLevel.tl:10 ' with effSelector ' lambda.tl:8); // Display unit that causes error
            //    abort${ord(lambda) > ord(op__)} "Order of the lambda approximation cannot exceed the number of efficiency data points!"
            // );
            // DirectOn
            loop( op_${p_unit(unit, op_) = smin(op${p_unit(unit, op)}, p_unit(unit, op))}, // Loop over the 'op's to find the first nonzero 'op' data point.
                if(effDirectOn(effSelector) AND ord(op__) = ord(op_) AND not p_unit(unit, 'section') AND not p_unit(unit, 'opFirstCross'),
                    put log '!!! Error occurred on unit #' tmp; // Display unit that causes error, NEEDS WORK
                    abort "directOn requires two efficiency data points with nonzero 'op' or 'section' or 'opFirstCross'!";
                );
            );
        );
    );
);

