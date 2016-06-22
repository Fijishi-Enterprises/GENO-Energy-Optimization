* Load updates made for BackBone
$gdxin  'input/inputData.gdx'
$loaddc node
$loaddc flow
$loaddc unit
$loaddc fuel
$loaddc storage
$loaddc gnnStateLimit
$loaddc gnData
$loaddc gnuData
$loaddc nuData
$loaddc nuDataReserves
$loaddc gnsData
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
$loaddc p_transferCap
$loaddc p_transferLoss
$loaddc p_nnCoEff
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
gnState(grid, node)$(gnData(grid, node, 'maxState') or gnData(grid, node, 'minState') or gnData(grid, node, 'energyCapacity')) = yes;
gnu(grid, node, unit)$gnuData(grid, node, unit, 'maxCap') = yes;
gn(grid, node)$sum(unit, gnu(grid, node, unit)) = yes;
nu(node, unit)$sum(grid, gnu(grid, node, unit)) = yes;
nu(node, unit)$sum((grid, grid_), ggnuConstrainedOutputRatio(grid, grid_, node, unit)) = no;
nu(node, unit)$sum((grid, grid_), ggnuFixedOutputRatio(grid, grid_, node, unit)) = no;
gns(grid, node, storage)$gnsData(grid, node, storage, 'maxContent') = yes;
nnu(node, node_, unit)$(nu(node, unit) and ord(node) = ord(node_)) = yes;
gn2n(grid, from_node, to_node)$p_transferCap(grid, from_node, to_node) = yes;
node_to_node(from_node, to_node)$p_transferCap('elec', from_node, to_node) = yes;
gnnState(grid, node, node_)$(p_nnCoEff(grid, node, node_) and gnState(grid, node) and gnState(grid, node_)) = yes;

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
