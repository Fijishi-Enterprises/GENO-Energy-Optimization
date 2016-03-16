* --- Variable limits ---------------------------------------------------------
* Fix storage contents for the beginning
loop(ft_realized(f, t_solve),
$iftheni '%mode%' == 'findStorageStart'
        v_stoContent.lo(etype, geo, storage, f, t_solve)
           = usData(etype, geo, storage, 'min_content') * usData(etype, geo, storage, 'max_content');
        v_stoContent.up(etype, geo, storage, f, t_solve) = usData(etype, geo, storage, 'max_content');
$else
        v_stoContent.fx(etype, geo, storage, f, t_solve)$(ord(t_solve) = modelSolveRules('schedule', 't_start'))
            = ts_stoContent(storage, f, t_solve) * usData(etype, geo, storage, 'max_content');
        v_stoContent.fx(etype, geo, storage, f, t_solve)$(not ord(t_solve) = modelSolveRules('schedule', 't_start'))
            = v_stoContent.l(etype, geo, storage, f, t_solve);
$endif
    // Free online capacity for the first loop
    if(elapsed = 0 and not active('addOn'),
        v_online.up(gu(geo, unitOnline), f, t_solve) = 1;
    // Fix online capacity for later solutions
    else
        v_online.fx(gu(geo, unitOnline), f, t_solve) = v_online.l(geo, unitOnline, f, t_solve);
    );

);

* Other time dependent parameters and variable limits
loop(ft(f, t),
    // Max. energy generation
    v_gen.up(egu(etype, geo, unit), f, t)$(not unitVG(unit)) = uData(etype, geo, unit, 'max_cap') * uData(etype, geo, unit, 'availability');
    v_gen.up(egu(etype, geo, unitVG), f, t)$(not unitHydro(unitVG))      // Should only be about reservoir or RoR+reservoir hydro
        = sum(flow$(flow_unit(flow, unitVG) and gu(geo, unitVG)),
              ts_cf(flow, geo, f, t) *
              uData(etype, geo, unitVG, 'max_cap') *
              uData(etype, geo, unitVG, 'availability')
          );
    // Min. generation to zero for units without consumption
    v_gen.lo(egu(etype, geo, unit), f, t)$(not uData(etype, geo, unit, 'max_loading')) = 0;
    // Max. consumption capacity for electricity storages
    v_gen.lo(egu_input(etype, geo, unit), f, t) = -uData(etype, geo, unit, 'max_loading');
    // Max. unitElec consumption of unitHeat pumps and such
    v_gen.lo(egu_input('elec', geo, unit), f, t)$sum(etype, egu('heat', geo, unit)) = -uData('heat', geo, unit, 'max_cap') * uData('heat', geo, unit, 'avg_fuel_eff');
    // Fixed generation for run-of-river
    v_gen.up(egu('elec', geo, unit), f, t)$unit_fuel(unit, 'water', 'main') = ts_inflow(unit, f, t);
    // v_online cannot exceed 1
    v_online.up(gu(geo, unitOnline), f, t) = 1;
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
        = usData(etype, geo, storage, 'min_spill') * p_stepLength(m_solve, f, t);
    v_spill.up(egs(etype, geo, storage), f, t)
        = usData(etype, geo, storage, 'max_spill') * p_stepLength(m_solve, f, t);
    v_transfer.up(eg2g(etype, from_geo, to_geo), f, t)
        = p_transferCap(etype, from_geo, to_geo);
    v_resTransCapacity.up('tertiary', 'resUp', from_bus, to_bus, f, t)
        = p_transferCap('elec', from_bus, to_bus);
    // Reserve provision limits based on resXX_range (or possibly available generation in case of unitVG)
    v_reserve.up(resCapable(resType, 'resUp', geo, unitElec), f, t)
        = min { uReserveData(geo, unitElec, resType, 'resUp') * [ uData('elec', geo, unitElec, 'max_cap') + uData('elec', geo, unitElec, 'max_loading') ],  // Generator + consuming unit res_range limit
                v_gen.up('elec', geo, unitElec, f, t) - v_gen.lo('elec', geo, unitElec, f, t)                           // Generator + consuming unit available unitElec. output delta
              };
    v_reserve.up(resCapable(resType, 'resDown', geo, unitElec), f, t)
        = min { uReserveData(geo, unitElec, resType, 'resDown') * [ uData('elec', geo, unitElec, 'max_cap') + uData('elec', geo, unitElec, 'max_loading') ],  // Generator + consuming unit res_range limit
                 v_gen.up('elec', geo, unitElec, f, t) - v_gen.lo('elec', geo, unitElec, f, t)                           // Generator + consuming unit available unitElec. output delta
               };
);
