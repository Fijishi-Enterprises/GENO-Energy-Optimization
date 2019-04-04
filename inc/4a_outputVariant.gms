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
        r_state(gn_state(grid, node), f_solve, t) $[ord(t) = mSettings(mSolve, 't_start') + mSettings(mSolve, 't_initializationPeriod')]
          = v_state.l(grid, node, s, f_solve, t);
        r_online(unit, f_solve, t)$[unit_online(unit) and ord(t) = mSettings(mSolve, 't_start') + mSettings(mSolve, 't_initializationPeriod')]
          = v_online_LP.l(unit, s, f_solve, t)$unit_online_LP(unit)
              + v_online_MIP.l(unit, s, f_solve, t)$unit_online_MIP(unit);
    );
);
// Realized state history
loop(sft_realized(s, f, t),
    r_state(gn_state(grid, node), f, t)$[ord(t) > mSettings(mSolve, 't_start') + mSettings(mSolve, 't_initializationPeriod')]
        = v_state.l(grid, node, s, f, t);

    // Realized state history - initial state values in samples
    r_state(gn_state(grid, node), f_solve(f), t+dt(t))${   ord(t) > mSettings(mSolve, 't_start') + mSettings(mSolve, 't_initializationPeriod')
                                                           and sum(ms(mSolve, s), mst_start(mSolve, s, t))
                                                       }
        = v_state.l(grid, node, s, f, t+dt(t))
    ;
    // Realized unit online history
    r_online(uft_online(unit, f, t))$[ord(t) > mSettings(mSolve, 't_start') + mSettings(mSolve, 't_initializationPeriod')]
        = v_online_LP.l(unit, s, f, t)${ uft_onlineLP(unit, f, t)    }
            + v_online_MIP.l(unit, s, f, t)${  uft_onlineMIP(unit, f, t)   }
    ;
    // Unit startup and shutdown history
    r_startup(unit, starttype, f, t)${ uft_online(unit, f, t) and [ord(t) > mSettings(mSolve, 't_start') + mSettings(mSolve, 't_initializationPeriod')] }
        = v_startup_LP.l(unit, starttype, s, f, t)${ uft_onlineLP(unit, f, t) }
            + v_startup_MIP.l(unit, starttype, s, f, t)${ uft_onlineMIP(unit, f, t) }
    ;
    r_shutdown(uft_online(unit, f, t))$[ord(t) > mSettings(mSolve, 't_start') + mSettings(mSolve, 't_initializationPeriod')]
        = v_shutdown.l(unit, s, f, t)
    ;
);

* --- Reserve results ---------------------------------------------------------

// Loop over reserve horizon, as the reserve variables use a different ft-structure due to commitment
loop((restypeDirectionNode(restype, up_down, node), sft(s, f, t))
    ${  ord(t) <= tSolveFirst + p_nReserves(node, restype, 'reserve_length')
        and ord(t) > mSettings(mSolve, 't_start') + mSettings(mSolve, 't_initializationPeriod')
        },

    // Reserve provisions of units
    r_reserve(nuRescapable(restype, up_down, node, unit), f+df_reserves(node, restype, f, t), t)
        ${  not [   restypeReleasedForRealization(restype)
                    and sft_realized(s, f+df_reserves(node, restype, f, t), t)
                    ]
            }
        = + v_reserve.l(restype, up_down, node, unit, s, f+df_reserves(node, restype, f, t), t)
          + sum(restype_$p_nuRes2Res(node, unit, restype_, up_down, restype),
              + v_reserve.l(restype_, up_down, node, unit, s, f+df_reserves(node, restype_, f, t), t)
                  * p_nuRes2Res(node, unit, restype_, up_down, restype)
            );

    // Reserve requirement due to N-1 reserve constraint
    r_resDemandLargestInfeedUnit(grid, f+df_reserves(node, restype, f, t), t, restype, up_down, node)
        ${ sum(unit_fail, nuRescapable(restype, up_down, node, unit_fail)) } // Calculate only for nodes with units that can fail.
        = smax(unit_fail(unit_), v_gen.l(grid, node, unit_, s, f, t) * p_nuReserves(node, unit_, restype, 'portion_of_infeed_to_reserve'));

    // Reserve transfer capacity for links defined out from this node
    r_resTransferRightward(restype, up_down, node, to_node, f+df_reserves(node, restype, f, t), t)
        ${  sum(grid, gn2n_directional(grid, node, to_node))
            and restypeDirectionNodeNode(restype, up_down, node, to_node)
            }
        = v_resTransferRightward.l(restype, up_down, node, to_node, s, f+df_reserves(node, restype, f, t), t);

    r_resTransferLeftward(restype, up_down, node, to_node, f+df_reserves(to_node, restype, f, t), t)
        ${  sum(grid, gn2n_directional(grid, node, to_node))
            and restypeDirectionNodeNode(restype, up_down, to_node, node)
            }
        = v_resTransferLeftward.l(restype, up_down, node, to_node, s, f+df_reserves(to_node, restype, f, t), t);

    // Dummy reserve demand changes
    r_qResDemand(restype, up_down, node, f+df_reserves(node, restype, f, t), t)
        = vq_resDemand.l(restype, up_down, node, s, f+df_reserves(node, restype, f, t), t);

    r_qResMissing(restype, up_down, node, f+df_reserves(node, restype, f, t), t)
        = vq_resMissing.l(restype, up_down, node, s, f+df_reserves(node, restype, f, t), t);

); // END loop(restypeDirectionNode, sft)

* --- Interesting results -----------------------------------------------------

loop(sft_realized(s, f, t),
    // Unit generation and consumption
    r_gen(gnuft(grid, node, unit, f, t))$[ord(t) > mSettings(mSolve, 't_start') + mSettings(mSolve, 't_initializationPeriod')]
        = v_gen.l(grid, node, unit, s, f, t)
    ;
    // Fuel use of units
    r_fuelUse(fuel, uft(unit_fuel, f, t))$[ord(t) > mSettings(mSolve, 't_start') + mSettings(mSolve, 't_initializationPeriod')]
        = v_fuelUse.l(fuel, unit_fuel, s, f, t)
    ;
    // Transfer of energy between nodes
    r_transfer(gn2n(grid, from_node, to_node), f, t)$[ord(t) > mSettings(mSolve, 't_start') + mSettings(mSolve, 't_initializationPeriod')]
        = v_transfer.l(grid, from_node, to_node, s, f, t)
    ;
    // Energy spilled from nodes
    r_spill(gn(grid, node), f, t)$[ord(t) > mSettings(mSolve, 't_start') + mSettings(mSolve, 't_initializationPeriod')]
        = v_spill.l(grid, node, s, f, t)
    ;
);

// Total Objective function
r_totalObj(tSolve)
    = r_totalObj(tSolve - mSettings(mSolve, 't_jump')) + v_obj.l
;

// q_balance marginal values
loop(sft_realized(s, f, t),
    r_balanceMarginal(gn(grid, node), f, t)$[ord(t) > mSettings(mSolve, 't_start') + mSettings(mSolve, 't_initializationPeriod')]
        = q_balance.m(grid, node, mSolve, s, f, t)
    ;
    // q_resDemand marginal values
    r_resDemandMarginal(restypeDirectionNode(restype, up_down, node), f, t)$[ord(t) > mSettings(mSolve, 't_start') + mSettings(mSolve, 't_initializationPeriod')]
        = q_resDemand.m(restype, up_down, node, s, f, t)
    ;
    // v_stateSlack values for calculation of realized costs later on
    r_stateSlack(gn_stateSlack(grid, node), slack, f, t)$[ord(t) > mSettings(mSolve, 't_start') + mSettings(mSolve, 't_initializationPeriod')]
        = v_stateSlack.l(grid, node, slack, s, f, t)
    ;
);
// Unit investments
r_invest(unit)${unit_investLP(unit) or unit_investMIP(unit)}
    = sum(t_invest, v_invest_LP.l(unit, t_invest) + v_invest_MIP.l(unit, t_invest))
;
// Link investments
r_investTransfer(grid, node, node_, t_invest(t))${ p_gnn(grid, node, node_, 'transferCapInvLimit')
*                                                   and t_current(t)
                                                   and ord(t) <= tSolveFirst + mSettings(mSolve, 't_jump')
                                                   }
    = v_investTransfer_LP.l(grid, node, node_, t)
        + v_investTransfer_MIP.l(grid, node, node_, t) * p_gnn(grid, node, node_, 'unitSize')
;

* --- Feasibility results -----------------------------------------------------
loop(sft_realized(s, f, t),
// Dummy generation & consumption
r_qGen(inc_dec, gn(grid, node), f, t)
    ${  ord(t) > mSettings(mSolve, 't_start') + mSettings(mSolve, 't_initializationPeriod')
        }
    = vq_gen.l(inc_dec, grid, node, s, f, t)
;
// Dummy capacity
r_qCapacity(gn(grid, node), f, t)
    ${  ord(t) > mSettings(mSolve, 't_start') + mSettings(mSolve, 't_initializationPeriod')
        }
    = vq_capacity.l(grid, node, s, f, t)
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
    = ts_cf_(flow, node, f, t, s)
        + ts_cf(flow, node, f, t + dt_scenarioOffset(flow, node, 'ts_cf', s))${ not ts_cf_(flow, node, f, t, s) }
        + Eps
;
// Temperature forecast for examining the error
d_nodeState(gn_state(grid, node), param_gnBoundaryTypes, sft(s, f_solve(f), t_current(t)))
    ${  p_gnBoundaryPropertiesForStates(grid, node, param_gnBoundaryTypes, 'useTimeseries')
        and t_active(t)
        and msf(mSolve, s, f)
        }
    = ts_node_(grid, node, param_gnBoundaryTypes, f, t, s)
        + ts_node(grid, node, param_gnBoundaryTypes, f, t)${ not ts_node_(grid, node, param_gnBoundaryTypes, f, t, s)}
        + Eps
;
// Influx forecast for examining the errors
d_influx(gn(grid, node), sft(s, f_solve(f), t_current(t)))
    ${  msf(mSolve, s, f)
        and t_active(t)
        }
    = ts_influx_(grid, node, f, t, s)
        + ts_influx(grid, node, f, t)${ not ts_influx_(grid, node, f, t, s)}
        + Eps
;
// Scenario values for time series
Options clear = d_state, clear = d_ts_scenarios; // Only keep latest results
loop(s_scenario(s, scenario),
    loop(mft_start(mSolve, f, t)$ms_initial(mSolve, s),
        d_state(gn_state(grid, node), scenario, f, t) = v_state.l(grid, node, s, f, t);
    );
    d_state(gn_state, scenario, ft)$sft(s, ft) = v_state.l(gn_state, s, ft) + eps;
    d_ts_scenarios('ts_influx', gn, scenario, ft)$sft(s, ft) = ts_influx_(gn, ft, s) + eps;
    d_ts_scenarios('ts_cf', flowNode, scenario, ft)$sft(s, ft) = ts_cf_(flowNode, ft, s) + eps;
);
$endif.diag

* --- Model Solve & Status ----------------------------------------------------

// Model/solve status
if (mSolve('schedule'),
    r_solveStatus(tSolve,'modelStat')=schedule.modelStat;
    r_solveStatus(tSolve,'solveStat')=schedule.solveStat;
    r_solveStatus(tSolve,'totalTime')=schedule.etSolve;
    r_solveStatus(tSolve,'iterations')=schedule.iterUsd;
    r_solveStatus(tSolve,'nodes')=schedule.nodUsd;
    r_solveStatus(tSolve,'numEqu')=schedule.numEqu;
    r_solveStatus(tSolve,'numDVar')=schedule.numDVar;
    r_solveStatus(tSolve,'numVar')=schedule.numVar;
    r_solveStatus(tSolve,'numNZ')=schedule.numNZ;
    r_solveStatus(tSolve,'sumInfes')=schedule.sumInfes;
    r_solveStatus(tSolve,'objEst')=schedule.objEst;
    r_solveStatus(tSolve,'objVal')=schedule.objVal;
);
if (mSolve('invest'),
    r_solveStatus(tSolve,'modelStat')=invest.modelStat;
    r_solveStatus(tSolve,'solveStat')=invest.solveStat;
    r_solveStatus(tSolve,'totalTime')=invest.etSolve;
    r_solveStatus(tSolve,'iterations')=invest.iterUsd;
    r_solveStatus(tSolve,'nodes')=invest.nodUsd;
    r_solveStatus(tSolve,'numEqu')=invest.numEqu;
    r_solveStatus(tSolve,'numDVar')=invest.numDVar;
    r_solveStatus(tSolve,'numVar')=invest.numVar;
    r_solveStatus(tSolve,'numNZ')=invest.numNZ;
    r_solveStatus(tSolve,'sumInfes')=invest.sumInfes;
    r_solveStatus(tSolve,'objEst')=invest.objEst;
    r_solveStatus(tSolve,'objVal')=invest.objVal;
);



