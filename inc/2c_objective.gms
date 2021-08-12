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
            * p_s_discountFactor(s) // Discount costs
            * [
                // Time step length dependent costs
                + p_stepLength(m, f, t)
                    * [
                        // Variable O&M costs for inputs
                        - sum(gnuft(grid, node, unit, f, t)$gnu_input(grid, node, unit),
                            + v_gen(grid, node, unit, s, f, t)
                                * ts_vomCost_(grid, node, unit, t)
                            ) // END sum(gnuft)

                        // Variable O&M costs
                        + sum(gnuft(grid, node, unit, f, t)$gnu_output(grid, node, unit),
                            + v_gen(grid, node, unit, s, f, t)
                                * ts_vomCost_(grid, node, unit, t)
                            ) // END sum(gnuft)

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
                                    + ts_node_(grid, node, 'balancePenalty', s, f, t)${p_gnBoundaryPropertiesForStates(grid, node, 'balancePenalty', 'useTimeSeries')}
                                      )
                                ) // END sum(gn)
                            ) // END sum(inc_dec)

                        // Reserve provision feasibility dummy variable penalties
                        + sum(restypeDirectionGroup(restype, up_down, group),
                            + vq_resDemand(restype, up_down, group, s, f+df_reservesGroup(group, restype, f, t), t)
                                * PENALTY_RES(restype, up_down)
                            + vq_resMissing(restype, up_down, group, s, f+df_reservesGroup(group, restype, f, t), t)${ ft_reservesFixed(group, restype, f+df_reservesGroup(group, restype, f, t), t) }
                                * PENALTY_RES_MISSING(restype, up_down)
                            ) // END sum(restypeDirectionNode)

                        // Capacity margin feasibility dummy variable penalties
                        + sum(gn(grid, node)${ p_gn(grid, node, 'capacityMargin') },
                            + vq_capacity(grid, node, s, f, t)
                                * PENALTY_CAPACITY(grid, node)
                            ) // END sum(gn)
                        ] // END * p_stepLength

                // Start-up costs, initial startup free as units could have been online before model started
                + sum(uft_online(unit, f, t),
                    + sum(unitStarttype(unit, starttype)$ts_startupCost_(unit, starttype, t),
                        + [ // Unit startup variables
                            + v_startup_LP(unit, starttype, s, f, t)${ uft_onlineLP(unit, f, t) }
                            + v_startup_MIP(unit, starttype, s, f, t)${ uft_onlineMIP(unit, f, t) }
                          ]
                          * ts_startupCost_(unit, starttype, t)
                      ) // END sum(starttype)
                  ) // END sum(uft_online)

                // Shut-down costs, initial shutdown free?
                + sum(uft_online(unit, f, t)$p_uShutdown(unit, 'cost'),
                    + p_uShutdown(unit, 'cost')
                      * [
                            + v_shutdown_LP(unit, s, f, t)
                                ${ uft_onlineLP(unit, f, t) }
                            + v_shutdown_MIP(unit, s, f, t)
                                ${ uft_onlineMIP(unit, f, t) }
                        ]
                  ) // END sum(uft_online)

                // Ramping costs
                + sum(gnuft_rampCost(grid, node, unit, slack, f, t)$p_gnuBoundaryProperties(grid, node, unit, slack, 'rampCost'),
                    + p_gnuBoundaryProperties(grid, node, unit, slack, 'rampCost')
                        * v_genRampUpDown(grid, node, unit, slack, s, f, t)
                  ) // END sum(gnuft_rampCost)

                ]  // END * p_sft_probability(s,f,t)

                // Variable Transfer
                + sum(gn2n_directional(grid, node_, node)$p_gnn(grid, node, node_, 'variableTransCost'),
                    + p_gnn(grid, node, node_, 'variableTransCost')
                    * v_transferLeftward(grid, node_, node, s, f, t)
                  ) // END sum(gn2n_directional(grid, node_, node))

                + sum(gn2n_directional(grid, node_, node)$p_gnn(grid, node_, node, 'variableTransCost'),
                    + p_gnn(grid, node_, node, 'variableTransCost')
                    * v_transferRightward(grid, node_, node, s, f, t)
                  ) // END sum(gn2n_directional(grid, node_, node))

        ) // END sum over msft(m, s, f, t)

    // Cost of energy storage change (note: not discounted)
    + sum(gn_state(grid, node),
        + sum(mft_start(m, f, t)${ active(m, 'storageValue') },
            + sum(ms(m, s)${ p_msft_probability(m, s, f, t) },
                + [
                    + p_storageValue(grid, node)${ not p_gn(grid, node, 'storageValueUseTimeSeries') }
                    + ts_storageValue_(grid, node, s, f+df_central(f,t), t)${ p_gn(grid, node, 'storageValueUseTimeSeries') }
                  ]
                    * p_msft_probability(m, s, f, t)
                    * v_state(grid, node, s, f+df_central(f,t), t)
               ) // END sum(s)
            ) // END sum(mftStart)
        - sum(mft_lastSteps(m, f, t)${ active(m, 'storageValue') },
            + sum(ms(m, s)${p_msft_probability(m, s, f, t)},
                + [
                    + p_storageValue(grid, node)${ not p_gn(grid, node, 'storageValueUseTimeSeries') }
                    + ts_storageValue_(grid, node, s, f+df_central(f,t), t)${ p_gn(grid, node, 'storageValueUseTimeSeries') }
                  ]
                    * p_msft_probability(m, s, f, t)
                    * v_state(grid, node, s, f+df_central(f,t), t)
                ) // END sum(s)
            ) // END sum(mftLastSteps)
        ) // END sum(gn_state)

    // Investment Costs
    + sum(ms(m, s)${ sum(msft(m, s, f, t), 1) }, // consider ms only if it has active msft
        + p_msAnnuityWeight(m, s) // Sample weighting to calculate annual costs
            * p_s_discountFactor(s) // Discount costs
            * [
                // Unit investment costs (including fixed operation and maintenance costs)
                + sum(gnu(grid, node, unit),
                    + v_invest_LP(unit)${ unit_investLP(unit) and sum(msft(m, s, f, t_), uft(unit, f, t_))} // consider unit only if it is active in the sample
                        * p_gnu(grid, node, unit, 'unitSize')
                        * [
                            + p_gnu(grid, node, unit, 'invCosts') * p_gnu(grid, node, unit, 'annuity')
                            + p_gnu(grid, node, unit, 'fomCosts')
                          ]
                    + v_invest_MIP(unit)${ unit_investMIP(unit) and sum(msft(m, s, f, t_), uft(unit, f, t_))} // consider unit only if it is active in the sample
                        * p_gnu(grid, node, unit, 'unitSize')
                        * [
                            + p_gnu(grid, node, unit, 'invCosts') * p_gnu(grid, node, unit, 'annuity')
                            + p_gnu(grid, node, unit, 'fomCosts')
                          ]
                    ) // END sum(gnu)

                + sum(t_invest(t)${ord(t) <= msEnd(m, s)},
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

                ] // END * p_s_discountFactor(s)

        ) // END sum(ms)

$ifthen.addterms exist '%input_dir%/2c_additional_objective_terms.gms'
    $$include '%input_dir%/2c_additional_objective_terms.gms';
$endif.addterms
;
