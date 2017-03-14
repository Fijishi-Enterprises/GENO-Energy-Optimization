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
*$loaddc gnuUnion
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

unit_aggregate(unit)$sum(unit_, unitUnit_aggregate(unit, unit_)) = yes;
unit_noAggregate(unit)$(unit(unit) - unit_aggregate(unit) - sum(unit_, unitUnit_aggregate(unit_, unit))) = yes;
*unitStorage(unit, storage)$sum(unit_$(unitUnit_aggregate(unit, unit_) and unitStorage(unit_, storage)), 1) = yes;

* Process data for unit aggregations
p_gnu(grid, node, unit_aggregate(unit), 'maxGen') = sum(unit_$unitUnit_aggregate(unit, unit_), p_gnu(grid, node, unit_, 'maxGen'));
p_gnu(grid, node, unit_aggregate(unit), 'maxCons') = sum(unit_$unitUnit_aggregate(unit, unit_), p_gnu(grid, node, unit_, 'maxCons'));

* Generate sets based on parameter data
gnu(grid, node, unit)$(p_gnu(grid, node, unit, 'maxGen') or p_gnu(grid, node, unit, 'maxCons')) = yes;
gnu_output(grid, node, unit)$p_gnu(grid, node, unit, 'maxGen') = yes;
gnu_input(grid, node, unit)$p_gnu(grid, node, unit, 'maxCons') = yes;
gn2gnu(grid_, node_input, grid, node, unit)$(gnu_input(grid_, node_input, unit) and gnu_output(grid, node, unit)) = yes;
nu(node, unit)$sum(grid, gnu(grid, node, unit)) = yes;
*nu(node, unit)$sum((grid, grid_, node_), gngnu_constrainedOutputRatio(grid, node, grid_, node_, unit)) = no;
*nu(node, unit)$sum((grid, grid_, node_), gngnu_fixedOutputRatio(grid, node, grid_, node_, unit)) = no;
nnu(node, node_, unit)$(nu(node, unit) and ord(node) = ord(node_)) = yes;
gn2n(grid, from_node, to_node)$p_gnn(grid, from_node, to_node, 'transferCap') = yes;
node_to_node(from_node, to_node)$p_gnn('elec', from_node, to_node, 'transferCap') = yes;
gnn_boundState(grid, node, node_)$(p_gnn(grid, node, node_, 'boundStateOffset')) = yes;
gnn_state(grid, node, node_)$(p_gnn(grid, node, node_, 'diffCoeff') or gnn_boundState(grid, node, node_)) = yes;
gn_stateSlack(grid, node)$(sum((upwardSlack,   useConstantOrTimeSeries), p_gnBoundaryPropertiesForStates(grid, node,   upwardSlack, useConstantOrTimeSeries))) = yes;
gn_stateSlack(grid, node)$(sum((downwardSlack, useConstantOrTimeSeries), p_gnBoundaryPropertiesForStates(grid, node, downwardSlack, useConstantOrTimeSeries))) = yes;
gn_state(grid, node)$gn_stateSlack(grid, node) = yes;
gn_state(grid, node)$p_gn(grid, node, 'energyStoredPerUnitOfState') = yes;
gn_state(grid, node)$(sum((stateLimits, useConstantOrTimeSeries), p_gnBoundaryPropertiesForStates(grid, node, stateLimits, useConstantOrTimeSeries))) = yes;
gn_state(grid, node)$(sum(useConstantOrTimeSeries, p_gnBoundaryPropertiesForStates(grid, node, 'reference', useConstantOrTimeSeries))) = yes;
gn(grid, node)$(sum(unit, gnu(grid, node, unit) or gn_state(grid, node))) = yes;
p_gnBoundaryPropertiesForStates(gn(grid, node), param_gnBoundaryTypes, 'multiplier')$(not p_gnBoundaryPropertiesForStates(grid, node, param_gnBoundaryTypes, 'multiplier')) = 1; // If multiplier has not been set, set it to 1 by default
p_gn(gn(grid, node), 'energyStoredPerUnitOfState')$(not p_gn(grid, node, 'energyStoredPerUnitOfState') and not p_gn(grid, node, 'boundAll')) = 1; // If unitConversion has not been set, default to 1; If the state is bound, there is no need for the term

ts_fuelPriceChangenode(fuel, node, t) = ts_fuelPriceChange(fuel, t);

unit_online(unit)$[ p_unit(unit, 'startupCost') or p_unit(unit, 'startupFuelCons') or p_unit(unit, 'coldStart') ] = yes;
unit_flow(unit)$sum(flow, flowUnit(flow, unit)) = yes;
*unitConversion(unit)$sum(gn(grid, node), gnu_input(grid, node, unit)) = yes;
unit_elec(unit)$sum(gnu(grid, node, unit), p_gnu('elec', node, unit, 'maxGen')) = yes;
unit_heat(unit)$sum(gnu(grid, node, unit), p_gnu('heat', node, unit, 'maxGen')) = yes;
unit_fuel(unit)$sum[ (fuel, node)$sum(t, ts_fuelPriceChangenode(fuel, node, t)), uFuel(unit, 'main', fuel) ] = yes;
unit_flow(unit)$sum(flow, flowUnit(flow, unit)) = yes;
unit_withConstrainedOutputRatio(unit)$(sum(gngnu_constrainedOutputRatio(grid, node, grid_, node_, unit), 1)) = yes;
p_unit(unit, 'eff00')$(not p_unit(unit, 'eff00')) = 1; // If the unit does not have efficiency set, it is 1
p_unit(unit, 'rb00')$(not p_unit(unit, 'rb00')) = 0;   // If there is no right border for the first efficiency point, there will be no section
unit_minload(unit)$[p_unit(unit, 'rb00') > 0 and p_unit(unit, 'rb00') < 1] = yes;   // If the first point is between 0 and 1, then the unit has a min load limit
*unit_hydro(unit)$sum(unitFuelParam(unit,'WATER','main'), 1) = yes;
*node_reservoir(node)$sum(unit_hydro, unitStorage(unit_hydro, storage)) = yes;
nuRescapable(restype, resdirection, node, unit)$p_nuReserves(node, unit, restype, resdirection) = yes;
node_spill(node)$(sum((grid, spillLimits, useConstantOrTimeSeries)$gn(grid, node), p_gnBoundaryPropertiesForStates(grid, node, spillLimits, useConstantOrTimeSeries))) = yes;
p_unit(unit, 'unitCount')$(not p_unit(unit, 'unitCount')) = 1;  // In case number of units has not been defined it is 1.
$ontext
p_unit(unit, 'section00') = p_unit(unit, 'rb00') / p_unit(unit, 'eff00'); // Section at min. load defined by rb00
p_unit(unit, 'slope00')$p_unit(unit, 'eff01')
                                           = [ + 1 / p_unit(unit, 'eff01')
                                               - 1 / p_unit(unit, 'eff00')
                                             ] /
                                             [ + p_unit(unit, 'rb01')
                                               - p_unit(unit, 'rb00')
                                             ];
p_unit(unit, 'slope00')$(not p_unit(unit, 'eff01'))   // In case there is single efficiency over the whole operating area
                                           = 1 / p_unit(unit, 'eff00');
p_unit(unit, 'slope01')$p_unit(unit, 'eff02')         // Calculate rest of the slope as additions over the first slope
                                           = [ + p_unit(unit, 'rb02') / p_unit(unit, 'eff02')
                                               - p_unit(unit, 'rb01') / p_unit(unit, 'eff01')
                                             ] /
                                             [ + p_unit(unit, 'rb02')
                                               - p_unit(unit, 'rb01')
                                             ]
                                             - p_unit(unit, 'slope00');
unit_slope(unit)$(sum(slope$p_unit(unit, slope), 1) > 1) = yes;
unit_noSlope(unit)$(sum(slope$p_unit(unit, slope), 1) <= 1 and not unit_flow(unit)) = yes;
slopeUnit(slope, unit)$(p_unit(unit, slope) and ord(slope)>1) = yes;
$offtext
p_unit(unit, 'unitCapacity')$p_unit(unit, 'unitCapacity') = sum(gnu_output(grid, node, unit), p_gnu(grid, node, unit, 'maxGen'));  // By default add outputs in order to get the total capacity of the unit

* Rest of the slope calculations missing... need to implement slope set or something similar.

