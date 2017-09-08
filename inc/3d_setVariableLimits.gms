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
v_state.up(gn_state(grid, node), ft_full(f, t))${p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'useConstant')
    } = p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'constant') * p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'multiplier');
v_state.lo(gn_state(grid, node), ft_full(f, t))${p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'useConstant')
    } = p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'constant') * p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'multiplier');
v_state.fx(gn_state(grid, node), ft_full(f, t))${   p_gn(grid, node, 'boundAll')
                                                    and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useConstant')
    } = p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'constant') * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier');

// When using time series
v_state.up(gn_state(grid, node), ft_dynamic(f, t))${p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'useTimeSeries')
    } = ts_nodeState_(grid, node,   'upwardLimit', f, t) * p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'multiplier');
v_state.lo(gn_state(grid, node), ft_dynamic(f, t))${p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'useTimeSeries')
    } = ts_nodeState_(grid, node, 'downwardLimit', f, t) * p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'multiplier');
v_state.fx(gn_state(grid, node), ft_full(f, t))${   p_gn(grid, node, 'boundAll')
                                                    and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useTimeSeries')
    } = ts_nodeState_(grid, node, 'reference', f, t) * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier');
// Other time dependent parameters and variable limits
// Max. energy generation
v_gen.up(gnu(grid, node, unit), ft(f,t))${not unit_flow(unit)
     and not (unit_investLP(unit) or unit_investMIP(unit))} = p_gnu(grid, node, unit, 'maxGen') * p_unit(unit, 'availability');
v_gen.up(gnu(grid, node, unit_flow), ft(f,t))$(not (unit_investLP(unit_flow) or unit_investMIP(unit_flow)))      // Should only be about variable generation
    = sum(flow$(flowUnit(flow, unit_flow) and nu(node, unit_flow)),
          ts_cf_(flow, node, f, t) *
          p_gnu(grid, node, unit_flow, 'maxGen') *
          p_unit(unit_flow, 'availability')
      );

// Min. generation to zero for units without consumption
v_gen.lo(gnu(grid, node, unit), ft(f,t))${not gnu_input(grid, node, unit)
     } = 0;
// Max. consumption capacity
v_gen.lo(gnu(grid, node, unit), ft(f,t))${gnu_input(grid, node, unit)
     and not (unit_investLP(unit) or unit_investMIP(unit))} = -p_gnu(grid, node, unit, 'maxCons');

// In the case of negative generation (currently only used for cooling equipment)
v_gen.lo(gnu(grid, node, unit), ft(f,t))${p_gnu(grid, node, unit, 'maxGen') < 0
    } = p_gnu(grid, node, unit, 'maxGen');
v_gen.up(gnu(grid, node, unit), ft(f,t))${p_gnu(grid, node, unit, 'maxGen') < 0
    } = 0;

// v_online cannot exceed unit count
v_online.up(unit, ft_dynamic(f,t))${    ( uft_online(unit, f, t)
                                          or [    uft_online(unit, f, t+pt(t))
                                                  and fRealization(f)
                                                  ]
                                        ) and not unit_investMIP(unit)
    } = p_unit(unit, 'unitCount');
// Restrict v_online also in the last dynamic time step
v_online.up(uft_online(unit, ft_dynamic(f,t)))${mftLastSteps(mSolve, f, t)
                                                and not unit_investMIP(unit)
    } = p_unit(unit, 'unitCount');
// v_online is zero for units with continuous online variable
v_online.fx(uft_online(unit, ft_full(f,t)))${unit_investLP(unit)
    } = 0;
v_online.fx(unit, ft_dynamic(f,t))${    ( uft_online(unit, f, t)
                                          or [    uft_online(unit, f, t+pt(t))
                                                  and fRealization(f)
                                                  ]
                                        ) and unit_investLP(unit)
    } = 0;
// Restrict v_online also in the last dynamic time step
v_online.fx(uft_online(unit, ft_dynamic(f,t)))${mftLastSteps(mSolve, f, t)
                                                and unit_investLP(unit)
    } = 0;
// v_online_LP is zero for units without continuous online variable
v_online_LP.fx(uft_online(unit, ft_full(f,t)))${not unit_investLP(unit)
    } = 0;
v_online_LP.fx(unit, ft_dynamic(f,t))${    ( uft_online(unit, f, t)
                                             or [    uft_online(unit, f, t+pt(t))
                                                     and fRealization(f)
                                                     ]
                                           ) and not unit_investLP(unit)
    } = 0;
// Restrict v_online_LP also in the last dynamic time step
v_online_LP.fx(uft_online(unit, ft_dynamic(f,t)))${mftLastSteps(mSolve, f, t)
                                                   and not unit_investLP(unit)
    } = 0;

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
v_transfer.up(gn2n(grid, from_node, to_node), ft(f, t))$(not p_gnn(grid, from_node, to_node, 'transferCapInvLimit'))
    = p_gnn(grid, from_node, to_node, 'transferCap');
v_resTransfer.up(restypeDirectionNode(restype, up_down, from_node), to_node, ft(f, t))${    restypeDirectionNode(restype, up_down, to_node)
                                                                                            and sum(grid, gn2n(grid, from_node, to_node)
                                                                                            and not p_gnn('elec', from_node, to_node, 'transferCapInvLimit'))
    } = p_gnn('elec', from_node, to_node, 'transferCap');

// Reserve provision limits based on resXX_range (or possibly available generation in case of unit_flow)
v_reserve.up(nuRescapable(restype, 'up', node, unit_elec), f+cf_nReserves(node, restype, f, t), t)${    nuft(node, unit_elec, f, t)
                                                                                                        and ord(t) < tSolveFirst + mSettings(mSolve, 't_reserveLength')
    } = min {   p_nuReserves(node, unit_elec, restype, 'up') * [ p_gnu('elec', node, unit_elec, 'maxGen') + p_gnu('elec', node, unit_elec, 'maxCons') ],  // Generator + consuming unit res_range limit
                v_gen.up('elec', node, unit_elec, f, t) - v_gen.lo('elec', node, unit_elec, f, t)                           // Generator + consuming unit available unit_elec. output delta
                };
v_reserve.up(nuRescapable(restype, 'down', node, unit_elec), f+cf_nReserves(node, restype, f, t), t)${  nuft(node, unit_elec, f, t)
                                                                                                        and ord(t) < tSolveFirst + mSettings(mSolve, 't_reserveLength')
    } = min {   p_nuReserves(node, unit_elec, restype, 'down') * [ p_gnu('elec', node, unit_elec, 'maxGen') + p_gnu('elec', node, unit_elec, 'maxCons') ],  // Generator + consuming unit res_range limit
                v_gen.up('elec', node, unit_elec, f, t) - v_gen.lo('elec', node, unit_elec, f, t)                           // Generator + consuming unit available unit_elec. output delta
                };

// Max and min capacity investment
v_invest_LP.up(gnu(grid, node, unit), t)${    (p_gnu(grid, node, unit, 'maxGenCap') > 0)
                                              and unit_investLP(unit)
    } = p_gnu(grid, node, unit, 'maxGenCap');
v_invest_LP.up(gnu(grid, node, unit), t)${    (p_gnu(grid, node, unit, 'maxConsCap') > 0)
                                              and unit_investLP(unit)
    } = p_gnu(grid, node, unit, 'maxConsCap');
v_invest_LP.lo(gnu(grid, node, unit), t)${    (p_gnu(grid, node, unit, 'maxGenCap') > 0)
                                              and unit_investLP(unit)
    } = p_gnu(grid, node, unit, 'minGenCap');
v_invest_LP.lo(gnu(grid, node, unit), t)${    (p_gnu(grid, node, unit, 'maxConsCap') > 0)
                                              and unit_investLP(unit)
    } = p_gnu(grid, node, unit, 'minConsCap');
v_invest_LP.fx(gnu(grid, node, unit), t)${    [(not p_gnu(grid, node, unit, 'maxGenCap'))
                                              and (not p_gnu(grid, node, unit, 'maxConsCap'))
                                              ] or unit_investMIP(unit)
                                              or not t_invest(t)
    } = 0;
v_invest_MIP.up(unit, t)${    unit_investMIP(unit)
    } = p_unit(unit, 'maxUnitCount');
v_invest_MIP.lo(unit, t)${    unit_investMIP(unit)
    } = p_unit(unit, 'minUnitCount');
v_invest_MIP.fx(unit, t)${    not unit_investMIP(unit)
                              or not t_invest(t)
    } = 0;
v_investTransfer_LP.up(gn2n(grid, from_node, to_node), t)${not p_gnn(grid, from_node, to_node, 'investMIP')
    } = p_gnn(grid, from_node, to_node, 'transferCapInvLimit');
v_investTransfer_LP.fx(gn2n(grid, from_node, to_node), t)${p_gnn(grid, from_node, to_node, 'investMIP')
                                                        or not t_invest(t)
    } = 0;
v_investTransfer_MIP.up(gn2n(grid, from_node, to_node), t)${p_gnn(grid, from_node, to_node, 'investMIP')
    } = p_gnn(grid, from_node, to_node, 'transferCapInvLimit') / p_gnn(grid, from_node, to_node, 'unitSize');
v_investTransfer_MIP.fx(gn2n(grid, from_node, to_node), t)${not p_gnn(grid, from_node, to_node, 'investMIP')
                                                         or not t_invest(t)
    } = 0;

// If offline hours after which the start-up will be a warm/cold start is not
// defined, fix hot/warm start-up to zero.
v_startup.fx(unit, 'hot', ft_dynamic(f, t))${not p_unit(unit, 'startWarm')} = 0;
v_startup.fx(unit, 'warm', ft_dynamic(f, t))${not p_unit(unit, 'startCold')} = 0;

// Fix reserves between t_jump and gate_closure based on previous allocations
loop(restypeDirectionNode(restypeDirection(restype, up_down), node),
        v_reserve.fx(nuRescapable(restype, up_down, node, unit_elec), f, t)${   ft_nReserves(node, restype, f, t)
                                                                                and ord(t) >= mSettings(mSolve, 't_start') + p_nReserves(node, restype, 'update_frequency') // Don't lock reserves before the first update
                                                                                and not unit_flow(unit_elec)           // NOTE! Units using flows can change their reserve (they might not have as much available in real time as they had bid)
            } = r_reserve(restype, up_down, node, unit_elec, f, t);
        v_resTransfer.fx(restype, up_down, node, to_node, f, t)${   ft_nReserves(node, restype, f, t)
                                                                    and restypeDirectionNode(restype, up_down, to_node)
                                                                    and ord(t) >= mSettings(mSolve, 't_start') + p_nReserves(node, restype, 'update_frequency') // Don't lock reserves before the first update
                                                                    and sum(grid, gn2n(grid, node, to_node))
            } = r_resTransfer(restype, up_down, node, to_node, f, t);

    // Free the tertiary reserves for the realization
    v_reserve.fx(nuRescapable('tertiary', up_down, node, unit_elec), ft_realized(ft(f,t)))${    nuft(node, unit_elec, f, t)
        } = 0;
    v_resTransfer.fx('tertiary', up_down, node, to_node, ft_realized(ft(f,t)))${    sum(grid, gn2n(grid, node, to_node))
        } = 0;
);
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
    v_online.up(uft_online(unit, f, tSolve))${ tSolveFirst = mSettings(mSolve, 't_start')
                                               and not unit_investMIP(unit)
        } = p_unit(unit, 'unitCount');

    // State and online variables fixed for the subsequent solves
    v_state.fx(gn_state(grid, node), f, tSolve)${   not ord(tSolve) = mSettings(mSolve, 't_start')
                                                    and mftStart(mSolve, f, tSolve)
        } = r_state(grid, node, f, tSolve);
    v_online.fx(uft_online(unit, f, tSolve))${  not ord(tSolve) = mSettings(mSolve, 't_start')
                                                and mftStart(mSolve, f, tSolve)
        } = r_online(unit, f, tSolve);
    v_gen.fx(gnu(grid, node, unit), f, tSolve+pt(tSolve))${  not ord(tSolve) = mSettings(mSolve, 't_start')
                                                             and mftStart(mSolve, f, tSolve)
        } = r_gen(grid, node, unit, f, tSolve+pt(tSolve));
);

// BoundStartToEnd
v_state.fx(grid, node, ft_dynamic(f,t))${   mftLastSteps(mSolve, f, t)
                                            and p_gn(grid, node, 'boundStartToEnd')
    } = r_state(grid, node, f, t);


