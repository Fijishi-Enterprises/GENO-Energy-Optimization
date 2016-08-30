* Load updates made for BackBone
$gdxin  'input/inputData.gdx'
$loaddc node
$loaddc flow
$loaddc unit
$loaddc fuel
$loaddc storage
$loaddc gnData
$loaddc gnnData
$loaddc gnuData
$loaddc nuData
$loaddc nuDataReserves
$loaddc gnsData
$loaddc pgnData
$loaddc gnu_input
$loaddc nnu
$loaddc unit_fuel
$loaddc flow_unit
$loaddc unit_storage
$loaddc ggnuFixedOutputRatio
$loaddc ggnuConstrainedOutputRatio
$loaddc emission
$loaddc ts_energyDemand
$loaddc ts_import
$loaddc ts_cf
$loaddc ts_stoContent
$loaddc ts_fuelPriceChange
$loaddc ts_inflow
$loaddc ts_nodeState
$loaddc p_data2d
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

* Generate sets based on parameter data
gnu(grid, node, unit)$gnuData(grid, node, unit, 'maxCap') = yes;
nu(node, unit)$sum(grid, gnu(grid, node, unit)) = yes;
nu(node, unit)$sum((grid, grid_), ggnuConstrainedOutputRatio(grid, grid_, node, unit)) = no;
nu(node, unit)$sum((grid, grid_), ggnuFixedOutputRatio(grid, grid_, node, unit)) = no;
gns(grid, node, storage)$gnsData(grid, node, storage, 'maxContent') = yes;
nnu(node, node_, unit)$(nu(node, unit) and ord(node) = ord(node_)) = yes;
gn2n(grid, from_node, to_node)$gnnData(grid, from_node, to_node, 'transferCap') = yes;
node_to_node(from_node, to_node)$gnnData('elec', from_node, to_node, 'transferCap') = yes;
gnnBoundState(grid, node, node_)$(gnnData(grid, node, node_, 'BoundStateOffset')) = yes;
gnnState(grid, node, node_)$(gnnData(grid, node, node_, 'DiffCoeff') or gnnBoundState(grid, node, node_)) = yes;
gnState(grid, node)$(sum(param_gn, gnData(grid, node, param_gn)) or sum(node_, gnnState(grid, node, node_)) or sum(node_, gnnState(grid, node_, node))) = yes;
gnStateSlack(grid, node)$((gnData(grid, node, 'maxStateSlack') or gnData(grid, node, 'minStateSlack') or sum(f, sum(t, ts_nodeState(grid, node, 'maxStateSlack', f, t) + ts_nodeState(grid, node, 'minStateSlack', f, t)))) and not gnData(grid, node, 'fixState')) = yes;
gn(grid, node)$(sum(unit, gnu(grid, node, unit)) or gnState(grid, node)) = yes;
pgn(slack, inc_dec, grid, node)$(sum(param_pgn, pgnData(slack, inc_dec, grid, node, param_pgn))) = yes;

ts_fuelPriceChangenode(fuel, node, t) = ts_fuelPriceChange(fuel, t);

unitOnline(unit)$[ sum(gnu(grid, node, unit), nuData(node, unit, 'startupCost') or nuData(node, unit, 'startupFuelCons') or nuData(node, unit, 'coldStart') ) ] = yes;
unitVG(unit)$sum(flow, flow_unit(flow, unit)) = yes;
*unitConversion(unit)$sum(gn(grid, node), gnu_input(grid, node, unit)) = yes;
unitElec(unit)$sum(gnu(grid, node, unit), gnuData('elec', node, unit, 'maxCap')) = yes;
unitHeat(unit)$sum(gnu(grid, node, unit), gnuData('heat', node, unit, 'maxCap')) = yes;
unitFuel(unit)$sum[ (fuel, node)$sum(t, ts_fuelPriceChangenode(fuel, node, t)), unit_fuel(unit, fuel, 'main') ] = yes;
unitVG(unit)$sum(flow, flow_unit(flow, unit)) = yes;
unitWithCV(unit)$(sum(gnu(grid, node, unit), 1) > 1) = yes;
unitMinload(unit)$sum(gnu(grid, node, unit), nuData(node, unit, 'minLoad')) = yes;
unitHydro(unit)$sum(unit_fuel(unit,'WATER','main'), 1) = yes;
unitHydro(unit)$sum(unit_fuel(unit,'WATER_RES','main'), 1) = yes;
storageHydro(storage)$sum(unitHydro, unit_storage(unitHydro, storage)) = yes;
storageCharging(storage)$(sum(gnu(grid, node, unit)$unit_storage(unit, storage), gnuData(grid, node, unit, 'maxCharging'))) = yes;
storageSpill(storage)$(sum(gns(grid, node, storage), gnsData(grid, node, storage, 'maxSpill'))) = yes;
resCapable(resType, resDirection, node, unit)$nuDataReserves(node, unit, resType, resDirection) = yes;

* Link units to genTypes
$iftheni '%genTypes%' == 'yes'
loop(nu_fuel(node, unit, fuel, 'main'),
    genType_g('pumped storage', unit) = yes$(sameas(fuel, 'water')
                                          and nuData(node, unit, 'maxCharging') > 0);
    genType_g('hydropower', unit) = yes$(sameas(fuel, 'water')
                                      and not genType_g('pumped storage', unit));
    genType_g('nuclear', unit) = yes$sameas(fuel, 'nuclear');
    genType_g('coal', unit) = yes$sameas(fuel, 'coal');
    genType_g('OCGT', unit) = yes$(sameas(g, 'OCGT') or sameas(unit, 'DoE_Peaker'));
    genType_g('CCGT', unit) = yes$(sameas(fuel, 'nat_gas')
                                and not genType_g('OCGT', unit));
    genType_g('solar', unit) = yes$sameas(fuel, 'solar');
    genType_g('wind', unit) = yes$sameas(fuel, 'wind');
    genType_g('dummy', unit) = yes$sameas(unit, 'dummy');
);
$endif
