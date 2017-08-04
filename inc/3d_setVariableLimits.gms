* --- Variable limits ---------------------------------------------------------
// v_state absolute boundaries set according to p_gn parameters;
  // When using constant values and to supplement time series with constant values (time series will override when data available)
v_state.up(gn_state(grid, node), ft_limits(f, t))${p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'useConstant') and not ft_fix(f,t)} = p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'constant') * p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'multiplier');
v_state.lo(gn_state(grid, node), ft_limits(f, t))${p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'useConstant') and not ft_fix(f,t)} = p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'constant') * p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'multiplier');
v_state.fx(gn_state(grid, node), ft_limits(f, t))$(p_gn(grid, node, 'boundAll') and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useConstant')) = p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'constant') * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier');
  // When using time series
v_state.up(gn_state(grid, node), ft_limits(f, t))${p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'useTimeSeries') and not ft_fix(f,t)} = ts_nodeState_(grid, node,   'upwardLimit', f, t) * p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'multiplier');
v_state.lo(gn_state(grid, node), ft_limits(f, t))${p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'useTimeSeries') and not ft_fix(f,t)} = ts_nodeState_(grid, node, 'downwardLimit', f, t) * p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'multiplier');
v_state.fx(gn_state(grid, node), ft_limits(f, t))$(p_gn(grid, node, 'boundAll') and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useTimeSeries')) = ts_nodeState_(grid, node, 'reference', f, t) * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier');

* Other time dependent parameters and variable limits
    // Max. energy generation
v_gen.up(gnu(grid, node, unit), ft_limits(f,t))$(not unit_flow(unit)) = p_gnu(grid, node, unit, 'maxGen') * p_unit(unit, 'availability');
v_gen.up(gnu(grid, node, unit_flow), ft_limits(f,t))      // Should only be about variable generation
    = sum(flow$(flowUnit(flow, unit_flow) and nu(node, unit_flow)),
          ts_cf_(flow, node, f, t) *
          p_gnu(grid, node, unit_flow, 'maxGen') *
          p_unit(unit_flow, 'availability')
      );

// Min. generation to zero for units without consumption
v_gen.lo(gnu(grid, node, unit), ft_limits(f,t))$(not p_gnu(grid, node, unit, 'maxCons')) = 0;
// Max. consumption capacity
v_gen.lo(gnu(grid, node, unit), ft_limits(f,t))$gnu_input(grid, node, unit) = -p_gnu(grid, node, unit, 'maxCons');

// In the case of negative generation (currently only used for cooling equipment)
v_gen.lo(gnu(grid, node, unit), ft_limits(f,t))${p_gnu(grid, node, unit, 'maxGen') < 0} = p_gnu(grid, node, unit, 'maxGen');
v_gen.up(gnu(grid, node, unit), ft_limits(f,t))${p_gnu(grid, node, unit, 'maxGen') < 0} = 0;

// v_online cannot exceed unit count
v_online.up(uft_limits_online(unit, f, t)) = p_unit(unit, 'unitCount');
// Restrict v_online also in the last dynamic time step
v_online.up(uft_limits_online(unit, f, t))${mftLastSteps(mSolve, f, t)} = p_unit(unit, 'unitCount');

// Possible constraints for generator ramping speeds
v_genRamp.up(gnu(grid, node, unit), ft_limits(f, t))${gnuft_ramp(grid, node, unit, f, t) AND p_gnu(grid, node, unit, 'maxRampUp')} = p_gnu(grid, node, unit, 'maxRampUp');
v_genRamp.lo(gnu(grid, node, unit), ft_limits(f, t))${gnuft_ramp(grid, node, unit, f, t) AND p_gnu(grid, node, unit, 'maxRampDown')} = -p_gnu(grid, node, unit, 'maxRampDown');

// Max. & min. spilling
v_spill.lo(gn(grid, node), ft_limits(f, t))$p_gnBoundaryPropertiesForStates(grid, node, 'minSpill', 'useConstant')
    = p_gnBoundaryPropertiesForStates(grid, node, 'minSpill', 'constant') * p_gnBoundaryPropertiesForStates(grid, node, 'minSpill', 'multiplier') * p_stepLength(mSolve, f, t);
v_spill.lo(gn(grid, node), ft_limits(f, t))$p_gnBoundaryPropertiesForStates(grid, node, 'minSpill', 'useTimeSeries')
    = ts_nodeState_(grid, node, 'minSpill', f, t) * p_gnBoundaryPropertiesForStates(grid, node, 'minSpill', 'multiplier') * p_stepLength(mSolve, f, t);
v_spill.up(gn(grid, node), ft_limits(f, t))$p_gnBoundaryPropertiesForStates(grid, node, 'maxSpill', 'useConstant')
    = p_gnBoundaryPropertiesForStates(grid, node, 'maxSpill', 'constant') * p_gnBoundaryPropertiesForStates(grid, node, 'maxSpill', 'multiplier') * p_stepLength(mSolve, f, t);
v_spill.up(gn(grid, node), ft_limits(f, t))$p_gnBoundaryPropertiesForStates(grid, node, 'maxSpill', 'useTimeSeries')
    = ts_nodeState_(grid, node, 'maxSpill', f, t) * p_gnBoundaryPropertiesForStates(grid, node, 'maxSpill', 'multiplier') * p_stepLength(mSolve, f, t);

// Restrictions on transferring energy between nodes
v_transfer.up(gn2n(grid, from_node, to_node), ft_limits(f, t))
    = p_gnn(grid, from_node, to_node, 'transferCap');
v_resTransfer.up(restype, 'up', from_node, to_node, ft_limits(f, t))$(restypeDirectionNode(restype, 'up', from_node) and restypeDirectionNode(restype, 'up', to_node))
    = p_gnn('elec', from_node, to_node, 'transferCap');

// Reserve provision limits based on resXX_range (or possibly available generation in case of unit_flow)
v_reserve.up(nuRescapable(restype, 'up', node, unit_elec), ft_limits(f, t))$nuft(node, unit_elec, f, t)
    = min { p_nuReserves(node, unit_elec, restype, 'up') * [ p_gnu('elec', node, unit_elec, 'maxGen') + p_gnu('elec', node, unit_elec, 'maxCons') ],  // Generator + consuming unit res_range limit
            v_gen.up('elec', node, unit_elec, f, t) - v_gen.lo('elec', node, unit_elec, f, t)                           // Generator + consuming unit available unit_elec. output delta
          };
v_reserve.up(nuRescapable(restype, 'down', node, unit_elec), ft_limits(f, t))$nuft(node, unit_elec, f, t)
    = min { p_nuReserves(node, unit_elec, restype, 'down') * [ p_gnu('elec', node, unit_elec, 'maxGen') + p_gnu('elec', node, unit_elec, 'maxCons') ],  // Generator + consuming unit res_range limit
             v_gen.up('elec', node, unit_elec, f, t) - v_gen.lo('elec', node, unit_elec, f, t)                           // Generator + consuming unit available unit_elec. output delta
           };

* --- Bounds overwritten for the first solve -----------------------------------
loop(ft_limits(f, tSolve),
    // First solve, state variables (only if boundStart flag is true)
    v_state.fx(grid, node, f, tSolve)$(gn_state(grid,node) and p_gn(grid, node, 'boundStart') and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useConstant') and tSolveFirst = mSettings(mSolve, 't_start'))
      = p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'constant') * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier');
    v_state.fx(grid, node, f, tSolve)$(gn_state(grid,node) and p_gn(grid, node, 'boundStart') and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useTimeSeries') and tSolveFirst = mSettings(mSolve, 't_start'))
      = ts_nodeState_(grid, node, 'reference', 'f00', tSolve) * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier');

    // First solve, online variables
    v_online.up(uft_online(unit, f, tSolve))${tSolveFirst = mSettings(mSolve, 't_start')} = p_unit(unit, 'unitCount');

    // State and online variables fixed for the subsequent solves
    v_state.fx(gn_state(grid, node), ft_fix(f,t))${not ord(t) = mSettings(mSolve, 't_start')} = v_state.l(grid, node, f, t);
    v_online.fx(uft_online(unit, ft_fix(f,t)))${not ord(t) = mSettings(mSolve, 't_start')} = v_online.l(unit, f, t);
);

v_state.fx(grid, node, f, t)$(mftLastSteps(mSolve, f, t) and p_gn(grid, node, 'boundStartToEnd')) = v_state.l(grid, node, f, tSolve);


