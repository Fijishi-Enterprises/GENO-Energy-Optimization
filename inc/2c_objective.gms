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
* --- Objective Function Definition -------------------------------------------
* =============================================================================

q_obj ..

    + v_obj * 1e6 // Objective function valued in MEUR instead of EUR (or whatever monetary unit the data is in)

    =E=

    // Sum over all the samples, forecasts, and time steps in the current model
    + sum(msft(m, s, f, t),
        // Probability (weight coefficient) of (s,f,t)
        + p_msft_probability(m, s, f, t)
            * [
                // Time step length dependent costs
                + p_stepLength(m, f, t)
                    * [
                        // Variable O&M costs
                        + sum(gnuft(gnu_output(grid, node, unit), f, t),  // Calculated only for output energy
                            + v_gen(grid, node, unit, s, f, t)
                                * p_unit(unit, 'omCosts')
                            ) // END sum(gnu_output)

                        // Fuel and emission costs
                        + sum(uFuel(unit, 'main', fuel)${uft(unit, f, t)},
                            + v_fuelUse(fuel, unit, s, f, t)
                                * [
                                    + p_fuelPrice(fuel, 'fuelPrice')${ p_fuelPrice(fuel, 'useConstant') }
                                    + ts_fuelPrice_(fuel ,t)${ p_fuelPrice(fuel, 'useTimeSeries') }
                                    + sum(emission, // Emission taxes
                                        + p_unitFuelEmissionCost(unit, fuel, emission)
                                        )
                                    ] // END * v_fuelUse
                            ) // END sum(uFuel)

                        // Node state slack variable costs
                        + sum(gn_stateSlack(grid, node),
                            + sum(slack${p_gnBoundaryPropertiesForStates(grid, node, slack, 'slackCost')},
                                + v_stateSlack(grid, node, slack, s, f, t)
                                    * p_gnBoundaryPropertiesForStates(grid, node, slack, 'slackCost')
                                ) // END sum(slack)
                            ) // END sum(gn_stateSlack)

                        // Dummy variable penalties
                        // Energy balance feasibility dummy varible penalties
                        + sum(inc_dec,
                            + sum(gn(grid, node),
                                + vq_gen(inc_dec, grid, node, s, f, t)
                                    *( PENALTY_BALANCE(grid, node)${not p_gnBoundaryPropertiesForStates(grid, node, 'balancePenalty', 'useTimeSeries')}
                                    + ts_node(grid, node, 'balancePenalty', f, t)${p_gnBoundaryPropertiesForStates(grid, node, 'balancePenalty', 'useTimeSeries')}
                                      )
                                ) // END sum(gn)
                            ) // END sum(inc_dec)

                        // Reserve provision feasibility dummy variable penalties
                        + sum(restypeDirectionNode(restype, up_down, node),
                            + vq_resDemand(restype, up_down, node, s, f+df_reserves(node, restype, f, t), t)
                                * PENALTY_RES(restype, up_down)
                            + vq_resMissing(restype, up_down, node, s, f+df_reserves(node, restype, f, t), t)${ ft_reservesFixed(node, restype, f+df_reserves(node, restype, f, t), t) }
                                * PENALTY_RES_MISSING(restype, up_down)
                            ) // END sum(restypeDirectionNode)

                        // Capacity margin feasibility dummy variable penalties
                        + sum(gn(grid, node),
                            + vq_capacity(grid, node, s, f, t)
                                * PENALTY_CAPACITY(grid, node)
                            ) // END sum(gn)
                        ] // END * p_stepLength

                // Start-up costs, initial startup free as units could have been online before model started
                + sum(uft_online(unit, f, t),
                    + sum(unitStarttype(unit, starttype),
                        + v_startup(unit, starttype, s, f, t) // Cost of starting up
                            * [ // Startup variable costs
                                + p_uStartup(unit, starttype, 'cost')

                                // Start-up fuel and emission costs
                                + sum(uFuel(unit, 'startup', fuel),
                                    + p_uStartup(unit, starttype, 'consumption')
                                        * p_uFuel(unit, 'startup', fuel, 'fixedFuelFraction')
                                        * [
                                            + p_fuelPrice(fuel, 'fuelPrice')${ p_fuelPrice(fuel, 'useConstant') }
                                            + ts_fuelPrice_(fuel, t)${ p_fuelPrice(fuel, 'useTimeseries') }
                                            + sum(emission, // Emission taxes of startup fuel use
                                                + p_unitFuelEmissionCost(unit, fuel, emission)
                                              ) // END sum(emission)
                                          ] // END * p_uStartup
                                  ) // END sum(uFuel)
                              ] // END * v_startup
                      ) // END sum(starttype)
                  ) // END sum(uft_online)

                // Shut-down costs, initial shutdown free?
                + sum(uft_online(unit, f, t),
                      + v_shutdown(unit, s, f, t) * p_uShutdown(unit, 'cost')
                  ) // END sum(uft_online)

                // Ramping costs
                + sum(gnuft_rampCost(grid, node, unit, slack, f, t),
                    + p_gnuBoundaryProperties(grid, node, unit, slack, 'rampCost')
                        * v_genRampUpDown(grid, node, unit, slack, s, f, t)
                  ) // END sum(gnuft_rampCost)

                ]  // END * p_sft_probability(s,f,t)

        ) // END sum over msft(m, s, f, t)

    // Cost of energy storage change
    + sum(gn_state(grid, node),
        + sum(mft_start(m, f, t)${  p_storageValue(grid, node, t)
                                    and active(m, 'storageValue')
                                    },
            + p_storageValue(grid, node, t)
                * sum(ms(m, s)${ p_msft_probability(m, s, f, t) },
                    + p_msft_probability(m, s, f, t)
                      * v_state(grid, node, s, f+df_central(f,t), t)
                    ) // END sum(s)
            ) // END sum(mftStart)
        - sum(mft_lastSteps(m, f, t)${  p_storageValue(grid, node, t)
                                        and active(m, 'storageValue')
                                        },
            + p_storageValue(grid, node, t)
                * sum(ms(m, s)${p_msft_probability(m, s, f, t)},
                    + p_msft_probability(m, s, f, t)
                      * v_state(grid, node, s, f+df_central(f,t), t)
                    ) // END sum(s)
            ) // END sum(mftLastSteps)
        ) // END sum(gn_state)

    // Investment Costs
    + sum(t_invest(t),

        // Unit investment costs (including fixed operation and maintenance costs)
        + sum(gnu(grid, node, unit),
            + v_invest_LP(unit, t)${ unit_investLP(unit) }
                * p_gnu(grid, node, unit, 'unitSizeTot')
                * [
                    + p_gnu(grid, node, unit, 'invCosts') * p_gnu(grid, node, unit, 'annuity')
                    + p_gnu(grid, node, unit, 'fomCosts')
                  ]
            + v_invest_MIP(unit, t)${ unit_investMIP(unit) }
                * p_gnu(grid, node, unit, 'unitSizeTot')
                * [
                    + p_gnu(grid, node, unit, 'invCosts') * p_gnu(grid, node, unit, 'annuity')
                    + p_gnu(grid, node, unit, 'fomCosts')
                  ]
            ) // END sum(gnu)

        // Transfer link investment costs
        + sum(gn2n_directional(grid, from_node, to_node),
            + v_investTransfer_LP(grid, from_node, to_node, t)${ gn2n_directional_investLP(grid, from_node, to_node) }
                * [
                    + p_gnn(grid, from_node, to_node, 'invCost')
                        * p_gnn(grid, from_node, to_node, 'annuity')
                    + p_gnn(grid, to_node, from_node, 'invCost')
                        * p_gnn(grid, to_node, from_node, 'annuity')
                    ] // END * v_investTransfer_LP
            + v_investTransfer_MIP(grid, from_node, to_node, t)${ gn2n_directional_investMIP(grid, from_node, to_node) }
                * [
                    + p_gnn(grid, from_node, to_node, 'unitSize')
                        * p_gnn(grid, from_node, to_node, 'invCost')
                        * p_gnn(grid, from_node, to_node, 'annuity')
                    + p_gnn(grid, to_node, from_node, 'unitSize')
                        * p_gnn(grid, to_node, from_node, 'invCost')
                        * p_gnn(grid, to_node, from_node, 'annuity')
                    ] // END * v_investTransfer_MIP
            ) // END sum(gn2n_directional)
        ) // END sum(t_invest)

$ifthen.addterms exist '%input_dir%/2c_additional_objective_terms.gms'
    $$include '%input_dir%/2c_additional_objective_terms.gms';
$endif.addterms
;
