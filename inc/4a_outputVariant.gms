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
r_reserve(nuRescapable(restype, up_down, node, unit), fSolve(f), tActive(t))${  mft_nReserves(node, restype, mSolve, f, t)
                                                                                or sum(f_, df_nReserves(node, restype, f_, t))
                                                                                }
    = v_reserve.l(restype, up_down, node, unit, f, t)
;
// Reserve transfer capacity
r_resTransferRightward(restypeDirectionNode(restype, up_down, from_node), to_node, fSolve(f), tActive(t))${ restypeDirectionNode(restype, up_down, to_node)
                                                                                                            and [   mft_nReserves(from_node, restype, mSolve, f, t)
                                                                                                                or sum(f_, df_nReserves(from_node, restype, f_, t))
                                                                                                                ]
                                                                                                            }
    = v_resTransferRightward.l(restype, up_down, from_node, to_node, f, t)
;
r_resTransferLeftward(restypeDirectionNode(restype, up_down, from_node), to_node, fSolve(f), tActive(t))${  restypeDirectionNode(restype, up_down, to_node)
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
// Last realized timestep
*r_realizedLast = tRealizedLast;

* --- Interesting results -----------------------------------------------------

// Unit generation and consumption
r_gen(gnuft(grid, node, unit, ft_realized(f, t)))
    = v_gen.l(grid, node, unit, f, t)
;
// Fuel use of units
r_fuelUse(fuel, uft(unit_fuel, ft_realized(f, t)))
    = v_fuelUse.l(fuel, unit_fuel, f, t)
;
// Fuel used for generation
r_genFuel(gn(grid, node), fuel, ft_realized(f, t))
    = sum(gnu(grid, node, unit), v_fuelUse.l(fuel, unit, f, t))
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

* --- Realized system costs ---------------------------------------------------

r_gnRealizedCost(gn(grid, node), ft_realized(f, t))
    // Time step length dependent costs
    = 1e-6 // Scaling to MEUR
        * [
            // Time step length dependent costs
            + p_stepLength(mSolve, f, t)
                * [
                    // Variable O&M costs
                    + sum(gnuft(gnu_output(grid, node, unit), f, t),  // Calculated only for output energy
                        + v_gen.l(grid, node, unit, f, t)
                            * p_unit(unit, 'omCosts')
                        ) // END sum(gnu_output)

                    // Fuel and emission costs
                    + sum(uFuel(unit, 'main', fuel)${ gnuft(grid, node, unit, f, t) },
                        + v_fuelUse.l(fuel, unit, f, t)
                            * [
                                + ts_fuelPrice(fuel, t)
                                + sum(emission, // Emission taxes
                                    + p_unitFuelEmissionCost(unit, fuel, emission)
                                    ) // END sum(emission)
                                ] // END * v_fuelUse
                        ) // END sum(uFuel)

                    // Node state slack variable penalties
                    + sum(gn_stateSlack(grid, node),
                        + sum(slack${p_gnBoundaryPropertiesForStates(grid, node, slack, 'slackCost')},
                            + v_stateSlack.l(grid, node, slack, f, t)
                                * p_gnBoundaryPropertiesForStates(grid, node, slack, 'slackCost')
                            ) // END sum(slack)
                        ) // END sum(gn_stateSlack)

                    ] // END * p_stepLength

            // Start-up costs
            + sum(gnuft(grid, node, unit, f, t)${ uft_online(unit, f, t) },
                + sum(starttype,
                    + v_startup.l(unit, starttype, f, t) // Cost of starting up
                        * [ // Startup variable costs
                            + p_uStartup(unit, starttype, 'cost', 'unit')

                            // Start-up fuel and emission costs
                            + sum(uFuel(unit, 'startup', fuel),
                                + p_uStartup(unit, starttype, 'consumption', 'unit')${not unit_investLP(unit)}
                                    * [
                                        + ts_fuelPrice(fuel, t)
                                        + sum(emission, // Emission taxes of startup fuel use
                                            + p_unitFuelEmissionCost(unit, fuel, emission)
                                            ) // END sum(emission)
                                        ] // END * p_uStartup
                                ) // END sum(uFuel)
                            ] // END * v_startup
                    ) // END sum(starttype)
                ) // END sum(gnuft)
            ] // END * 1e-6
;

* --- Feasibility results -----------------------------------------------------

// Dummy generation & consumption
r_qGen(inc_dec, gn(grid, node), ft_realized(f, t))
    = vq_gen.l(inc_dec, grid, node, f, t)
;
// Dummy reserve demand changes
r_qResDemand(restypeDirectionNode(restype, up_down, node), ft_realized(f, t))
    = vq_resDemand.l(restype, up_down, node, f, t)
;

* --- Diagnostics Results -----------------------------------------------------

d_cop(uft(unit, ft_realized(f, t)))${sum(gnu_input(grid, node, unit), 1)}
    = sum(gnu_output(grid, node, unit),
        + r_gen(grid, node, unit, f, t)
        ) // END sum(gnu_output)
        / [ sum(gnu_input(grid_, node_, unit),
                -r_gen(grid_, node_, unit, f, t)
                ) // END sum(gnu_input)
            + 1${not sum(gnu_input(grid_, node_, unit), -r_gen(grid_, node_, unit, f, t))}
            ]
;
d_eff(uft(unit_fuel, ft_realized(f, t)))
    = sum(gnu_output(grid, node, unit_fuel),
        + r_gen(grid, node, unit_fuel, f, t)
        ) // END sum(gnu_output)
        / [ sum(uFuel(unit_fuel, param_fuel, fuel),
                + r_fuelUse(fuel, unit_fuel, f, t)
                ) // END sum(uFuel)
            + 1${not sum(uFuel(unit_fuel, param_fuel, fuel), r_fuelUse(fuel, unit_fuel, f, t))}
            ]
;
d_capacityFactor(flow, node, fSolve(f), tActive(t))${ sum(flowUnit(flow, unit), nu(node, unit)) }
    = ts_cf_(flow, node, f, t)
        + ts_cf(flow, node, f, t)${ not ts_cf_(flow, node, f, t) }
        - 1e-3${ not ts_cf_(flow, node, f, t) and not ts_cf(flow, node, f, t) }

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



