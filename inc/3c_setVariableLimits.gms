* --- Variable limits ---------------------------------------------------------
* Fix storage contents for the beginning
loop(ft_realized(f, tSolve),
$iftheni '%mode%' == 'findStorageStart'
        v_stoContent.lo(etype, geo, storage, f, tSolve)
           = egsData(etype, geo, storage, 'min_content') * egsData(etype, geo, storage, 'maxContent');
        v_stoContent.up(etype, geo, storage, f, tSolve) = egsData(etype, geo, storage, 'maxContent');
$else
        v_stoContent.fx(etype, geo, storage, f, tSolve)$(ord(tSolve) = mSettings('schedule', 't_start'))
            = ts_stoContent(storage, f, tSolve) * egsData(etype, geo, storage, 'maxContent');
        v_stoContent.fx(etype, geo, storage, f, tSolve)$(not ord(tSolve) = mSettings('schedule', 't_start'))
            = v_stoContent.l(etype, geo, storage, f, tSolve);
$endif
    // Free online capacity and state for the first loop
    if(tElapsed = 0 and not active('addOn'),
        v_online.up(gu(geo, unitOnline), f, tSolve) = 1;
        v_state.up(eg(etype, geo), f, tSolve) = egData(etype, geo, 'maxState');
    // Fix online capacity and state for later solutions
    else
        v_online.fx(gu(geo, unitOnline), f, tSolve) = v_online.l(geo, unitOnline, f, tSolve);
        v_state.fx(eg(etype, geo), f, tSolve) = v_state.l(etype, geo, f, tSolve);
    );

);

* Other time dependent parameters and variable limits
loop(ft(f, t),
    // Max. energy generation
    v_gen.up(egu(etype, geo, unit), f, t)$(not unitVG(unit)) = eguData(etype, geo, unit, 'maxCap') * sum(geo_, guData(geo_, unit, 'availability'));
    v_gen.up(egu(etype, geo, unitVG), f, t)$(not unitHydro(unitVG))      // Should only be about reservoir or RoR+reservoir hydro
        = sum(flow$(flow_unit(flow, unitVG) and gu(geo, unitVG)),
              ts_cf_(flow, geo, f, t) *
              eguData(etype, geo, unitVG, 'maxCap') *
              guData(geo, unitVG, 'availability')
          );
    // Min. generation to zero for units without consumption
    v_gen.lo(egu(etype, geo, unit), f, t)$(not eguData(etype, geo, unit, 'maxCharging')) = 0;
    // Max. consumption capacity for chargable storages
    v_gen.lo(egu_input(etype, geo, unit), f, t) = -eguData(etype, geo, unit, 'maxCharging');
    // Max. unitElec consumption of unitHeat pumps and such
    v_gen.lo(egu_input('elec', geo, unit), f, t)$sum(etype, egu('heat', geo, unit)) = -eguData('heat', geo, unit, 'maxCap') * guData(geo, unit, 'slope');
    // Fixed generation for run-of-river
    v_gen.up(egu('elec', geo, unit), f, t)$unit_fuel(unit, 'water', 'main') = ts_inflow_(unit, f, t);
    // v_online cannot exceed 1
    v_online.up(gu(geo, unitOnline), f, t) = 1;
    // v_state upper border is defined by maxState;
    v_state.up(eg(etype, geo), f, t) = egData(etype, geo, 'maxState');
    // Free storage control ...
*    if(currentStage('scheduling'),
*        v_stoCharge.up(longStorage, f, t) = inf;
*        v_stoCharge.lo(longStorage, f, t) = -inf;
*    );
    // ... or fixed if not using storage value link
*    if(currentStage('dispatch') and not active('storageValue'),
*        v_stoCharge.fx(longStorage, f, t)
*            = v_stoCharge.l(longStorage, f, t);
*    );
    // Max. & min. spilling
    v_spill.lo(egs(etype, geo, storage), f, t)
        = egsData(etype, geo, storage, 'minSpill') * p_stepLength(mSolve, f, t);
    v_spill.up(egs(etype, geo, storage), f, t)
        = egsData(etype, geo, storage, 'maxSpill') * p_stepLength(mSolve, f, t);
    v_transfer.up(eg2g(etype, from_geo, to_geo), f, t)
        = p_transferCap(etype, from_geo, to_geo);
    v_resTransCapacity.up('tertiary', 'resUp', from_bus, to_bus, f, t)
        = p_transferCap('elec', from_bus, to_bus);
    // Reserve provision limits based on resXX_range (or possibly available generation in case of unitVG)
    v_reserve.up(resCapable(resType, 'resUp', geo, unitElec), f, t)
        = min { guDataReserves(geo, unitElec, resType, 'resUp') * [ eguData('elec', geo, unitElec, 'maxCap') + eguData('elec', geo, unitElec, 'maxCharging') ],  // Generator + consuming unit res_range limit
                v_gen.up('elec', geo, unitElec, f, t) - v_gen.lo('elec', geo, unitElec, f, t)                           // Generator + consuming unit available unitElec. output delta
              };
    v_reserve.up(resCapable(resType, 'resDown', geo, unitElec), f, t)
        = min { guDataReserves(geo, unitElec, resType, 'resDown') * [ eguData('elec', geo, unitElec, 'maxCap') + eguData('elec', geo, unitElec, 'maxCharging') ],  // Generator + consuming unit res_range limit
                 v_gen.up('elec', geo, unitElec, f, t) - v_gen.lo('elec', geo, unitElec, f, t)                           // Generator + consuming unit available unitElec. output delta
               };
);
