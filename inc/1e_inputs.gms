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
$loaddc p_nuReserves
$loaddc p_gnBoundaryPropertiesForStates
$loaddc p_gnPolicy
$loaddc p_uFuel
$loaddc flowUnit
$loaddc gngnu_fixedOutputRatio
$loaddc gngnu_constrainedOutputRatio
$loaddc emission
$loaddc p_fuelEmission
$loaddc ts_energyDemand
$loaddc ts_cf
$loaddc ts_fuelPriceChange
$loaddc ts_absolute
$loaddc ts_nodeState
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
gn2gnu(grid_, node_input, grid, node, unit)$(gnu_input(grid_, node_input, unit) and gnu_output(grid, node, unit)) = yes;
nu(node, unit)$sum(grid, gnu(grid, node, unit)) = yes;
nuRescapable(restype, resdirection, node, unit)$p_nuReserves(node, unit, restype, resdirection) = yes;
unit_minload(unit)$[p_unit(unit, 'rb00') > 0 and p_unit(unit, 'rb00') < 1] = yes;   // If the first point is between 0 and 1, then the unit has a min load limit
unit_online(unit)$[p_unit(unit, 'rb00') > 0 or p_unit(unit, 'startupCost') or p_unit(unit, 'startupFuelCons') or p_unit(unit, 'coldStart') ] = yes; // How does this differ from unit_minLoad, exactly?
unit_flow(unit)$sum(flow, flowUnit(flow, unit)) = yes;
unit_fuel(unit)$sum[ (fuel, node)$sum(t, ts_fuelPriceChangenode(fuel, node, t)), uFuel(unit, 'main', fuel) ] = yes;
unit_elec(unit)$sum(gnu(grid, node, unit), p_gnu('elec', node, unit, 'maxGen')) = yes;

* Assume values for critical unit related parameters, if not provided by input data
p_unit(unit, 'eff00')$(not p_unit(unit, 'eff00')) = 1; // If the unit does not have efficiency set, it is 1
p_unit(unit, 'unitCount')$(not p_unit(unit, 'unitCount')) = 1;  // In case number of units has not been defined it is 1.
p_unit(unit, 'unitCapacity')$(not p_unit(unit, 'unitCapacity')) = sum(gnu_output(grid, node, unit), p_gnu(grid, node, unit, 'maxGen'));  // By default add outputs in order to get the total capacity of the unit

* Generate node related sets based on input data
gn2n(grid, from_node, to_node)$p_gnn(grid, from_node, to_node, 'transferCap') = yes;
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

* Assume values for critical node related parameters, if not provided by input data
p_gnBoundaryPropertiesForStates(gn(grid, node), param_gnBoundaryTypes, 'multiplier')$(not p_gnBoundaryPropertiesForStates(grid, node, param_gnBoundaryTypes, 'multiplier')) = 1; // If multiplier has not been set, set it to 1 by default
p_gn(gn(grid, node), 'energyStoredPerUnitOfState')$(not p_gn(grid, node, 'energyStoredPerUnitOfState') and not p_gn(grid, node, 'boundAll')) = 1; // If unitConversion has not been set, default to 1; If the state is bound, there is no need for the term

* --- Perform various data checks, and abort if errors are detected -----------
* Check the integrity of efficiency approximation related data
loop( unit,
    count = 0; // Initialize the previous rb to zero
    loop( rb,
        abort${p_unit(unit, rb) + 1${not p_unit(unit, rb)} < count} "param_unit 'rb's must be defined as zero or positive and increasing!";
        count = p_unit(unit, rb);
    );
);

