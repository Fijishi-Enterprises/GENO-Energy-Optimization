* Load updates made for BackBone
$gdxin  'input/inputData.gdx'
$loaddc node
$loaddc flow
$loaddc unit
$loaddc fuel
$loaddc storage
$loaddc unitUnit_aggregate
$loaddc p_gn
$loaddc p_gnn
$loaddc p_gnu
$loaddc p_nu
$loaddc p_nuReserves
$loaddc p_gnStorage
$loaddc p_gnSlack
$loaddc p_gnPolicy
$loaddc gnu_input
$loaddc nnu
$loaddc unitFuelParam
$loaddc flowUnit
$loaddc unitStorage
$loaddc ggnu_fixedOutputRatio
$loaddc ggnu_constrainedOutputRatio
$loaddc emission
$loaddc p_fuelEmission
$loaddc ts_energyDemand
$loaddc ts_import
$loaddc ts_cf
$loaddc ts_stoContent
$loaddc ts_fuelPriceChange
$loaddc ts_inflow
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
unitStorage(unit, storage)$sum(unit_$(unitUnit_aggregate(unit, unit_) and unitStorage(unit_, storage)), 1) = yes;

p_gnu(grid, node, unit_aggregate(unit), 'maxCap') = sum(unit_$unitUnit_aggregate(unit, unit_), p_gnu(grid, node, unit_, 'maxCap'));
p_gnu(grid, node, unit_aggregate(unit), 'maxCharging') = sum(unit_$unitUnit_aggregate(unit, unit_), p_gnu(grid, node, unit_, 'maxCharging'));

* Generate sets based on parameter data
gnu(grid, node, unit)$p_gnu(grid, node, unit, 'maxCap') = yes;
nu(node, unit)$sum(grid, gnu(grid, node, unit)) = yes;
nu(node, unit)$sum((grid, grid_), ggnu_constrainedOutputRatio(grid, grid_, node, unit)) = no;
nu(node, unit)$sum((grid, grid_), ggnu_fixedOutputRatio(grid, grid_, node, unit)) = no;
gnStorage(grid, node, storage)$p_gnStorage(grid, node, storage, 'maxContent') = yes;
nnu(node, node_, unit)$(nu(node, unit) and ord(node) = ord(node_)) = yes;
gn2n(grid, from_node, to_node)$p_gnn(grid, from_node, to_node, 'transferCap') = yes;
node_to_node(from_node, to_node)$p_gnn('elec', from_node, to_node, 'transferCap') = yes;
gnn_boundState(grid, node, node_)$(p_gnn(grid, node, node_, 'boundStateOffset')) = yes;
gnn_state(grid, node, node_)$(p_gnn(grid, node, node_, 'diffCoeff') or gnn_boundState(grid, node, node_)) = yes;
gn_state(grid, node)$(sum(param_gn, p_gn(grid, node, param_gn)) or sum(node_, gnn_state(grid, node, node_)) or sum(node_, gnn_state(grid, node_, node))) = yes;
gn_stateSlack(grid, node)$((p_gn(grid, node, 'maxStateSlack') or p_gn(grid, node, 'minStateSlack') or sum(f, sum(t, ts_nodeState(grid, node, 'maxStateSlack', f, t) + ts_nodeState(grid, node, 'minStateSlack', f, t)))) and not p_gn(grid, node, 'fixState')) = yes;
gn(grid, node)$(sum(unit, gnu(grid, node, unit)) or gn_state(grid, node)) = yes;
gnSlack(inc_dec, slack, grid, node)$(sum(param_slack, p_gnSlack(inc_dec, slack, grid, node, param_slack))) = yes;

ts_fuelPriceChangenode(fuel, node, t) = ts_fuelPriceChange(fuel, t);

unit_online(unit)$[ sum(gnu(grid, node, unit), p_nu(node, unit, 'startupCost') or p_nu(node, unit, 'startupFuelCons') or p_nu(node, unit, 'coldStart') ) ] = yes;
unit_VG(unit)$sum(flow, flowUnit(flow, unit)) = yes;
*unitConversion(unit)$sum(gn(grid, node), gnu_input(grid, node, unit)) = yes;
unit_elec(unit)$sum(gnu(grid, node, unit), p_gnu('elec', node, unit, 'maxCap')) = yes;
unit_heat(unit)$sum(gnu(grid, node, unit), p_gnu('heat', node, unit, 'maxCap')) = yes;
unit_fuel(unit)$sum[ (fuel, node)$sum(t, ts_fuelPriceChangenode(fuel, node, t)), unitFuelParam(unit, fuel, 'main') ] = yes;
unit_VG(unit)$sum(flow, flowUnit(flow, unit)) = yes;
unit_withConstrainedOutputRatio(unit)$(sum(gnu(grid, node, unit), 1) > 1) = yes;
unit_minload(unit)$sum(gnu(grid, node, unit), p_nu(node, unit, 'minLoad')) = yes;
unit_hydro(unit)$sum(unitFuelParam(unit,'WATER','main'), 1) = yes;
storage_hydro(storage)$sum(unit_hydro, unitStorage(unit_hydro, storage)) = yes;
storage_charging(storage)$(sum(gnu(grid, node, unit)$unitStorage(unit, storage), p_gnu(grid, node, unit, 'maxCharging'))) = yes;
storage_spill(storage)$(sum(gnStorage(grid, node, storage), p_gnStorage(grid, node, storage, 'maxSpill'))) = yes;
nuRescapable(restype, resdirection, node, unit)$p_nuReserves(node, unit, restype, resdirection) = yes;

* Link units to unittypes
$iftheni '%unittypes%' == 'yes'
loop(nu_fuel(node, unit, fuel, 'main'),
    unittypeUnit('pumped storage', unit) = yes$(sameas(fuel, 'water')
                                          and p_nu(node, unit, 'maxCharging') > 0);
    unittypeUnit('hydropower', unit) = yes$(sameas(fuel, 'water')
                                      and not unittypeUnit('pumped storage', unit));
    unittypeUnit('nuclear', unit) = yes$sameas(fuel, 'nuclear');
    unittypeUnit('coal', unit) = yes$sameas(fuel, 'coal');
    unittypeUnit('OCGT', unit) = yes$(sameas(g, 'OCGT') or sameas(unit, 'DoE_Peaker'));
    unittypeUnit('CCGT', unit) = yes$(sameas(fuel, 'nat_gas')
                                and not unittypeUnit('OCGT', unit));
    unittypeUnit('solar', unit) = yes$sameas(fuel, 'solar');
    unittypeUnit('wind', unit) = yes$sameas(fuel, 'wind');
    unittypeUnit('dummy', unit) = yes$sameas(unit, 'dummy');
);
$endif

