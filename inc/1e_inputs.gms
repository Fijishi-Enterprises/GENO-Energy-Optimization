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

* Load updates made for BackBone
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
$loaddc p_unit
$loaddc ts_unit
$loaddc p_nReserves
$loaddc p_nuReserves
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
$loaddc p_gnugnu
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

* Copy fuel time series data for all nodes
ts_fuelPriceChangenode(fuel, node, t) = ts_fuelPriceChange(fuel, t);

* Define unit aggregation sets
unit_aggregate(unit)$sum(unit_, unitUnit_aggregate(unit, unit_)) = yes; // Set of aggregate units
unit_noAggregate(unit)$(unit(unit) - unit_aggregate(unit) - sum(unit_, unitUnit_aggregate(unit_, unit))) = yes; // Set of units that are not aggregated into any aggregate, or are not aggregates themselves

* Process data for unit aggregations
p_gnu(grid, node, unit_aggregate(unit), 'maxGen') = sum(unit_$unitUnit_aggregate(unit, unit_), p_gnu(grid, node, unit_, 'maxGen')); // Aggregate maxGen as the sum of aggregated maxGen
p_gnu(grid, node, unit_aggregate(unit), 'maxCons') = sum(unit_$unitUnit_aggregate(unit, unit_), p_gnu(grid, node, unit_, 'maxCons')); // Aggregate maxCons as the sum of aggregated maxCons

* Generate unit related sets based on input data
gnu(grid, node, unit)$(p_gnu(grid, node, unit, 'maxGen') or p_gnu(grid, node, unit, 'maxCons')) = yes;
gnu_output(grid, node, unit)$p_gnu(grid, node, unit, 'maxGen') = yes;
gnu_input(grid, node, unit)$p_gnu(grid, node, unit, 'maxCons') = yes;
gnu(grid, node, unit)$(p_gnu(grid, node, unit, 'maxGenCap') or p_gnu(grid, node, unit, 'maxConsCap')) = yes;
gnu_output(grid, node, unit)$p_gnu(grid, node, unit, 'maxGenCap') = yes;
gnu_output(grid, node, unit)$p_gnu(grid, node, unit, 'maxConsCap') = yes;
gn2gnu(grid_, node_input, grid, node, unit)$(gnu_input(grid_, node_input, unit) and gnu_output(grid, node, unit)) = yes;
nu(node, unit)$sum(grid, gnu(grid, node, unit)) = yes;
nuRescapable(restype, up_down, node, unit)$p_nuReserves(node, unit, restype, up_down) = yes;
unit_minload(unit)$[p_unit(unit, 'op00') > 0 and p_unit(unit, 'op00') < 1] = yes;   // If the first point is between 0 and 1, then the unit has a min load limit
unit_flow(unit)$sum(flow, flowUnit(flow, unit)) = yes;
unit_fuel(unit)$sum[ (fuel, node)$sum(t, ts_fuelPriceChangenode(fuel, node, t)), uFuel(unit, 'main', fuel) ] = yes;
unit_elec(unit)$sum(gnu(grid, node, unit), p_gnu('elec', node, unit, 'maxGen')) = yes;
unit_elec(unit)$sum(gnu(grid, node, unit), p_gnu('elec', node, unit, 'maxCons')) = yes;
unit_elec(unit)$sum(gnu(grid, node, unit), p_gnu('elec', node, unit, 'maxGenCap')) = yes;
unit_elec(unit)$sum(gnu(grid, node, unit), p_gnu('elec', node, unit, 'maxConsCap')) = yes;

* Assume values for critical unit related parameters, if not provided by input data
p_unit(unit, 'eff00')$(not p_unit(unit, 'eff00')) = 1; // If the unit does not have efficiency set, it is 1
p_unit(unit, 'unitCount')$(not p_unit(unit, 'unitCount')) = 1;  // In case number of units has not been defined it is 1.
p_unit(unit, 'outputCapacityTotal')$(not p_unit(unit, 'outputCapacityTotal')) = sum(gnu_output(grid, node, unit), p_gnu(grid, node, unit, 'maxGen'));  // By default add outputs in order to get the total capacity of the unit

* Generate node related sets based on input data // NOTE! These will need to change if p_gnn is required to work with only one row per link.
gn2n(grid, from_node, to_node)${p_gnn(grid, from_node, to_node, 'transferCap') OR p_gnn(grid, from_node, to_node, 'transferLoss')} = yes;
gn2n(grid, from_node, to_node)${p_gnn(grid, from_node, to_node, 'transferCapBidirectional') OR p_gnn(grid, to_node, from_node, 'transferCapBidirectional')} = yes;
gn2n(grid, from_node, to_node)$p_gnn(grid, from_node, to_node, 'transferCapInvLimit') = yes;
gnn_boundState(grid, node, node_)$(p_gnn(grid, node, node_, 'boundStateOffset')) = yes;
gnn_state(grid, node, node_)$(p_gnn(grid, node, node_, 'diffCoeff') or gnn_boundState(grid, node, node_)) = yes;
gn_stateSlack(grid, node)$(sum((upwardSlack,   useConstantOrTimeSeries), p_gnBoundaryPropertiesForStates(grid, node,   upwardSlack, useConstantOrTimeSeries))) = yes;
gn_stateSlack(grid, node)$(sum((downwardSlack, useConstantOrTimeSeries), p_gnBoundaryPropertiesForStates(grid, node, downwardSlack, useConstantOrTimeSeries))) = yes;
gn_state(grid, node)$gn_stateSlack(grid, node) = yes;
gn_state(grid, node)$p_gn(grid, node, 'energyStoredPerUnitOfState') = yes;
gn_state(grid, node)$(sum((stateLimits, useConstantOrTimeSeries), p_gnBoundaryPropertiesForStates(grid, node, stateLimits, useConstantOrTimeSeries))) = yes;
gn_state(grid, node)$(sum(useConstantOrTimeSeries, p_gnBoundaryPropertiesForStates(grid, node, 'reference', useConstantOrTimeSeries))) = yes;
gn(grid, node)$(sum(unit, gnu(grid, node, unit) or gn_state(grid, node))) = yes;
node_spill(node)$(sum((grid, spillLimits, useConstantOrTimeSeries)$gn(grid, node), p_gnBoundaryPropertiesForStates(grid, node, spillLimits, useConstantOrTimeSeries))) = yes;

* Generate the set of unique, symmetric transfer links
gn2n_bidirectional(grid, node, node_) = no;
gn2n_bidirectional(grid, node, node_)${p_gnn(grid, node, node_, 'transferCapBidirectional')} = yes;
loop(gn(grid, node),
    loop(gn2n(grid, node, node_)${gn2n(grid, node_,node)},
        gn2n_bidirectional(grid, node, node_)${not gn2n_bidirectional(grid, node_, node)} = yes;
    );
);
* Assume lacking parameters for bidirectional links, if input data found lacking.
loop(gn2n_bidirectional(grid, node, node_)${p_gnn(grid, node, node_, 'transferCapBidirectional')},
    // Replicate the bidirectional transfer capacity for the other direction as well for clarity, in case it's undefined. This affects the related data integrity check later.
    p_gnn(grid, node_, node, 'transferCapBidirectional')${not p_gnn(grid, node_, node, 'transferCapBidirectional')} = p_gnn(grid, node, node_, 'transferCapBidirectional');
    // Limit individual directional transfer capacities to the bidirectional capacity if not defined otherwise.
    p_gnn(grid, node, node_, 'transferCap')${not p_gnn(grid, node, node_, 'transferCap')} = p_gnn(grid, node, node_, 'transferCapBidirectional');
    p_gnn(grid, node_, node, 'transferCap')${not p_gnn(grid, node_, node, 'transferCap')} = p_gnn(grid, node, node_, 'transferCapBidirectional');
    // Fill in missing transfer losses
    // NOTE! One has to define 'transferCapBidirectional' for the direction with zero 'transferLoss', if asymmetric losses are desired.
    p_gnn(grid, node_, node, 'transferLoss')${not p_gnn(grid, node_, node, 'transferLoss')} = p_gnn(grid, node, node_, 'transferLoss');
);

* Assume values for critical node related parameters, if not provided by input data
p_gnBoundaryPropertiesForStates(gn(grid, node), param_gnBoundaryTypes, 'multiplier')$(not p_gnBoundaryPropertiesForStates(grid, node, param_gnBoundaryTypes, 'multiplier')) = 1; // If multiplier has not been set, set it to 1 by default
*p_gn(gn(grid, node), 'energyStoredPerUnitOfState')$(not p_gn(grid, node, 'energyStoredPerUnitOfState') and not p_gn(grid, node, 'boundAll')) = 1; // If unitConversion has not been set, default to 1; If the state is bound, there is no need for the term

* --- Perform various data checks, and abort if errors are detected -----------
* Check the integrity of node connection related data
count = 0;
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
tmp = 0; // Log the unit index for finding the error easier.
loop( unit,
    tmp = tmp + 1; // Increase the unit counter
    // Check that 'op' is defined correctly
    count = 0; // Initialize the previous op to zero
    loop( op,
        abort${p_unit(unit, op) + 1${not p_unit(unit, op)} < count} "param_unit 'op's must be defined as zero or positive and increasing!";
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

