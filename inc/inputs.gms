* Load updates made for BackBone
$gdxin  'input/inputData.gdx'
$loadm  param
$loaddc geo
$loaddc flow
$loaddc bus
$loaddc unit
$loaddc fuel
$loaddc storage
*$loaddc eg
*$loaddc unitVG
$loaddc hydroBus
*$loaddc gu
*$loaddc egu
$loaddc eguData
$loaddc guData
$loaddc guDataReserves
$loaddc egsData
$loaddc egu_input
$loaddc ggu
*$loaddc egs
$loaddc flow_unit
$loaddc unit_fuel
$loaddc unit_storage
$loaddc eeguFixedOutputRatio
$loaddc eeguConstrainedOutputRatio
*$loaddc resCapable
$loaddc emission
$loaddc ts_energyDemand
$loaddc ts_import
*$load   ts_reserveDemand
$loaddc ts_cf
$loaddc ts_stoContent
$loaddc ts_fuelPriceChange
$loaddc ts_inflow
$loaddc p_transferCap
$loaddc p_transferLoss
$loaddc p_data2d
*$loaddc etype_storage
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
egu(etype, geo, unit)$eguData(etype, geo, unit, 'maxCap') = yes;
eg(etype, geo)$sum(unit, egu(etype, geo, unit)) = yes;
gu(geo, unit)$sum(etype, egu(etype, geo, unit)) = yes;
gu(geo, unit)$sum((etype, etype_), eeguConstrainedOutputRatio(etype, etype_, geo, unit)) = no;
gu(geo, unit)$sum((etype, etype_), eeguFixedOutputRatio(etype, etype_, geo, unit)) = no;
egs(etype, geo, storage)$egsData(etype, geo, storage, 'maxContent') = yes;
ggu(geo, geo_, unit)$(gu(geo, unit) and ord(geo) = ord(geo_)) = yes;
eg2g(etype, from_geo, to_geo)$p_transferCap(etype, from_geo, to_geo) = yes;
bus_to_bus(from_geo, to_geo)$p_transferCap('elec', from_geo, to_geo) = yes;

ts_fuelPriceChangeGeo(fuel, geo, t) = ts_fuelPriceChange(fuel, t);

unitOnline(unit)$[ sum(egu(etype, geo, unit), guData(geo, unit, 'startupCost') or guData(geo, unit, 'startupFuelCons') or guData(geo, unit, 'coldStart') ) ] = yes;
unitVG(unit)$sum(flow, flow_unit(flow, unit)) = yes;
*unitConversion(unit)$sum(eg(etype, geo), egu_input(etype, geo, unit)) = yes;
unitElec(unit)$sum(egu(etype, geo, unit), eguData('elec', geo, unit, 'maxCap')) = yes;
unitHeat(unit)$sum(egu(etype, geo, unit), eguData('heat', geo, unit, 'maxCap')) = yes;
unitFuel(unit)$sum[ (fuel, geo)$sum(t, ts_fuelPriceChangeGeo(fuel, geo, t)), unit_fuel(unit, fuel, 'main') ] = yes;
unitVG(unit)$sum(flow, flow_unit(flow, unit)) = yes;
unitWithCV(unit)$(sum(egu(etype, geo, unit), 1) > 1) = yes;
unitMinload(unit)$sum(egu(etype, geo, unit), guData(geo, unit, 'minLoad')) = yes;
unitHydro(unit)$sum(unit_fuel(unit,'WATER','main'), 1) = yes;
unitHydro(unit)$sum(unit_fuel(unit,'WATER_RES','main'), 1) = yes;
storageHydro(storage)$sum(unitHydro, unit_storage(unitHydro, storage)) = yes;
resCapable(resType, resDirection, geo, unit)$guDataReserves(geo, unit, resType, resDirection) = yes;

* Link units to genTypes
$iftheni '%genTypes%' == 'yes'
loop(gu_fuel(geo, unit, fuel, 'main'),
    genType_g('pumped storage', unit) = yes$(sameas(fuel, 'water')
                                          and guData(geo, unit, 'maxCharging') > 0);
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
