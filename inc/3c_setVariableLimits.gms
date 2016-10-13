* --- Variable limits ---------------------------------------------------------
// v_state absolute boundaries set according to p_gn parameters;
v_state.up(gn_state(grid, node), ft(f, t))$(p_gn(grid, node, 'maxState')) = p_gn(grid, node, 'maxState');
v_state.up(gn_state(grid, node), f, t)$(mftLastSteps(mSolve, f, t) and p_gn(grid, node, 'maxState')) = p_gn(grid, node, 'maxState');
v_state.lo(gn_state(grid, node), ft(f, t))$(p_gn(grid, node, 'minState')) = p_gn(grid, node, 'minState');
v_state.lo(gn_state(grid, node), f, t)$(mftLastSteps(mSolve, f, t) and p_gn(grid, node, 'minState')) = p_gn(grid, node, 'minState');
v_state.fx(gn_state(grid, node), ft(f, t))$(p_gn(grid, node, 'fixState')) = p_gn(grid, node, 'fixState') * ( p_gn(grid, node, 'maxState')${not p_gn(grid, node, 'absolute')} + p_gn(grid, node, 'absolute') );

* Fix storage contents for the beginning
loop(ft(f, tSolve),
*    v_state.fx(grid, node, f, tSolve)$(gn_state(grid,node) and ord(tSolve) = mSettings('schedule', 't_start'))
*      = ts_nodeState(grid, node, 'fixState', f, tSolve) * (p_gn(grid, node, 'maxState')$(not p_gn(grid, node, 'absolute')) + p_gn(grid, node, 'absolute'));
    v_state.fx(grid, node, f, tSolve)$(gn_state(grid,node) and not ord(tSolve) = mSettings('schedule', 't_start'))
      = v_state.l(grid, node, f, tSolve);

    // Free online capacity and state for the first loop
    if(tSolveFirst = mSettings('schedule', 't_start'),
        v_online.up(uft(unit, f, tSolve)) = 1;
    // Fix online capacity and state for later solutions
    else
        v_online.fx(uft(unit, f, tSolve)) = round(v_online.l(unit, f, tSolve));
        v_state.fx(gn_state(grid, node), f, tSolve) = v_state.l(grid, node, f, tSolve);
    );
);

// Possibility to input v_state boundaries in time-series form. NOTE! Overwrites overlapping constant boundaries!
v_state.up(gn_state(grid, node), ft(f, t))$ts_nodeState(grid, node, 'maxState', f, t) = ts_nodeState(grid, node, 'maxState', f, t);
v_state.lo(gn_state(grid, node), ft(f, t))$ts_nodeState(grid, node, 'minState', f, t) = ts_nodeState(grid, node, 'minState', f, t);
v_state.fx(gn_state(grid, node), ft(f, t))$(not p_gn(grid, node, 'fixOnlyStart') and ts_nodeState(grid, node, 'fixState', f, t))
  = ts_nodeState(grid, node, 'fixState', f, t) * (p_gn(grid, node, 'maxState')$(not p_gn(grid, node, 'absolute')) + p_gn(grid, node, 'absolute'));

// v_stateSlack absolute boundaries determined by the slack data in p_gnSlack
v_stateSlack.up(gnSlack(inc_dec, slack, grid, node), ft(f, t))$p_gnSlack(inc_dec, slack, grid, node, 'maxSlack') = p_gnSlack(inc_dec, slack, grid, node, 'maxSlack');


* Other time dependent parameters and variable limits
    // Max. energy generation
v_gen.up(gnuft(grid, node, unit, f, t))$(not unit_flow(unit)) = p_gnu(grid, node, unit, 'maxGen') * p_unit(unit, 'availability');
v_gen.up(gnuft(grid, node, unit_flow, f, t))      // Should only be about variable generation
    = sum(flow$(flowUnit(flow, unit_flow) and nu(node, unit_flow)),
          ts_cf_(flow, node, f, t) *
          p_gnu(grid, node, unit_flow, 'maxGen') *
          p_unit(unit_flow, 'availability')
      );

*v_sos1.lo(effSelector, uft(unit, f, t))$(sum(effLevelSelectorUnit(effLevel, effSelector, unit), 1)) = p_effUnit(effSelector, unit, 'lb') * sum(gnu(grid, node, unit), p_gnu(grid, node, unit, 'maxGen'));
v_sos1.up(sufts(effGroup, unit, f, t, effSelector))$effSlope(effGroup) = p_effUnit(effSelector, unit, 'rb') * sum(gnu(grid, node, unit), p_gnu(grid, node, unit, 'maxGen'));

// Min. generation to zero for units without consumption
v_gen.lo(gnuft(grid, node, unit, f, t))$(not p_gnu(grid, node, unit, 'maxCons')) = 0;
// Max. consumption capacity for chargable storages
v_gen.lo(gnuft(grid, node, unit, f, t))$gnu_input(grid, node, unit) = -p_gnu(grid, node, unit, 'maxCons');
// Max. consumption for units that convert endogenous inputs to endogenous outputs  !!This doesn't work well with different effSelectors and ways to calculate efficiency
*v_gen.lo(gnuft(grid_, node_input, unit, f, t))$gnu_input(grid_, node_input, unit) = sum(gn(grid, node)$nu(node, unit), -p_gnu(grid, node, unit, 'maxGen') * p_unit(unit, 'slope'));

// v_online cannot exceed unit count
v_online.up(uft(unit, f, t))$sum(effSelector$(not effDirectOff(effSelector)), suft(effSelector, unit, f, t)) = p_unit(unit, 'unitCount');
// Restrict v_online also in the last dynamic time step
v_online.up(uft(unit, f, t))$(sum(effSelector$(not effDirectOff(effSelector)), suft(effSelector, unit, f, t)) and mftLastSteps(mSolve,f,t)) = p_unit(unit, 'unitCount');


// Free storage control ...
*    if(currentStage('scheduling'),
*        v_stoCharge.up(longStorage, ft(f, t)) = inf;
*        v_stoCharge.lo(longStorage, ft(f, t)) = -inf;
*    );
    // ... or fixed if not using storage value link
*    if(currentStage('dispatch') and not active('storageValue'),
*        v_stoCharge.fx(longStorage, ft(f, t))
*            = v_stoCharge.l(longStorage, f, t);
*    );

// Max. & min. spilling
v_spill.lo(gn(grid, node), ft(f, t))$p_gn(grid, node, 'minSpill')
    = p_gn(grid, node, 'minSpill') * p_stepLength(mSolve, f, t);
v_spill.up(gn(grid, node), ft(f, t))$p_gn(grid, node, 'maxSpill')
    = p_gn(grid, node, 'maxSpill') * p_stepLength(mSolve, f, t);

// Restrictions on transferring energy between nodes
v_transfer.up(gn2n(grid, from_node, to_node), ft(f, t))
    = p_gnn(grid, from_node, to_node, 'transferCap');
v_resTransfer.up(restype, 'resUp', from_node, to_node, ft(f, t))$(restypeDirectionNode(restype, 'resUp', from_node) and restypeDirectionNode(restype, 'resUp', to_node))
    = p_gnn('elec', from_node, to_node, 'transferCap');

// Reserve provision limits based on resXX_range (or possibly available generation in case of unit_flow)
v_reserve.up(nuRescapable(restype, 'resUp', node, unit_elec), ft(f, t))$nuft(node, unit_elec, f, t)
    = min { p_nuReserves(node, unit_elec, restype, 'resUp') * [ p_gnu('elec', node, unit_elec, 'maxGen') + p_gnu('elec', node, unit_elec, 'maxCons') ],  // Generator + consuming unit res_range limit
            v_gen.up('elec', node, unit_elec, f, t) - v_gen.lo('elec', node, unit_elec, f, t)                           // Generator + consuming unit available unit_elec. output delta
          };
v_reserve.up(nuRescapable(restype, 'resDown', node, unit_elec), ft(f, t))$nuft(node, unit_elec, f, t)
    = min { p_nuReserves(node, unit_elec, restype, 'resDown') * [ p_gnu('elec', node, unit_elec, 'maxGen') + p_gnu('elec', node, unit_elec, 'maxCons') ],  // Generator + consuming unit res_range limit
             v_gen.up('elec', node, unit_elec, f, t) - v_gen.lo('elec', node, unit_elec, f, t)                           // Generator + consuming unit available unit_elec. output delta
           };

