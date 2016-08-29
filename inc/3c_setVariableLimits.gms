* --- Variable limits ---------------------------------------------------------
* Fix storage contents for the beginning
loop(ft_realized(f, tSolve),
$iftheni '%mode%' == 'findStorageStart'
        v_stoContent.lo(grid, node, storage, f, tSolve)$gns(grid,node,storage)
           = gnsData(grid, node, storage, 'min_content') * gnsData(grid, node, storage, 'maxContent');
        v_stoContent.up(grid, node, storage, f, tSolve)$gns(grid,node,storage)
           = gnsData(grid, node, storage, 'maxContent');
$else
        v_stoContent.fx(grid, node, storage, f, tSolve)$(gns(grid,node,storage) and ord(tSolve) = mSettings('schedule', 't_start'))
            = ts_stoContent(storage, f, tSolve) * gnsData(grid, node, storage, 'maxContent');
        v_stoContent.fx(grid, node, storage, f, tSolve)$(gns(grid,node,storage) and not ord(tSolve) = mSettings('schedule', 't_start'))
            = v_stoContent.l(grid, node, storage, f, tSolve);
$endif
    // Free online capacity and state for the first loop
    if(tSolveFirst = mSettings('schedule', 't_start') and not active('addOn'),
        v_online.up(nu(node, unitOnline), f, tSolve) = 1;
        v_state.up(gnState(grid, node), f, tSolve)$(gnData(grid, node, 'maxState')) = gnData(grid, node, 'maxState');
    // Fix online capacity and state for later solutions
    else
        v_online.fx(nu(node, unitOnline), f, tSolve) = v_online.l(node, unitOnline, f, tSolve);
        v_state.fx(gnState(grid, node), f, tSolve) = v_state.l(grid, node, f, tSolve);
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
    // Max. consumption for units that convert endogenous inputs to endogenous outputs
    v_gen.lo(gnu_input(grid_, node_input, unit), f, t) = sum(gn(grid, node)$nu(node, unit), -gnuData(grid, node, unit, 'maxCap') * nuData(node, unit, 'slope'));
    // Fixed generation for run-of-river
    v_gen.up(gnu('elec', node, unit), f, t)$unit_fuel(unit, 'water', 'main') = ts_inflow_(unit, f, t);
    // v_online cannot exceed 1
    v_online.up(nu(node, unitOnline), f, t) = 1;
    // v_state constant bounds set according to gnData parameters;
    v_state.up(gnState(grid, node), f, t)$(gnData(grid, node, 'maxState')) = gnData(grid, node, 'maxState');
    v_state.lo(gnState(grid, node), f, t)$(gnData(grid, node, 'minState')) = gnData(grid, node, 'minState');
    v_state.fx(gnState(grid, node), f, t)$(gnData(grid, node, 'fixState')) = gnData(grid, node, 'fixState');
    // Possibility to input v_state boundaries in time-series form. NOTE! Overwrites overlapping constant bounds!;
    v_state.up(gnState(grid, node), f, t)$ts_nodeState(grid, node, 'maxState', f, t) = ts_nodeState(grid, node, 'maxState', f, t);
    v_state.lo(gnState(grid, node), f, t)$ts_nodeState(grid, node, 'minState', f, t) = ts_nodeState(grid, node, 'minState', f, t);
    v_state.fx(gnState(grid, node), f, t)$ts_nodeState(grid, node, 'fixState', f, t) = ts_nodeState(grid, node, 'fixState', f, t);
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
        = gnnData(grid, from_node, to_node, 'transferCap');
    v_resTransCapacity.up('tertiary', 'resUp', from_node, to_node, f, t)
        = gnnData('elec', from_node, to_node, 'transferCap');
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
