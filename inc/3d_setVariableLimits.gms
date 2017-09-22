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
v_state.up(gn_state(grid, node), ft_full(f, t))${   p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'useConstant')
                                                    and [ft_dynamic(f, t) or ord(t) = tSolveFirst]
    } = p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'constant') * p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'multiplier');
v_state.lo(gn_state(grid, node), ft_full(f, t))${   p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'useConstant')
                                                    and [ft_dynamic(f, t) or ord(t) = tSolveFirst]
    } = p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'constant') * p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'multiplier');
v_state.fx(gn_state(grid, node), ft_full(f, t))${   p_gn(grid, node, 'boundAll')
                                                    and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useConstant')
                                                    and [ft_dynamic(f, t) or ord(t) = tSolveFirst]
    } = p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'constant') * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier');

// When using time series
v_state.up(gn_state(grid, node), ft_full(f, t))${   p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'useTimeSeries')
                                                    and not cf_Central(f,t)
                                                    and [ft_dynamic(f, t) or ord(t) = tSolveFirst]
    } = ts_nodeState_(grid, node,   'upwardLimit', f, t) * p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'multiplier');
v_state.lo(gn_state(grid, node), ft_full(f, t))${   p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'useTimeSeries')
                                                    and not cf_Central(f,t)
                                                    and [ft_dynamic(f, t) or ord(t) = tSolveFirst]
    } = ts_nodeState_(grid, node, 'downwardLimit', f, t) * p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'multiplier');
v_state.fx(gn_state(grid, node), ft_full(f, t))${   p_gn(grid, node, 'boundAll')
                                                    and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useTimeSeries')
                                                    and not cf_Central(f,t)
                                                    and [ft_dynamic(f, t) or ord(t) = tSolveFirst]
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

// Ramping capability of units without online variable and not part of investment set
loop(ms(mSolve, s),
    v_genRamp.up(grid, node, unit, f, t+pt(t))${  ft(f, t)
                                              and gnuft_ramp(grid, node, unit, f, t)
                                              and msft(mSolve, s, f, t)
                                              and ord(t) > msStart(mSolve, s)
                                              and p_gnu(grid, node, unit, 'maxRampUp')
                                              and not uft_online_incl_previous(unit, f+cpf(f,t), t+pt(t))
                                              and not unit_investLP(unit)
                                              and not unit_investMIP(unit)

        } = ( p_gnu(grid, node, unit, 'maxGen') - p_gnu(grid, node, unit, 'maxCons') )
            * p_gnu(grid, node, unit, 'maxRampUp')
            * 60 / 100;  // Unit conversion from [p.u./min] to [MW/h]
    v_genRamp.lo(grid, node, unit, f, t+pt(t))${  ft(f, t)
                                              and gnuft_ramp(grid, node, unit, f, t)
                                              and msft(mSolve, s, f, t)
                                              and ord(t) > msStart(mSolve, s)
                                              and p_gnu(grid, node, unit, 'maxRampDown')
                                              and not uft_online_incl_previous(unit, f+cpf(f,t), t+pt(t))
                                              and not unit_investLP(unit)
                                              and not unit_investMIP(unit)

        } = -( p_gnu(grid, node, unit, 'maxGen') - p_gnu(grid, node, unit, 'maxCons') )
            * p_gnu(grid, node, unit, 'maxRampDown')
            * 60 / 100;  // Unit conversion from [p.u./min] to [MW/h]
);

// v_online cannot exceed unit count
v_online.up(unit, ft_full(f,t))${   (   uft_online(unit, f, t)
                                        or [    uft_online(unit, f, t+pt(t))
                                                and fRealization(f)
                                           ]
                                    ) and not unit_investMIP(unit)
    } = p_unit(unit, 'unitCount');

// v_online is zero for units with continuous online variable
v_online.fx(unit, ft_full(f,t))${   (   uft_online(unit, f, t)
                                        or [   uft_online(unit, f, t+pt(t))
                                               and fRealization(f)
                                               ]
                                    ) and unit_investLP(unit)
    } = 0;
v_online.fx(uft_online_incl_previous(unit, f, t))${unit_investLP(unit)
    } = 0;

// v_online_LP is zero for units without continuous online variable
v_online_LP.fx(unit, ft_full(f,t))${   (   uft_online(unit, f, t)
                                           or [   uft_online(unit, f, t+pt(t))
                                                  and fRealization(f)
                                              ]
                                       ) and not unit_investLP(unit)
    } = 0;
v_online_LP.fx(uft_online_incl_previous(unit, f, t))${not unit_investLP(unit)
    } = 0;

// Max. & min. spilling
v_spill.lo(gn(grid, node), ft(f, t))${p_gnBoundaryPropertiesForStates(grid, node, 'minSpill', 'useConstant')
    } = p_gnBoundaryPropertiesForStates(grid, node, 'minSpill', 'constant') * p_gnBoundaryPropertiesForStates(grid, node, 'minSpill', 'multiplier');
v_spill.lo(gn(grid, node), ft(f, t))${p_gnBoundaryPropertiesForStates(grid, node, 'minSpill', 'useTimeSeries')
    } = ts_nodeState_(grid, node, 'minSpill', f, t) * p_gnBoundaryPropertiesForStates(grid, node, 'minSpill', 'multiplier');
v_spill.up(gn(grid, node), ft(f, t))${p_gnBoundaryPropertiesForStates(grid, node, 'maxSpill', 'useConstant')
    } = p_gnBoundaryPropertiesForStates(grid, node, 'maxSpill', 'constant') * p_gnBoundaryPropertiesForStates(grid, node, 'maxSpill', 'multiplier');
v_spill.up(gn(grid, node), ft(f, t))${p_gnBoundaryPropertiesForStates(grid, node, 'maxSpill', 'useTimeSeries')
    } = ts_nodeState_(grid, node, 'maxSpill', f, t) * p_gnBoundaryPropertiesForStates(grid, node, 'maxSpill', 'multiplier');

// Restrictions on transferring energy between nodes
v_transfer.up(gn2n_directional(grid, node, node_), ft(f, t))$(not p_gnn(grid, node, node_, 'transferCapInvLimit'))
    = p_gnn(grid, node, node_, 'transferCap');
v_transfer.lo(gn2n_directional(grid, node, node_), ft(f, t))$(not p_gnn(grid, node, node_, 'transferCapInvLimit'))
    = -p_gnn(grid, node_, node, 'transferCap');
v_transferRightward.up(gn2n_directional(grid, node, node_), ft(f, t))$(not p_gnn(grid, node, node_, 'transferCapInvLimit'))
    = p_gnn(grid, node, node_, 'transferCap');
v_transferLeftward.up(gn2n_directional(grid, node, node_), ft(f, t))$(not p_gnn(grid, node, node_, 'transferCapInvLimit'))
    = p_gnn(grid, node_, node, 'transferCap');

// Reserve provision limits based on resXX_range (or possibly available generation in case of unit_flow)
v_reserve.up(nuRescapable(restype, 'up', node, unit_elec), f+cf_nReserves(node, restype, f, t), t)${    nuft(node, unit_elec, f, t)
                                                                                                        and ord(t) < tSolveFirst + mSettings(mSolve, 't_reserveLength')
    } = min {   p_nuReserves(node, unit_elec, restype, 'up') * [ p_gnu('elec', node, unit_elec, 'maxGen') + p_gnu('elec', node, unit_elec, 'maxCons') ],  // Generator + consuming unit res_range limit
                v_gen.up('elec', node, unit_elec, f, t) - v_gen.lo('elec', node, unit_elec, f, t) // Generator + consuming unit available unit_elec. output delta
                }
            * ( + 1${ft_nReserves(node, restype, f+cf_nReserves(node, restype, f, t), t)} // reserveContribution limits the reliability of reserves locked ahead of time.
                + p_nuReserves(node, unit_elec, restype, 'reserveContribution')${not ft_nReserves(node, restype, f+cf_nReserves(node, restype, f, t), t)}
              );
v_reserve.up(nuRescapable(restype, 'down', node, unit_elec), f+cf_nReserves(node, restype, f, t), t)${  nuft(node, unit_elec, f, t)
                                                                                                        and ord(t) < tSolveFirst + mSettings(mSolve, 't_reserveLength')
    } = min {   p_nuReserves(node, unit_elec, restype, 'down') * [ p_gnu('elec', node, unit_elec, 'maxGen') + p_gnu('elec', node, unit_elec, 'maxCons') ],  // Generator + consuming unit res_range limit
                v_gen.up('elec', node, unit_elec, f, t) - v_gen.lo('elec', node, unit_elec, f, t) // Generator + consuming unit available unit_elec. output delta
                }
            * ( + 1${ft_nReserves(node, restype, f+cf_nReserves(node, restype, f, t), t)} // reserveContribution limits the reliability of reserves locked ahead of time.
                + p_nuReserves(node, unit_elec, restype, 'reserveContribution')${not ft_nReserves(node, restype, f+cf_nReserves(node, restype, f, t), t)}
              );

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
v_investTransfer_LP.up(gn2n_directional(grid, from_node, to_node), t)${not p_gnn(grid, from_node, to_node, 'investMIP')
    } = p_gnn(grid, from_node, to_node, 'transferCapInvLimit');
v_investTransfer_LP.fx(gn2n_directional(grid, from_node, to_node), t)${p_gnn(grid, from_node, to_node, 'investMIP')
                                                        or not t_invest(t)
    } = 0;
v_investTransfer_MIP.up(gn2n_directional(grid, from_node, to_node), t)${p_gnn(grid, from_node, to_node, 'investMIP')
    } = p_gnn(grid, from_node, to_node, 'transferCapInvLimit') / p_gnn(grid, from_node, to_node, 'unitSize');
v_investTransfer_MIP.fx(gn2n_directional(grid, from_node, to_node), t)${not p_gnn(grid, from_node, to_node, 'investMIP')
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
                                                                                and not unit_flow(unit_elec) // NOTE! Units using flows can change their reserve (they might not have as much available in real time as they had bid)
            } = r_reserve(restype, up_down, node, unit_elec, f, t);
        v_resTransferRightward.fx(restype, up_down, node, node_, f, t)${   ft_nReserves(node, restype, f, t)
                                                                    and restypeDirectionNode(restype, up_down, node_)
                                                                    and ord(t) >= mSettings(mSolve, 't_start') + p_nReserves(node, restype, 'update_frequency') // Don't lock reserves before the first update
                                                                    and sum(grid, gn2n(grid, node, node_))
            } = r_resTransferRightward(restype, up_down, node, node_, f, t);
        v_resTransferLeftward.fx(restype, up_down, node, node_, f, t)${   ft_nReserves(node, restype, f, t)
                                                                    and restypeDirectionNode(restype, up_down, node_)
                                                                    and ord(t) >= mSettings(mSolve, 't_start') + p_nReserves(node, restype, 'update_frequency') // Don't lock reserves before the first update
                                                                    and sum(grid, gn2n(grid, node, node_))
            } = r_resTransferLeftward(restype, up_down, node, node_, f, t);

    // Free the tertiary reserves for the realization
    v_reserve.fx(nuRescapable('tertiary', up_down, node, unit_elec), ft_realized(ft(f,t)))${    nuft(node, unit_elec, f, t)
        } = 0;
    v_resTransferRightward.fx('tertiary', up_down, node, node_, ft_realized(ft(f,t)))${    sum(grid, gn2n(grid, node, node_))
        } = 0;
    v_resTransferLeftward.fx('tertiary', up_down, node, node_, ft_realized(ft(f,t)))${    sum(grid, gn2n(grid, node, node_))
        } = 0;
);
* --- Bounds overwritten for the first timestep --------------------------------
loop(mftStart(mSolve, f, t),
    // First solve, state variables (only if boundStart flag is true)
    v_state.fx(gn_state(grid, node), f, t)${    p_gn(grid, node, 'boundStart')
                                                and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useConstant')
                                                and tSolveFirst = mSettings(mSolve, 't_start')
        } = p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'constant') * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier');
    // Time series form boundary
    v_state.fx(gn_state(grid, node), f, t)${    p_gn(grid, node, 'boundStart')
                                                and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useTimeSeries')
                                                and tSolveFirst = mSettings(mSolve, 't_start')
        } = ts_nodeState_(grid, node, 'reference', f, t) * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier');

    // State and online variables fixed for the subsequent solves
    v_state.fx(gn_state(grid, node), f, t)${    not ord(t) = mSettings(mSolve, 't_start')
        } = r_state(grid, node, f, t);
    v_online.fx(uft_online(unit, f, t))${  not ord(t) = mSettings(mSolve, 't_start')
        } = r_online(unit, f, t);
    v_online.fx(unit, f, t+pt(t))${  not ord(t) = mSettings(mSolve, 't_start')
                                     and uft_online(unit, f, t)
        } = r_online(unit, f, t+pt(t));
    // Generation, startup and shutdown variables fixed for the subsequent solves
    v_gen.fx(gnu(grid, node, unit), f, t+pt(t))${  not ord(t) = mSettings(mSolve, 't_start')
        } = r_gen(grid, node, unit, f, t+pt(t));
);

v_startup.fx(unit, starttype, fRealization(f), t)${  ord(t) < tSolveFirst
                                                     and p_stepLengthNoReset(mSolve, f, t)
    } = r_startup(unit, starttype, f, t);

v_shutdown.fx(unit, fRealization(f), t)${  ord(t) < tSolveFirst
                                           and p_stepLengthNoReset(mSolve, f, t)
    } = r_shutdown(unit, f, t);

// BoundStartToEnd
v_state.fx(grid, node, ft_full(f,t))${  mftLastSteps(mSolve, f, t)
                                        and p_gn(grid, node, 'boundStartToEnd')
    } = r_state(grid, node, f, t);


