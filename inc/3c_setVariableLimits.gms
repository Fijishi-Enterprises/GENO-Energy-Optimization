* --- Variable limits ---------------------------------------------------------
* Fix storage contents for the beginning
loop(ft_realized(f, tSolve),
$iftheni '%mode%' == 'findStorageStart'
        v_stoContent.lo(grid, node, storage, f, tSolve)$gnStorage(grid,node,storage)
           = p_gnStorage(grid, node, storage, 'min_content') * p_gnStorage(grid, node, storage, 'maxContent');
        v_stoContent.up(grid, node, storage, f, tSolve)$gnStorage(grid,node,storage)
           = p_gnStorage(grid, node, storage, 'maxContent');
$else
        v_stoContent.fx(grid, node, storage, f, tSolve)$(gnStorage(grid,node,storage) and ord(tSolve) = mSettings('schedule', 't_start'))
            = ts_stoContent(storage, f, tSolve) * p_gnStorage(grid, node, storage, 'maxContent');
        v_stoContent.fx(grid, node, storage, f, tSolve)$(gnStorage(grid,node,storage) and not ord(tSolve) = mSettings('schedule', 't_start'))
            = v_stoContent.l(grid, node, storage, f, tSolve);
$endif
    // Free online capacity and state for the first loop
    if(tSolveFirst = mSettings('schedule', 't_start') and not active('addOn'),
        v_online.up(nu(node, unit_online), f, tSolve) = 1;
        v_state.up(gn_state(grid, node), f, tSolve)$(p_gn(grid, node, 'maxState')) = p_gn(grid, node, 'maxState');
    // Fix online capacity and state for later solutions
    else
        v_online.fx(nu(node, unit_online), f, tSolve) = v_online.l(node, unit_online, f, tSolve);
        v_state.fx(gn_state(grid, node), f, tSolve) = v_state.l(grid, node, f, tSolve);
    );

);

* Other time dependent parameters and variable limits
loop(ft(f, t),
    // Max. energy generation
    v_gen.up(gnu(grid, node, unit), f, t)$(not unit_VG(unit)) = p_gnu(grid, node, unit, 'maxCap') * sum(node_, p_nu(node_, unit, 'availability'));
    v_gen.up(gnu(grid, node, unit_VG), f, t)$(not unit_hydro(unit_VG))      // Should only be about reservoir or RoR+reservoir hydro
        = sum(flow$(flowUnit(flow, unit_VG) and nu(node, unit_VG)),
              ts_cf_(flow, node, f, t) *
              p_gnu(grid, node, unit_VG, 'maxCap') *
              p_nu(node, unit_VG, 'availability')
          );
    // Min. generation to zero for units without consumption
    v_gen.lo(gnu(grid, node, unit), f, t)$(not p_gnu(grid, node, unit, 'maxCharging')) = 0;
    // Max. consumption capacity for chargable storages
    v_gen.lo(gnu_input(grid, node, unit), f, t) = -p_gnu(grid, node, unit, 'maxCharging');
    // Max. consumption for units that convert endogenous inputs to endogenous outputs
    v_gen.lo(gnu_input(grid_, node_input, unit), f, t) = sum(gn(grid, node)$nu(node, unit), -p_gnu(grid, node, unit, 'maxCap') * p_nu(node, unit, 'slope'));
    // Fixed generation for run-of-river
    v_gen.up(gnu('elec', node, unit), f, t)$unitFuelParam(unit, 'water', 'main') = ts_inflow_(unit, f, t);
    // v_online cannot exceed 1
    v_online.up(nu(node, unit_online), f, t) = 1;
    // v_state absolute boundaries set according to p_gn parameters;
    v_state.up(gn_state(grid, node), f, t)$(p_gn(grid, node, 'maxState')) = p_gn(grid, node, 'maxState');
    v_state.lo(gn_state(grid, node), f, t)$(p_gn(grid, node, 'minState')) = p_gn(grid, node, 'minState');
    v_state.fx(gn_state(grid, node), f, t)$(p_gn(grid, node, 'fixState')) = p_gn(grid, node, 'fixState');
    // Possibility to input v_state boundaries in time-series form. NOTE! Overwrites overlapping constant boundaries!
    v_state.up(gn_state(grid, node), f, t)$ts_nodeState(grid, node, 'maxState', f, t) = ts_nodeState(grid, node, 'maxState', f, t);
    v_state.lo(gn_state(grid, node), f, t)$ts_nodeState(grid, node, 'minState', f, t) = ts_nodeState(grid, node, 'minState', f, t);
    v_state.fx(gn_state(grid, node), f, t)$ts_nodeState(grid, node, 'fixState', f, t) = ts_nodeState(grid, node, 'fixState', f, t);
    // v_stateSlack absolute boundaries determined by the slack data in p_gnSlack
    v_stateSlack.up(gnSlack(inc_dec, slack, grid, node), f, t)$p_gnSlack(inc_dec, slack, grid, node, 'maxSlack') = p_gnSlack(inc_dec, slack, grid, node, 'maxSlack');
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
    v_spill.lo(gnStorage(grid, node, storage), f, t)
        = p_gnStorage(grid, node, storage, 'minSpill') * p_stepLength(mSolve, f, t);
    v_spill.up(gnStorage(grid, node, storage), f, t)
        = p_gnStorage(grid, node, storage, 'maxSpill') * p_stepLength(mSolve, f, t);
    v_transfer.up(gn2n(grid, from_node, to_node), f, t)
        = p_gnn(grid, from_node, to_node, 'transferCap');
    v_resTransCapacity.up('tertiary', 'resUp', from_node, to_node, f, t)
        = p_gnn('elec', from_node, to_node, 'transferCap');
    // Reserve provision limits based on resXX_range (or possibly available generation in case of unit_VG)
    v_reserve.up(nuRescapable(restype, 'resUp', node, unit_elec), f, t)
        = min { p_nuReserves(node, unit_elec, restype, 'resUp') * [ p_gnu('elec', node, unit_elec, 'maxCap') + p_gnu('elec', node, unit_elec, 'maxCharging') ],  // Generator + consuming unit res_range limit
                v_gen.up('elec', node, unit_elec, f, t) - v_gen.lo('elec', node, unit_elec, f, t)                           // Generator + consuming unit available unit_elec. output delta
              };
    v_reserve.up(nuRescapable(restype, 'resDown', node, unit_elec), f, t)
        = min { p_nuReserves(node, unit_elec, restype, 'resDown') * [ p_gnu('elec', node, unit_elec, 'maxCap') + p_gnu('elec', node, unit_elec, 'maxCharging') ],  // Generator + consuming unit res_range limit
                 v_gen.up('elec', node, unit_elec, f, t) - v_gen.lo('elec', node, unit_elec, f, t)                           // Generator + consuming unit available unit_elec. output delta
               };
);
v_online.up(nu(node, unit_online), f, t)$mftLastSteps(mSolve,f,t) = 1;
