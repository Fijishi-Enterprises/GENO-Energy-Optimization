$ontext
This file is part of Backbone.

Backbone is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Backbone is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with Backbone.  If not, see <http://www.gnu.org/licenses/>.
$offtext

* --- Variable limits ---------------------------------------------------------
// v_state absolute boundaries set according to p_gn parameters;
// When using constant values and to supplement time series with constant values (time series will override when data available)
v_state.up(gn_state(grid, node), ft_dynamic(f, t))${p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'useConstant')
    } = p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'constant') * p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'multiplier');
v_state.lo(gn_state(grid, node), ft_dynamic(f, t))${p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'useConstant')
    } = p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'constant') * p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'multiplier');
v_state.fx(gn_state(grid, node), ft_full(f, t))${p_gn(grid, node, 'boundAll')
                                                    and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useConstant')
    } = p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'constant') * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier');

// When using time series
v_state.up(gn_state(grid, node), ft_dynamic(f, t))${p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'useTimeSeries')
    } = ts_nodeState_(grid, node,   'upwardLimit', f, t) * p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'multiplier');
v_state.lo(gn_state(grid, node), ft_dynamic(f, t))${p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'useTimeSeries')
    } = ts_nodeState_(grid, node, 'downwardLimit', f, t) * p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'multiplier');
v_state.fx(gn_state(grid, node), ft_full(f, t))${p_gn(grid, node, 'boundAll')
                                                    and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useTimeSeries')
    } = ts_nodeState_(grid, node, 'reference', f, t) * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier');

// Other time dependent parameters and variable limits
// Max. energy generation
v_gen.up(gnu(grid, node, unit), ft(f,t))${not unit_flow(unit)
    } = p_gnu(grid, node, unit, 'maxGen') * p_unit(unit, 'availability');
v_gen.up(gnu(grid, node, unit_flow), ft(f,t))      // Should only be about variable generation
    = sum(flow$(flowUnit(flow, unit_flow) and nu(node, unit_flow)),
          ts_cf_(flow, node, f, t) *
          p_gnu(grid, node, unit_flow, 'maxGen') *
          p_unit(unit_flow, 'availability')
      );

// Min. generation to zero for units without consumption
v_gen.lo(gnu(grid, node, unit), ft(f,t))${not p_gnu(grid, node, unit, 'maxCons')
    } = 0;
// Max. consumption capacity
v_gen.lo(gnu(grid, node, unit), ft(f,t))${gnu_input(grid, node, unit)
    } = -p_gnu(grid, node, unit, 'maxCons');

// In the case of negative generation (currently only used for cooling equipment)
v_gen.lo(gnu(grid, node, unit), ft(f,t))${p_gnu(grid, node, unit, 'maxGen') < 0
    } = p_gnu(grid, node, unit, 'maxGen');
v_gen.up(gnu(grid, node, unit), ft(f,t))${p_gnu(grid, node, unit, 'maxGen') < 0
    } = 0;

// v_online cannot exceed unit count
v_online.up(uft_online(unit, ft_dynamic(f,t)))
    = p_unit(unit, 'unitCount');
// Restrict v_online also in the last dynamic time step
v_online.up(uft_online(unit, ft_dynamic(f,t)))${mftLastSteps(mSolve, f, t)
    } = p_unit(unit, 'unitCount');

// Possible constraints for generator ramping speeds
v_genRamp.up(gnu(grid, node, unit), ft(f, t))${ gnuft_ramp(grid, node, unit, f, t)
                                                AND p_gnu(grid, node, unit, 'maxRampUp')
    } = p_gnu(grid, node, unit, 'maxRampUp');
v_genRamp.lo(gnu(grid, node, unit), ft(f, t))${ gnuft_ramp(grid, node, unit, f, t)
                                                AND p_gnu(grid, node, unit, 'maxRampDown')
    } = -p_gnu(grid, node, unit, 'maxRampDown');

// Max. & min. spilling
v_spill.lo(gn(grid, node), ft(f, t))${p_gnBoundaryPropertiesForStates(grid, node, 'minSpill', 'useConstant')
    } = p_gnBoundaryPropertiesForStates(grid, node, 'minSpill', 'constant') * p_gnBoundaryPropertiesForStates(grid, node, 'minSpill', 'multiplier') * p_stepLength(mSolve, f, t);
v_spill.lo(gn(grid, node), ft(f, t))${p_gnBoundaryPropertiesForStates(grid, node, 'minSpill', 'useTimeSeries')
    } = ts_nodeState_(grid, node, 'minSpill', f, t) * p_gnBoundaryPropertiesForStates(grid, node, 'minSpill', 'multiplier') * p_stepLength(mSolve, f, t);
v_spill.up(gn(grid, node), ft(f, t))${p_gnBoundaryPropertiesForStates(grid, node, 'maxSpill', 'useConstant')
    } = p_gnBoundaryPropertiesForStates(grid, node, 'maxSpill', 'constant') * p_gnBoundaryPropertiesForStates(grid, node, 'maxSpill', 'multiplier') * p_stepLength(mSolve, f, t);
v_spill.up(gn(grid, node), ft(f, t))${p_gnBoundaryPropertiesForStates(grid, node, 'maxSpill', 'useTimeSeries')
    } = ts_nodeState_(grid, node, 'maxSpill', f, t) * p_gnBoundaryPropertiesForStates(grid, node, 'maxSpill', 'multiplier') * p_stepLength(mSolve, f, t);

// Restrictions on transferring energy between nodes
v_transfer.up(gn2n(grid, from_node, to_node), ft(f, t))
    = p_gnn(grid, from_node, to_node, 'transferCap');
v_resTransfer.up(restype, up_down, from_node, to_node, ft(f, t))${  restypeDirectionNode(restype, up_down, from_node)
                                                                        and restypeDirectionNode(restype, up_down, to_node)
    } = p_gnn('elec', from_node, to_node, 'transferCap');

// Reserve provision limits based on resXX_range (or possibly available generation in case of unit_flow)
v_reserve.up(nuRescapable(restype, 'up', node, unit_elec), ft(f, t))$nuft(node, unit_elec, f, t)
    = min { p_nuReserves(node, unit_elec, restype, 'up') * [ p_gnu('elec', node, unit_elec, 'maxGen') + p_gnu('elec', node, unit_elec, 'maxCons') ],  // Generator + consuming unit res_range limit
            v_gen.up('elec', node, unit_elec, f, t) - v_gen.lo('elec', node, unit_elec, f, t)                           // Generator + consuming unit available unit_elec. output delta
          };
v_reserve.up(nuRescapable(restype, 'down', node, unit_elec), ft(f, t))$nuft(node, unit_elec, f, t)
    = min { p_nuReserves(node, unit_elec, restype, 'down') * [ p_gnu('elec', node, unit_elec, 'maxGen') + p_gnu('elec', node, unit_elec, 'maxCons') ],  // Generator + consuming unit res_range limit
             v_gen.up('elec', node, unit_elec, f, t) - v_gen.lo('elec', node, unit_elec, f, t)                           // Generator + consuming unit available unit_elec. output delta
           };

* --- Bounds overwritten for the first solve -----------------------------------
loop(ft(f, tSolve),
    // First solve, state variables (only if boundStart flag is true)
    v_state.fx(grid, node, f, tSolve)${ gn_state(grid,node)
                                        and p_gn(grid, node, 'boundStart')
                                        and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useConstant')
                                        and tSolveFirst = mSettings(mSolve, 't_start')
        } = p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'constant') * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier');
    // Time series form boundary
    v_state.fx(grid, node, f, tSolve)${ gn_state(grid,node)
                                        and p_gn(grid, node, 'boundStart')
                                        and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useTimeSeries')
                                        and tSolveFirst = mSettings(mSolve, 't_start')
        } = ts_nodeState_(grid, node, 'reference', 'f00', tSolve) * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier');

    // First solve, online variables
    v_online.up(uft_online(unit, f, tSolve))${tSolveFirst = mSettings(mSolve, 't_start')
        } = p_unit(unit, 'unitCount');

    // State and online variables fixed for the subsequent solves
    v_state.fx(gn_state(grid, node), f, tSolve)${not ord(tSolve) = mSettings(mSolve, 't_start')} = v_state.l(grid, node, f, tSolve);
    v_online.fx(uft_online(unit, f, tSolve))${not ord(tSolve) = mSettings(mSolve, 't_start')} = v_online.l(unit, f, tSolve);
);

// BoundStartToEnd
v_state.fx(grid, node, f, t)$(mftLastSteps(mSolve, f, t) and p_gn(grid, node, 'boundStartToEnd')) = v_state.l(grid, node, f, tSolve);


