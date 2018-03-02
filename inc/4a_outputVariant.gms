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
// !!! NOTE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// Have to go through my RealValue branch changes to the result arrays for
// More thought-out result arrays

* --- Result arrays required by model dynamics --------------------------------

// Realized state history
r_state(gn_state(grid, node), ft_realized(f, t))
    = v_state.l(grid, node, f, t)
;
// Realized unit online history
r_online(uft_online(unit, ft_realized(f, t)))
    = v_online_LP.l(unit, f, t)${ uft_onlineLP(unit, f, t)    }
        + v_online_MIP.l(unit, f, t)${  uft_onlineMIP(unit, f, t)   }
;
// Reserve provisions of units
r_reserve(nuRescapable(restype, up_down, node, unit), f_solve(f), t_active(t))${    mft_nReserves(node, restype, mSolve, f, t)
                                                                                    or sum(f_, df_nReserves(node, restype, f_, t))
                                                                                    }
    = v_reserve.l(restype, up_down, node, unit, f, t)
;
// Reserve transfer capacity
r_resTransferRightward(restypeDirectionNode(restype, up_down, from_node), to_node, f_solve(f), t_active(t))${   restypeDirectionNode(restype, up_down, to_node)
                                                                                                                and [   mft_nReserves(from_node, restype, mSolve, f, t)
                                                                                                                    or sum(f_, df_nReserves(from_node, restype, f_, t))
                                                                                                                    ]
                                                                                                                }
    = v_resTransferRightward.l(restype, up_down, from_node, to_node, f, t)
;
r_resTransferLeftward(restypeDirectionNode(restype, up_down, from_node), to_node, f_solve(f), t_active(t))${    restypeDirectionNode(restype, up_down, to_node)
                                                                                                                and [   mft_nReserves(from_node, restype, mSolve, f, t)
                                                                                                                    or sum(f_, df_nReserves(from_node, restype, f_, t))
                                                                                                                    ]
                                                                                                                }
    = v_resTransferLeftward.l(restype, up_down, from_node, to_node, f, t)
;
// Unit startup and shutdown history
r_startup(unit, starttype, ft_realized(f, t))${ uft_online(unit, f, t)  }
    = v_startup.l(unit, starttype, f, t)
;
r_shutdown(uft_online(unit, ft_realized(f, t)))
    = v_shutdown.l(unit, f, t)
;

* --- Interesting results -----------------------------------------------------

// Unit generation and consumption
r_gen(gnuft(grid, node, unit, ft_realized(f, t)))
    = v_gen.l(grid, node, unit, f, t)
;
// Fuel use of units
r_fuelUse(fuel, uft(unit_fuel, ft_realized(f, t)))
    = v_fuelUse.l(fuel, unit_fuel, f, t)
;
// Transfer of energy between nodes
r_transfer(gn2n(grid, from_node, to_node), ft_realized(f, t))
    = v_transfer.l(grid, from_node, to_node, f, t)
;
// Energy spilled from nodes
r_spill(gn(grid, node), ft_realized(f, t))
    = v_spill.l(grid, node, f, t)
;
// Total Objective function
r_totalObj
    = r_totalObj + v_obj.l
;
// q_balance marginal values
r_balanceMarginal(gn(grid, node), ft_realized(f, t))
    = q_balance.m(grid, node, mSolve, f, t)
;
// q_resDemand marginal values
r_resDemandMarginal(restypeDirectionNode(restype, up_down, node), ft_realized(f, t))
    = q_resDemand.m(restype, up_down, node, f, t)
;
// v_stateSlack values for calculation of realized costs later on
r_stateSlack(gn_stateSlack(grid, node), slack, ft_realized(f, t))
    = v_stateSlack.l(grid, node, slack, f, t)
;

* --- Feasibility results -----------------------------------------------------

// Dummy generation & consumption
r_qGen(inc_dec, gn(grid, node), f_solve(f), t_active(t))
    = vq_gen.l(inc_dec, grid, node, f, t)
;
// Dummy reserve demand changes
r_qResDemand(restypeDirectionNode(restype, up_down, node), f_solve(f), t_active(t))
    = vq_resDemand.l(restype, up_down, node, f, t)
;

* --- Diagnostics Results -----------------------------------------------------

$iftheni.diag NOT '%diag%' == 'no'
// Capacity factors for examining forecast errors
d_capacityFactor(flowNode(flow, node), f_solve(f), t_active(t))${ sum(flowUnit(flow, unit), nu(node, unit)) }
    = ts_cf_(flow, node, f, t)
        + ts_cf(flow, node, f, t)${ not ts_cf_(flow, node, f, t) }
        - 1e-3${    not ts_cf_(flow, node, f, t)
                    and not ts_cf(flow, node, f, t)
                    }
;
// Temperature forecast for examining the error
d_nodeState(gn_stateTimeseries(grid, node), param_gnBoundaryTypes, f_solve(f), t_active(t))${ p_gnBoundaryPropertiesForStates(grid, node, param_gnBoundaryTypes, 'useTimeseries') }
    = ts_nodeState_(grid, node, param_gnBoundaryTypes, f, t)
        + ts_nodeState(grid, node, param_gnBoundaryTypes, f, t)${ not ts_nodeState_(grid, node, param_gnBoundaryTypes, f, t) }
        - 1e-3${    not ts_nodeState_(grid, node, param_gnBoundaryTypes, f, t)
                    and not ts_nodeState_(grid, node, param_gnBoundaryTypes, f, t)
                    }
;
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



