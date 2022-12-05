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
* --- Recording realized parameter values -------------------------------------
* =============================================================================

* --- Result arrays required by model dynamics --------------------------------
if(tSolveFirst >= mSettings(mSolve, 't_start') + mSettings(mSolve, 't_initializationPeriod') - mSettings(mSolve, 't_jump')
   and firstResultsOutputSolve,
    loop(msf(mSolve, s, f_solve),
        firstResultsOutputSolve = 0;
        r_state_gnft(gn_state(grid, node), f_solve, t) $[ord(t) = mSettings(mSolve, 't_start') + mSettings(mSolve, 't_initializationPeriod')]
          = v_state.l(grid, node, s, f_solve, t);
        r_online_uft(unit, f_solve, t)$[unit_online(unit) and ord(t) = mSettings(mSolve, 't_start') + mSettings(mSolve, 't_initializationPeriod')]
          = v_online_LP.l(unit, s, f_solve, t)$unit_online_LP(unit)
              + v_online_MIP.l(unit, s, f_solve, t)$unit_online_MIP(unit);
    );
);

// Improve performance & readibility by using a few helper sets
option clear=startp, clear=sft_resdgn, s_realized < sft_realized;
*startp(t)$(ord(t) > mSettings(mSolve, 't_start') + mSettings(mSolve, 't_initializationPeriod'))=yes;
startp(t)
   ${(ord(t) > mSettings(mSolve, 't_start') + mSettings(mSolve, 't_initializationPeriod'))
     and (ord(t) <= mSettings(mSolve, 't_end'))
     and sum((s,f), sft_realized(s, f , t))
     } =yes;

// Realized state history
loop(ms(mSolve, s_realized(s)),
    r_state_gnft(gn_state(grid, node), f, startp(t))$sft_realized(s, f, t)
        = v_state.l(grid, node, s, f, t);

    // Realized state history - initial state values in samples
    r_state_gnft(gn_state(grid, node), f_solve(f), t_(t+dt(t)))$(mst_start(ms, t)$sft_realized(s, f, t)$startp(t))
        = v_state.l(grid, node, s, f, t_)
    ;
    // Realized unit online history
    r_online_uft(uft_online(unit, f, startp(t)))$sft_realized(s, f, t)
        = v_online_LP.l(unit, s, f, t)$uft_onlineLP(unit, f, t)
            + v_online_MIP.l(unit, s, f, t)$uft_onlineMIP(unit, f, t)
    ;
    // Unit startup and shutdown history
    r_startup_uft(unit, starttype, f, startp(t))$(uft_online(unit, f, t)$sft_realized(s, f, t))
        = v_startup_LP.l(unit, starttype, s, f, t)$uft_onlineLP(unit, f, t)
            + v_startup_MIP.l(unit, starttype, s, f, t)$uft_onlineMIP(unit, f, t)
    ;
    r_shutdown_uft(uft_online(unit, f, startp(t)))$sft_realized(s, f, t)
        = v_shutdown_LP.l(unit, s, f, t)$uft_onlineLP(unit, f, t)
            + v_shutdown_MIP.l(unit, s, f, t)$uft_onlineMIP(unit, f, t)
    ;
);

* --- Reserve results ---------------------------------------------------------

// Loop over reserve horizon, as the reserve variables use a different ft-structure due to commitment

sft_resdgn(restypeDirectionGridNode(restype, up_down, gn), sft(s, f, startp(t)))
  ${ord(t) <= tSolveFirst + p_gnReserves(gn, restype, 'reserve_length')} = yes;

loop(s_realized(s),
    // Reserve provisions of units
    r_reserve_gnuft(gnuRescapable(restype, up_down, gn, unit), f_(f+df_reserves(gn, restype, f, t)), t)
        ${ (not sft_realized(s, f_, t)$restypeReleasedForRealization(restype))$sft_resdgn(restype,up_down,gn,s,f,t) }
        = + v_reserve.l(restype, up_down, gn, unit, s, f_, t)
          + sum(restype_$p_gnuRes2Res(gn, unit, restype_, up_down, restype),
              + v_reserve.l(restype_, up_down, gn, unit, s, f+df_reserves(gn, restype_, f, t), t)
                  * p_gnuRes2Res(gn, unit, restype_, up_down, restype)
            );

    // Reserve transfer capacity for links defined out from this node
    r_reserveTransferRightward_gnnft(restype, up_down, gn2n_directional(gn, to_node), f_(f+df_reserves(gn, restype, f, t)), t)
        ${ restypeDirectionGridNodeNode(restype, up_down, gn, to_node)$sft_resdgn(restype,up_down,gn,s,f,t) }
        = v_resTransferRightward.l(restype, up_down, gn, to_node, s, f_, t);

    r_reserveTransferLeftward_gnnft(restype, up_down, gn2n_directional(gn(grid, node), to_node), f_(f+df_reserves(grid, to_node, restype, f, t)), t)
        ${ restypeDirectionGridNodeNode(restype, up_down, grid, to_node, node)$sft_resdgn(restype,up_down,gn,s,f,t) }
        = v_resTransferLeftward.l(restype, up_down, gn, to_node, s, f_, t);

    // Loop over group reserve horizon
    loop((restypeDirectionGroup(restype, up_down, group), sft(s, f, startp(t)))
        ${ord(t) <= tSolveFirst + p_groupReserves(group, restype, 'reserve_length')},

        // Reserve requirement due to N-1 reserve constraint
        r_reserveDemand_largestInfeedUnit_ft(restype, 'up', group, f_(f+df_reservesGroup(group, restype, f, t)), t)
            ${ sum((gnGroup(gn, group),unit_fail)$p_gnuReserves(gn, unit_fail, restype, 'portion_of_infeed_to_reserve'),1) } // Calculate only for groups with units that can fail.
            = smax((gnGroup(gn, group),unit_fail)$p_gnuReserves(gn, unit_fail, restype, 'portion_of_infeed_to_reserve'),
                + v_gen.l(gn, unit_fail, s, f, t)
                    * p_gnuReserves(gn, unit_fail, restype, 'portion_of_infeed_to_reserve')
                ) // END smax(unit_fail)
            ;
        // Dummy reserve demand changes
        r_qReserveDemand_ft(restype, up_down, group, f_(f+df_reservesGroup(group, restype, f, t)), t)
            = vq_resDemand.l(restype, up_down, group, s, f_, t);

        r_qReserveMissing_ft(restype, up_down, group, f_(f+df_reservesGroup(group, restype, f, t)), t)
            = vq_resMissing.l(restype, up_down, group, s, f_, t);

    ); // END loop(restypeDirectionGroup, sft)
); // END loop(s_realized(s)

* --- Interesting results -----------------------------------------------------

loop(s_realized(s),

    // Unit generation and consumption
    r_gen_gnuft(gnu(grid, node, unit), f, startp(t))$sft_realized(s, f, t)
        = v_gen.l(grid, node, unit, s, f, t)
    ;
    // Transfer of energy between nodes
    r_transfer_gnnft(gn2n(grid, from_node, to_node), f, startp(t))$sft_realized(s, f, t)
        = v_transfer.l(grid, from_node, to_node, s, f, t)
    ;
    // Transfer of energy from first node to second node
    r_transferRightward_gnnft(gn2n_directional(grid, from_node, to_node), f, startp(t))$sft_realized(s, f, t)
        = v_transferRightward.l(grid, from_node, to_node, s, f, t)
    ;
    // Transfer of energy from second node to first node
    r_transferLeftward_gnnft(gn2n_directional(grid, to_node, from_node), f, startp(t))$sft_realized(s, f, t)
        = v_transferLeftward.l(grid, to_node, from_node, s, f, t)
    ;
    // Energy spilled from nodes
    r_spill_gnft(gn, f, startp(t))$sft_realized(s, f, t)
        = v_spill.l(gn, s, f, t) * p_stepLength(mSolve, f, t)
    ;
);

// Total Objective function
r_cost_objectiveFunction_t(tSolve)
    = r_cost_objectiveFunction_t(tSolve - mSettings(mSolve, 't_jump')) + v_obj.l
;

loop(s_realized(s),
    // q_balance marginal values
    // Scaling Marginal Values to EUR/MWh from MEUR/MWh
    r_balance_marginalValue_gnft(gn, f, startp(t))$sft_realized(s, f, t)
        = 1e6 * q_balance.m(gn, mSolve, s, f, t)
    ;
    // q_resDemand marginal values
    // Scaling Marginal Values to EUR/MWh from MEUR/MWh
    r_reserve_marginalValue_ft(restypeDirectionGroup(restype, up_down, group), f, startp(t))$sft_realized(s, f, t)
        = 1e6 * q_resDemand.m(restype, up_down, group, s, f, t)
    ;
    // v_stateSlack values for calculation of realized costs later on
    r_stateSlack_gnft(gn_stateSlack(gn), slack, f, startp(t))$sft_realized(s, f, t)
        = v_stateSlack.l(gn, slack, s, f, t)
    ;
);
// Unit investments
r_invest_unitCount_u(unit)${ (unit_investLP(unit) or unit_investMIP(unit))
                  and p_unit(unit, 'becomeAvailable') <= tSolveFirst + mSettings(mSolve, 't_jump')
                  }
    = v_invest_LP.l(unit) + v_invest_MIP.l(unit)
;

// Link investments
r_invest_transferCapacity_gnn(grid, node, node_, t_invest(t))${ p_gnn(grid, node, node_, 'transferCapInvLimit')
*                                                   and t_current(t)
                                                   and ord(t) <= tSolveFirst + mSettings(mSolve, 't_jump')
                                                   }
    = v_investTransfer_LP.l(grid, node, node_, t)
        + v_investTransfer_MIP.l(grid, node, node_, t) * p_gnn(grid, node, node_, 'unitSize')
;

* --- Feasibility results -----------------------------------------------------
loop(sft_realized(s, f, t),
// Dummy generation & consumption
r_qGen_gnft(inc_dec, gn, f, startp(t))
    = vq_gen.l(inc_dec, gn, s, f, t)
;
// Dummy capacity
r_qCapacity_ft(gn, f, startp(t))
    = vq_capacity.l(gn, s, f, t)
;
);

* =============================================================================
* --- Diagnostics Results -----------------------------------------------------
* =============================================================================

// Only include these if '--diag=yes' given as a command line argument
$iftheni.diag %diag% == 'yes'
// Capacity factors for examining forecast errors
d_capacityFactor(flowNode(flow, node), sft(s, f_solve(f), t_current(t)))
    ${  msf(mSolve, s, f)
        and t_active(t)
        and sum(flowUnit(flow, unit), nu(node, unit))
        }
    = ts_cf_(flow, node, s, f, t)
        + ts_cf(flow, node, f, t)${ not ts_cf_(flow, node, s, f, t) }
        + Eps
;
// Node state forecast for examining the error
d_nodeState(gn_BoundaryType_ts(grid, node, param_gnBoundaryTypes), sft(s, f_solve(f), t_current(t)))
    ${  p_gnBoundaryPropertiesForStates(grid, node, param_gnBoundaryTypes, 'useTimeseries')
        and t_active(t)
        and msf(mSolve, s, f)
        }
    = ts_node_(grid, node, param_gnBoundaryTypes, s, f, t)
        + ts_node(grid, node, param_gnBoundaryTypes, f, t)${ not ts_node_(grid, node, param_gnBoundaryTypes, s, f, t)}
        + Eps
;
// Influx forecast for examining the errors
d_influx(gn(grid, node), sft(s, f_solve(f), t_current(t)))
    ${  msf(mSolve, s, f)
        and t_active(t)
        }
    = ts_influx_(grid, node, s, f, t)
        + ts_influx(grid, node, f, t)${ not ts_influx_(grid, node, s, f, t)}
        + Eps
;
$endif.diag

* --- Model Solve & Status ----------------------------------------------------

// Model/solve status
if (mSolve('schedule'),
    r_info_solveStatus(tSolve,'modelStat')=schedule.modelStat;
    r_info_solveStatus(tSolve,'solveStat')=schedule.solveStat;
    r_info_solveStatus(tSolve,'totalTime')=schedule.etSolve;
    r_info_solveStatus(tSolve,'solverTime')=schedule.etSolver;
    r_info_solveStatus(tSolve,'iterations')=schedule.iterUsd;
    r_info_solveStatus(tSolve,'nodes')=schedule.nodUsd;
    r_info_solveStatus(tSolve,'numEqu')=schedule.numEqu;
    r_info_solveStatus(tSolve,'numDVar')=schedule.numDVar;
    r_info_solveStatus(tSolve,'numVar')=schedule.numVar;
    r_info_solveStatus(tSolve,'numNZ')=schedule.numNZ;
    r_info_solveStatus(tSolve,'sumInfes')=schedule.sumInfes;
    r_info_solveStatus(tSolve,'objEst')=schedule.objEst;
    r_info_solveStatus(tSolve,'objVal')=schedule.objVal;
);
if (mSolve('invest'),
    r_info_solveStatus(tSolve,'modelStat')=invest.modelStat;
    r_info_solveStatus(tSolve,'solveStat')=invest.solveStat;
    r_info_solveStatus(tSolve,'totalTime')=invest.etSolve;
    r_info_solveStatus(tSolve,'solverTime')=invest.etSolver;
    r_info_solveStatus(tSolve,'iterations')=invest.iterUsd;
    r_info_solveStatus(tSolve,'nodes')=invest.nodUsd;
    r_info_solveStatus(tSolve,'numEqu')=invest.numEqu;
    r_info_solveStatus(tSolve,'numDVar')=invest.numDVar;
    r_info_solveStatus(tSolve,'numVar')=invest.numVar;
    r_info_solveStatus(tSolve,'numNZ')=invest.numNZ;
    r_info_solveStatus(tSolve,'sumInfes')=invest.sumInfes;
    r_info_solveStatus(tSolve,'objEst')=invest.objEst;
    r_info_solveStatus(tSolve,'objVal')=invest.objVal;
);



