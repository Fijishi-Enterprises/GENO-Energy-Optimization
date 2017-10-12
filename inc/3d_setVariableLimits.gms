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

* =============================================================================
* --- Variable limits ---------------------------------------------------------
* =============================================================================

* --- Node State Boundaries ---------------------------------------------------

// When using constant values and to supplement time series with constant values (time series will override when data available)
// Upper bound
v_state.up(gn_state(grid, node), ft(f, t))${    p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'useConstant') }
    = p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'constant')
        * p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'multiplier')
;
// Lower bound
v_state.lo(gn_state(grid, node), ft(f, t))${    p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'useConstant') }
    = p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'constant')
        * p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'multiplier')
;
// Fixed value
v_state.fx(gn_state(grid, node), ft(f, t))${    p_gn(grid, node, 'boundAll')
                                                and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useConstant')
                                                }
    = p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'constant')
        * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier')
;
// When using time series
// Upper Bound
v_state.up(gn_state(grid, node), ft(f, t))${    p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'useTimeSeries')
                                                and not df_central(f,t)
                                                }
    = ts_nodeState_(grid, node,   'upwardLimit', f, t)
        * p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'multiplier')
;
// Lower bound
v_state.lo(gn_state(grid, node), ft(f, t))${    p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'useTimeSeries')
                                                and not df_central(f,t)
                                                }
    = ts_nodeState_(grid, node, 'downwardLimit', f, t)
        * p_gnBoundaryPropertiesForStates(grid, node, 'downwardLimit', 'multiplier')
;
// Fixed value
v_state.fx(gn_state(grid, node), ft(f, t))${    p_gn(grid, node, 'boundAll')
                                                and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useTimeSeries')
                                                and not df_central(f,t)
                                                    }
    = ts_nodeState_(grid, node, 'reference', f, t)
        * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier')
;

// Spilling of energy from the nodes
// Max. & min. spilling, use constant value as base and overwrite with time series if desired
v_spill.lo(gn(grid, node_spill), ft(f, t))${    p_gnBoundaryPropertiesForStates(grid, node_spill, 'minSpill', 'constant')   }
    = p_gnBoundaryPropertiesForStates(grid, node_spill, 'minSpill', 'constant')
        * p_gnBoundaryPropertiesForStates(grid, node_spill, 'minSpill', 'multiplier')
;
v_spill.lo(gn(grid, node_spill), ft(f, t))${    p_gnBoundaryPropertiesForStates(grid, node_spill, 'minSpill', 'useTimeSeries') }
    = ts_nodeState_(grid, node_spill, 'minSpill', f, t)
        * p_gnBoundaryPropertiesForStates(grid, node_spill, 'minSpill', 'multiplier')
;
v_spill.up(gn(grid, node_spill), ft(f, t))${    p_gnBoundaryPropertiesForStates(grid, node_spill, 'maxSpill', 'constant') }
    = p_gnBoundaryPropertiesForStates(grid, node_spill, 'maxSpill', 'constant')
        * p_gnBoundaryPropertiesForStates(grid, node_spill, 'maxSpill', 'multiplier')
;
v_spill.up(gn(grid, node_spill), ft(f, t))${    p_gnBoundaryPropertiesForStates(grid, node_spill, 'maxSpill', 'useTimeSeries')    }
    = ts_nodeState_(grid, node_spill, 'maxSpill', f, t)
        * p_gnBoundaryPropertiesForStates(grid, node_spill, 'maxSpill', 'multiplier')
;

* --- Unit Related Variable Boundaries ----------------------------------------

// Constant max. energy generation if investments disabled
v_gen.up(gnuft(gnu_output(grid, node, unit), f,t))${    not unit_flow(unit)
                                                        and not (unit_investLP(unit) or unit_investMIP(unit))
                                                        }
    = p_gnu(grid, node, unit, 'maxGen')
        * p_unit(unit, 'availability')
;
// Time series capacity factor based max. energy generation if investments disabled
v_gen.up(gnuft(gnu_output(grid, node, unit_flow), f,t))${   not (unit_investLP(unit_flow) or unit_investMIP(unit_flow)) }
    = sum(flow${    flowUnit(flow, unit_flow)
                    and nu(node, unit_flow)
                    },
          + ts_cf_(flow, node, f, t)
            * p_gnu(grid, node, unit_flow, 'maxGen')
            * p_unit(unit_flow, 'availability')
      ) // END sum(flow)
;
// Maximum generation to zero to units without generation
v_gen.up(gnuft(grid, node, unit, f, t))${   not gnu_output(grid, node, unit)    }
    = 0
;
// Min. generation to zero for units without consumption
v_gen.lo(gnuft(grid, node, unit, f, t))${   not gnu_input(grid, node, unit) }
    = 0
;
// Constant max. consumption capacity if investments disabled
v_gen.lo(gnuft(gnu_input(grid, node, unit), f, t))${    not (unit_investLP(unit) or unit_investMIP(unit))   }
    = - p_gnu(grid, node, unit, 'maxCons')
        * p_unit(unit, 'availability')
;
// Time series capacity factor based max. consumption if investments disabled
v_gen.lo(gnuft(gnu_input(grid, node, unit_flow), f, t))${   not (unit_investLP(unit_flow) or unit_investMIP(unit_flow)) }
    = - sum(flow${  flowUnit(flow, unit_flow)
                    and nu(node, unit_flow)
                    },
          + ts_cf_(flow, node, f, t)
            * p_gnu(grid, node, unit_flow, 'maxCons')
            * p_unit(unit_flow, 'availability')
      ) // END sum(flow)
;
// In the case of negative generation (currently only used for cooling equipment)
v_gen.lo(gnuft(gnu_output(grid, node, unit), f, t))${   p_gnu(grid, node, unit, 'maxGen') < 0   }
    = p_gnu(grid, node, unit, 'maxGen')
;
v_gen.up(gnuft(gnu_output(grid, node, unit), f, t))${   p_gnu(grid, node, unit, 'maxGen') < 0   }
    = 0;

// Ramping capability of units without online variable and not part of investment set
// !!! PENDING CHANGES !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
$ontext
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
$offtext

// v_online cannot exceed unit count if investments disabled
// LP variant
v_online_LP.up(uft_onlineLP(unit, f, t))${  not unit_investLP(unit) }
    = p_unit(unit, 'unitCount')
;
// MIP variant
v_online_MIP.up(uft_onlineMIP(unit, f, t))${    not unit_investMIP(unit) }
    = p_unit(unit, 'unitCount')
;

* --- Energy Transfer Boundaries ----------------------------------------------

// Restrictions on transferring energy between nodes without investments
// Total transfer variable restricted from both above and below (free variable)
v_transfer.up(gn2n_directional(grid, node, node_), ft(f, t))${  not p_gnn(grid, node, node_, 'transferCapInvLimit') }
    = p_gnn(grid, node, node_, 'transferCap')
;
v_transfer.lo(gn2n_directional(grid, node, node_), ft(f, t))${  not p_gnn(grid, node, node_, 'transferCapInvLimit') }
    = -p_gnn(grid, node_, node, 'transferCap')
;
// Directional transfer variables only restricted from above (positive variables)
v_transferRightward.up(gn2n_directional(grid, node, node_), ft(f, t))${ not p_gnn(grid, node, node_, 'transferCapInvLimit') }
    = p_gnn(grid, node, node_, 'transferCap')
;
v_transferLeftward.up(gn2n_directional(grid, node, node_), ft(f, t))${  not p_gnn(grid, node, node_, 'transferCapInvLimit') }
    = p_gnn(grid, node_, node, 'transferCap')
;

* --- Reserve Provision Boundaries --------------------------------------------

// Reserve provision limits without investments
// Reserve provision limits based on resXX_range (or possibly available generation in case of unit_flow)
v_reserve.up(nuRescapable(restype, 'up', node, unit), f+df_nReserves(node, restype, f, t), t)${ gnuft('elec', node, unit, f, t)
                                                                                                and not (unit_investLP(unit) or unit_investMIP(unit))
                                                                                                and ord(t) < tSolveFirst + mSettings(mSolve, 't_reserveLength')
                                                                                                }
    = min ( p_nuReserves(node, unit, restype, 'up') * [ p_gnu('elec', node, unit, 'maxGen') + p_gnu('elec', node, unit, 'maxCons') ],  // Generator + consuming unit res_range limit
            v_gen.up('elec', node, unit, f, t) - v_gen.lo('elec', node, unit, f, t) // Generator + consuming unit available unit_elec. output delta
            ) // END min
        * [
            + 1${ft_nReserves(node, restype, f+df_nReserves(node, restype, f, t), t)} // reserveContribution limits the reliability of reserves locked ahead of time.
            + p_nuReserves(node, unit, restype, 'reserveContribution')${not ft_nReserves(node, restype, f+df_nReserves(node, restype, f, t), t)}
            ] // END * min
;
v_reserve.up(nuRescapable(restype, 'down', node, unit), f+df_nReserves(node, restype, f, t), t)${   gnuft('elec', node, unit, f, t)
                                                                                                    and not (unit_investLP(unit) or unit_investMIP(unit))
                                                                                                    and ord(t) < tSolveFirst + mSettings(mSolve, 't_reserveLength')
                                                                                                    }
    = min ( p_nuReserves(node, unit, restype, 'down') * [ p_gnu('elec', node, unit, 'maxGen') + p_gnu('elec', node, unit, 'maxCons') ],  // Generator + consuming unit res_range limit
            v_gen.up('elec', node, unit, f, t) - v_gen.lo('elec', node, unit, f, t) // Generator + consuming unit available unit_elec. output delta
            ) // END min
        * [
            + 1${ft_nReserves(node, restype, f+df_nReserves(node, restype, f, t), t)} // reserveContribution limits the reliability of reserves locked ahead of time.
            + p_nuReserves(node, unit, restype, 'reserveContribution')${not ft_nReserves(node, restype, f+df_nReserves(node, restype, f, t), t)}
            ] // END * min
;

// Fix reserves between t_jump and gate_closure based on previous allocations
loop(restypeDirectionNode(restypeDirection(restype, up_down), node),
    // Fix non-flow unit reserves ahead of time
    v_reserve.fx(nuRescapable(restype, up_down, node, unit), f, t)${    ft_nReserves(node, restype, f, t)
                                                                        and ord(t) >= mSettings(mSolve, 't_start') + p_nReserves(node, restype, 'update_frequency') // Don't lock reserves before the first update
                                                                        and not unit_flow(unit) // NOTE! Units using flows can change their reserve (they might not have as much available in real time as they had bid)
                                                                        }
        = r_reserve(restype, up_down, node, unit, f, t);

    // Fix transfer of reserves ahead of time
    // Rightward
    v_resTransferRightward.fx(restype, up_down, node, node_, f, t)${    ft_nReserves(node, restype, f, t)
                                                                        and restypeDirectionNode(restype, up_down, node_)
                                                                        and ord(t) >= mSettings(mSolve, 't_start') + p_nReserves(node, restype, 'update_frequency') // Don't lock reserves before the first update
                                                                        and sum(grid, gn2n(grid, node, node_))
                                                                        }
        = r_resTransferRightward(restype, up_down, node, node_, f, t);
    // Leftward
    v_resTransferLeftward.fx(restype, up_down, node, node_, f, t)${ ft_nReserves(node, restype, f, t)
                                                                    and restypeDirectionNode(restype, up_down, node_)
                                                                    and ord(t) >= mSettings(mSolve, 't_start') + p_nReserves(node, restype, 'update_frequency') // Don't lock reserves before the first update
                                                                    and sum(grid, gn2n(grid, node, node_))
                                                                    }
        = r_resTransferLeftward(restype, up_down, node, node_, f, t);

    // Free the tertiary reserves for the realization
    v_reserve.fx(nuRescapable('tertiary', up_down, node, unit), ft_realized(f,t))${ nuft(node, unit, f, t) }
        = 0;
    v_resTransferRightward.fx('tertiary', up_down, node, node_, ft_realized(f,t))${ sum(grid, gn2n(grid, node, node_))  }
        = 0;
    v_resTransferLeftward.fx('tertiary', up_down, node, node_, ft_realized(f,t))${  sum(grid, gn2n(grid, node, node_))  }
        = 0;
    ) // END loop(restypeDirectionNode)
;

* --- Investment Variable Boundaries ------------------------------------------

// Unit Investments, Generation
// LP variant
v_invest_LP.up(unit, t_invest)${    unit_investLP(unit) }
    = min(  smax(gnu_output(grid, node, unit), p_gnu(grid, node, unit, 'maxGenCap')) // Maximum permitted gnu_output capacity investment
                / p_unit(unit, 'unitSizeGen')
            ,
            p_unit(unit, 'maxUnitCount')
        ) // END min
;
v_invest_LP.lo(unit, t_invest)${    unit_investLP(unit) }
    = min(  smax(gnu_output(grid, node, unit), p_gnu(grid, node, unit, 'minGenCap')) // Maximum defined gnu_output minimun capacity requirement
                / p_unit(unit, 'unitSizeGen')
            ,
            p_unit(unit, 'minUnitCount')
        ) // END min
;
// MIP variant
v_invest_MIP.up(unit, t_invest)${   unit_investMIP(unit)    }
    = min(  smax(gnu_output(grid, node, unit), p_gnu(grid, node, unit, 'maxGenCap')) // Maximum permitted gnu_output capacity investment
                / p_unit(unit, 'unitSizeGen')
            ,
            p_unit(unit, 'maxUnitCount')
        ) // END min
;
v_invest_MIP.lo(unit, t_invest)${   unit_investMIP(unit)    }
    = min(  smax(gnu_output(grid, node, unit), p_gnu(grid, node, unit, 'minGenCap'))
                / p_unit(unit, 'unitSizeGen')
            ,
            p_unit(unit, 'minUnitCount')
        ) // END min
;

// Unit Investments, Consumption
// LP variant
v_invest_LP.up(unit, t_invest)${    unit_investLP(unit) }
    = min(  smax(gnu_input(grid, node, unit), p_gnu(grid, node, unit, 'maxConsCap')) // Maximum permitted gnu_output capacity investment
                / p_unit(unit, 'unitSizeCons')
            ,
            p_unit(unit, 'maxUnitCount')
        ) // END min
;
v_invest_LP.lo(unit, t_invest)${    unit_investLP(unit) }
    = min(  smax(gnu_input(grid, node, unit), p_gnu(grid, node, unit, 'minConsCap')) // Maximum defined gnu_output minimun capacity requirement
                / p_unit(unit, 'unitSizeCons')
            ,
            p_unit(unit, 'minUnitCount')
        ) // END min
;
// MIP variant
v_invest_MIP.up(unit, t_invest)${   unit_investMIP(unit)    }
    = min(  smax(gnu_input(grid, node, unit), p_gnu(grid, node, unit, 'maxConsCap')) // Maximum permitted gnu_output capacity investment
                / p_unit(unit, 'unitSizeCons')
            ,
            p_unit(unit, 'maxUnitCount')
        ) // END min
;
v_invest_MIP.lo(unit, t_invest)${   unit_investMIP(unit)    }
    = min(  smax(gnu_output(grid, node, unit), p_gnu(grid, node, unit, 'minConsCap'))
                / p_unit(unit, 'unitSizeCons')
            ,
            p_unit(unit, 'minUnitCount')
        ) // END min
;

// Transfer Capacity Investments
// LP investments
v_investTransfer_LP.up(gn2n_directional(grid, from_node, to_node), t_invest)${  not p_gnn(grid, from_node, to_node, 'investMIP')
                                                                                and p_gnn(grid, from_node, to_node, 'transferCapInvLimit')
                                                                                }
    = p_gnn(grid, from_node, to_node, 'transferCapInvLimit')
;
// MIP investments
v_investTransfer_MIP.up(gn2n_directional(grid, from_node, to_node), t_invest)${ p_gnn(grid, from_node, to_node, 'investMIP')
                                                                                and p_gnn(grid, from_node, to_node, 'transferCapInvLimit')
                                                                                }
    = p_gnn(grid, from_node, to_node, 'transferCapInvLimit')
        / p_gnn(grid, from_node, to_node, 'unitSize')
;

// If offline hours after which the start-up will be a warm/cold start is not
// defined, fix hot/warm start-up to zero.
// !!! NOTE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// These should not be necessary,as if the time window is not defined, warm and
// hot starts should be impossible according to q_startuptype
*v_startup.fx(unit, 'hot', ft_dynamic(f, t))${not p_unit(unit, 'startWarm')} = 0;
*v_startup.fx(unit, 'warm', ft_dynamic(f, t))${not p_unit(unit, 'startCold')} = 0;

* =============================================================================
* --- Bounds overwritten for the first timestep -------------------------------
* =============================================================================

// Loop over the start steps
loop(mftStart(mSolve, f, t),
    // First solve, state variables (only if boundStart flag is true)
    v_state.fx(gn_state(grid, node), f, t)${    p_gn(grid, node, 'boundStart')
                                                and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useConstant')
                                                and tSolveFirst = mSettings(mSolve, 't_start')
                                                }
        = p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'constant')
            * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier');

    // Time series form boundary
    v_state.fx(gn_state(grid, node), f, t)${    p_gn(grid, node, 'boundStart')
                                                and p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'useTimeSeries')
                                                and tSolveFirst = mSettings(mSolve, 't_start')
                                                }
        = ts_nodeState_(grid, node, 'reference', f, t)
            * p_gnBoundaryPropertiesForStates(grid, node, 'reference', 'multiplier');
    ) // END loop(mftStart)
;

$ontext
// !!! NOTE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// These should no longer be necessary due to the time indexing changes
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
$offtext

// BoundStartToEnd
v_state.fx(grid, node, ft(f,t))${   mftLastSteps(mSolve, f, t)
                                    and p_gn(grid, node, 'boundStartToEnd')
                                    }
    = sum(fRealization(f_),
        + r_state(grid, node, f_, tSolve+dt(tSolve))
        ) // END sum(fRealization)
;
