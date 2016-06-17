* --- Variable limits ---------------------------------------------------------
* Fix storage contents for the beginning
loop(ft_realized(f, tSolve),
$iftheni '%mode%' == 'findStorageStart'
        v_stoContent.lo(grid, node, storage, f, tSolve)
           = gnsData(grid, node, storage, 'min_content') * gnsData(grid, node, storage, 'maxContent');
        v_stoContent.up(grid, node, storage, f, tSolve) = gnsData(grid, node, storage, 'maxContent');
$else
        v_stoContent.fx(grid, node, storage, f, tSolve)$(ord(tSolve) = mSettings('schedule', 't_start'))
            = ts_stoContent(storage, f, tSolve) * gnsData(grid, node, storage, 'maxContent');
        v_stoContent.fx(grid, node, storage, f, tSolve)$(not ord(tSolve) = mSettings('schedule', 't_start'))
            = v_stoContent.l(grid, node, storage, f, tSolve);
$endif
    // Free online capacity and state for the first loop
    if(tElapsed = 0 and not active('addOn'),
        v_online.up(nu(node, unitOnline), f, tSolve) = 1;
        v_state.up(gn(grid, node), f, tSolve) = gnData(grid, node, 'maxState');
    // Fix online capacity and state for later solutions
    else
        v_online.fx(nu(node, unitOnline), f, tSolve) = v_online.l(node, unitOnline, f, tSolve);
        v_state.fx(gn(grid, node), f, tSolve) = v_state.l(grid, node, f, tSolve);
    );

);

* Other time dependent parameters and variable limits
loop(ft(f, t),
    // Max. energy generation
    v_gen.up(gnu(grid, node, unit), f, t)$(not unitVG(unit)) = gnuData(grid, node, unit, 'maxCap') * sum(node_, nuData(node_, unit, 'availability'));
    v_gen.up(gnu(grid, node, unitVG), f, t)$(not unitHydro(unitVG))      // Should only be about reservoir or RoR+reservoir hydro
        = sum(flow$(flow_unit(flow, unitVG) and nu(node, unitVG)),
              ts_cf_(flow, node, f, t) *
              gnuData(grid, node, unitVG, 'maxCap') *
              nuData(node, unitVG, 'availability')
          );
    // Min. generation to zero for units without consumption
    v_gen.lo(gnu(grid, node, unit), f, t)$(not gnuData(grid, node, unit, 'maxCharging')) = 0;
    // Max. consumption capacity for chargable storages
    v_gen.lo(gnu_input(grid, node, unit), f, t) = -gnuData(grid, node, unit, 'maxCharging');
    // Max. unitElec consumption of unitHeat pumps and such
    v_gen.lo(gnu_input('elec', node, unit), f, t)$sum(grid, gnu('heat', node, unit)) = -gnuData('heat', node, unit, 'maxCap') * nuData(node, unit, 'slope');
    // Fixed generation for run-of-river
    v_gen.up(gnu('elec', node, unit), f, t)$unit_fuel(unit, 'water', 'main') = ts_inflow_(unit, f, t);
    // v_online cannot exceed 1
    v_online.up(nu(node, unitOnline), f, t) = 1;
    // v_state upper border is defined by maxState;
    v_state.up(gn(grid, node), f, t) = gnData(grid, node, 'maxState');
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
    v_spill.lo(gns(grid, node, storage), f, t)
        = gnsData(grid, node, storage, 'minSpill') * p_stepLength(mSolve, f, t);
    v_spill.up(gns(grid, node, storage), f, t)
        = gnsData(grid, node, storage, 'maxSpill') * p_stepLength(mSolve, f, t);
    v_transfer.up(gn2n(grid, from_node, to_node), f, t)
        = p_transferCap(grid, from_node, to_node);
    v_resTransCapacity.up('tertiary', 'resUp', from_node, to_node, f, t)
        = p_transferCap('elec', from_node, to_node);
    // Reserve provision limits based on resXX_range (or possibly available generation in case of unitVG)
    v_reserve.up(resCapable(resType, 'resUp', node, unitElec), f, t)
        = min { nuDataReserves(node, unitElec, resType, 'resUp') * [ gnuData('elec', node, unitElec, 'maxCap') + gnuData('elec', node, unitElec, 'maxCharging') ],  // Generator + consuming unit res_range limit
                v_gen.up('elec', node, unitElec, f, t) - v_gen.lo('elec', node, unitElec, f, t)                           // Generator + consuming unit available unitElec. output delta
              };
    v_reserve.up(resCapable(resType, 'resDown', node, unitElec), f, t)
        = min { nuDataReserves(node, unitElec, resType, 'resDown') * [ gnuData('elec', node, unitElec, 'maxCap') + gnuData('elec', node, unitElec, 'maxCharging') ],  // Generator + consuming unit res_range limit
                 v_gen.up('elec', node, unitElec, f, t) - v_gen.lo('elec', node, unitElec, f, t)                           // Generator + consuming unit available unitElec. output delta
               };
);
