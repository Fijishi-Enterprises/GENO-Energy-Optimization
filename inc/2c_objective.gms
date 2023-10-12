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
                        // O&M costs (gnu), fuel prices (gn), LCA emission costs (gnuEmissions, vomEmissions), fuel emission costs (gnEmission)
                        // see 3c_inputsloop for details
                        + sum(gnusft(grid, node, unit, s, f, t)${ p_vomCost(grid, node, unit, 'useConstant') or p_vomCost(grid, node, unit, 'useTimeSeries') },
                            + v_gen(grid, node, unit, s, f, t)
                                * (+p_vomCost(grid, node, unit, 'price')$p_vomCost(grid, node, unit, 'useConstant')
                                   +ts_vomCost_(grid, node, unit, t)$p_vomCost(grid, node, unit, 'useTimeSeries')
                                  )
                                // negative sign for input, because v_gen is negative for input
                                * (-1$gnu_input(grid, node, unit)
                                   +1$gnu_output(grid, node, unit)
                                  )
                            ) // END sum(gnusft)

                        // Ramping costs (eur/MW) * ramp (MW/h) * stepLength (h) = ramp cost (eur)
                        + sum(gnusft_rampCost(slack, grid, node, unit, s, f, t)$p_gnuBoundaryProperties(grid, node, unit, slack, 'rampCost'),
                            + p_gnuBoundaryProperties(grid, node, unit, slack, 'rampCost')
                                * v_genRampUpDown(slack, grid, node, unit, s, f, t)
                          ) // END sum(gnusft_rampCost)

                        // Variable Transfer cost
                        + sum(gn2n_directional(grid, node_, node)$p_gnn(grid, node, node_, 'variableTransCost'),
                              + p_gnn(grid, node, node_, 'variableTransCost')
                              * v_transferLeftward(grid, node_, node, s, f, t)
                          ) // END sum(gn2n_directional(grid, node_, node))

                        + sum(gn2n_directional(grid, node_, node)$p_gnn(grid, node_, node, 'variableTransCost'),
                              + p_gnn(grid, node_, node, 'variableTransCost')
                              * v_transferRightward(grid, node_, node, s, f, t)
                          ) // END sum(gn2n_directional(grid, node_, node))

                        // Node state slack variable costs
                        + sum(gn_stateSlack(grid, node),
                            + sum(slack${p_gnBoundaryPropertiesForStates(grid, node, slack, 'slackCost')},
                                + v_stateSlack(slack, grid, node, s, f, t)
                                    * p_gnBoundaryPropertiesForStates(grid, node, slack, 'slackCost')
                                ) // END sum(slack)
                            ) // END sum(gn_stateSlack)

                        // Dummy variable penalties
                        // Energy balance feasibility dummy varible penalties
                        + sum(inc_dec,
                            + sum(gn(grid, node)${p_gn(grid, node, 'nodeBalance')},
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
                + sum(usft_online(unit_startCost(unit), s, f, t),
                    + sum(unitStarttype(unit, starttype)
                        ${p_startupCost(unit, starttype, 'useConstant')
                          or ts_startupCost_(unit, starttype, t)
                          },
                        + [ // Unit startup variables
                            + v_startup_LP(starttype, unit, s, f, t)${ usft_onlineLP(unit, s, f, t) }
                            + v_startup_MIP(starttype, unit, s, f, t)${ usft_onlineMIP(unit, s, f, t) }
                          ]
                          * (+p_startupCost(unit, starttype, 'price')${ p_startupCost(unit, starttype, 'useConstant') }
                             +ts_startupCost_(unit, starttype, t)${ p_startupCost(unit, starttype, 'useTimeSeries') }
                            )
                      ) // END sum(starttype)
                  ) // END sum(usft_online)

                // Shut-down costs, initial shutdown free?
                + sum(usft_online(unit, s, f, t)$p_uShutdown(unit, 'cost'),
                    + p_uShutdown(unit, 'cost')
                      * [
                            + v_shutdown_LP(unit, s, f, t)${ usft_onlineLP(unit, s, f, t) }
                            + v_shutdown_MIP(unit, s, f, t)${ usft_onlineMIP(unit, s, f, t) }
                        ]
                  ) // END sum(usft_online)

              ]  // END * p_msft_probability(m, s, f, t)
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

    // Fixed maintenance costs of existing units and investment costs of new units and transfer links.
    // Direct costs and emission costs.
    + sum(ms(m, s)${ sum(msft(m, s, f, t), 1) }, // consider ms only if it has active msft
        + p_msAnnuityWeight(m, s) // Sample weighting to calculate annual costs
            * p_s_discountFactor(s) // Discount costs
            * [
                // unit fixed o&m and investment costs (EUR)
                + sum(gnu(grid, node, unit)${sum(msft(m, s, f, t_), usft(unit, s, f, t_))   // consider unit only if it is active in the sample
                                             and (p_gnu(grid, node, unit, 'fomCosts')   // and it has fomCost or invCost parameter defined
                                                  or p_gnu(grid, node, unit, 'invCosts'))
                                            },
                    // Fixed operation and maintenance costs of existing units (EUR)
                    // includes existing capacity even if unit has v_invest variable
                    + p_gnu(grid, node, unit, 'unitSize')   // (MW/unit)
                        * p_unit(unit, 'unitCount')         // number of units
                        * p_gnu(grid, node, unit, 'fomCosts')    // (EUR/MW/a)
                    // Unit investment costs and fixed operation and maintenance costs of new units (EUR)
                    + v_invest_LP(unit)${ unit_investLP(unit) } // number of units
                        * p_gnu(grid, node, unit, 'unitSize')   // (MW/unit)
                        * [
                            + p_gnu(grid, node, unit, 'invCosts') * p_gnu(grid, node, unit, 'annuityFactor')  // (EUR/MW) * annualizationFactor
                            + p_gnu(grid, node, unit, 'fomCosts')  // (EUR/MW)
                          ]
                    + v_invest_MIP(unit)${ unit_investMIP(unit) }  // number of units
                        * p_gnu(grid, node, unit, 'unitSize')      // (MW/unit)
                        * [
                            + p_gnu(grid, node, unit, 'invCosts') * p_gnu(grid, node, unit, 'annuityFactor')  // (EUR/MW) * annualizationFactor
                            + p_gnu(grid, node, unit, 'fomCosts')  // (EUR/MW)
                          ]
                    ) // END sum(gnu)

                // capacity emission costs: fixed o&M emissions and investment emissions (EUR)
                // note: calculated from p_emissionPrice if exists or from the average of ts_emissionPrice
                + sum((gnu(grid, node, unit),emissionGroup(emission, group))
                       ${p_gnuEmission(grid, node, unit, emission, 'fomEmissions')
                         and gnGroup(grid, node, group)
                         and sum(msft(m, s, f, t_), usft(unit, s, f, t_))
                         and (p_emissionPrice(emission, group, 'useConstant') or p_emissionPrice(emission, group, 'useTimeseries'))
                         },
                    + p_gnuEmission(grid, node, unit, emission, 'fomEmissions')       // (tEmissions/MW)
                        * p_gnu(grid, node, unit, 'unitSize')   // (MW/unit)
                        * [
                            // Existing capacity
                            + p_unit(unit, 'unitCount')         // (number of existing units)

                            // Investments to new capacity
                            + v_invest_LP(unit)${unit_investLP(unit)}        // (number of invested units)
                            + v_invest_MIP(unit)${unit_investMIP(unit)}      // (number of invested units)
                          ]
                        * [ + p_emissionPrice(emission, group, 'price')$p_emissionPrice(emission, group, 'useConstant')
                            + (sum(t_realized(t), ts_emissionPrice(emission, group, t))/card(t_realized))$p_emissionPrice(emission, group, 'useTimeSeries')
                          ]// END * p_gnuEmssion
                    ) // END sum(gnu)

                // capacity emissions cost: investment emissions (EUR)
                // note: calculated from p_emissionPrice if exists or from the average of ts_emissionPrice
                + sum((gnu(grid, node, unit),emissionGroup(emission, group))
                       ${p_gnuEmission(grid, node, unit, emission, 'invEmissions')
                         and (unit_investLP(unit) or unit_investMIP(unit))
                         and gnGroup(grid, node, group)
                         and sum(msft(m, s, f, t_), usft(unit, s, f, t_))
                         and (p_emissionPrice(emission, group, 'useConstant') or p_emissionPrice(emission, group, 'useTimeseries'))
                         },
                    // Capacity restriction
                    + p_gnuEmission(grid, node, unit, emission, 'invEmissions')    // (tEmission/MW)
                        * p_gnuEmission(grid, node, unit, emission, 'invEmissionsFactor')    // factor dividing emissions to N years
                        * p_gnu(grid, node, unit, 'unitSize')     // (MW/unit)
                        * [
                            // Investments to new capacity
                            + v_invest_LP(unit)${unit_investLP(unit)}         // (number of invested units)
                            + v_invest_MIP(unit)${unit_investMIP(unit)}       // (number of invested units)
                          ]
                        * [ + p_emissionPrice(emission, group, 'price')$p_emissionPrice(emission, group, 'useConstant')
                            + (sum(t_realized(t), ts_emissionPrice(emission, group, t))/card(t_realized))$p_emissionPrice(emission, group, 'useTimeSeries')
                          ]// END * p_gnuEmssion
                    ) // END sum(gnu)

                + sum(t_invest(t)${ord(t) <= msEnd(m, s)},
                    // Transfer link investment costs
                    + sum(gn2n_directional(grid, from_node, to_node),
                        + v_investTransfer_LP(grid, from_node, to_node, t)${ gn2n_directional_investLP(grid, from_node, to_node) }
                            * [
                                + p_gnn(grid, from_node, to_node, 'invCost')
                                    * p_gnn(grid, from_node, to_node, 'annuityFactor')
                                + p_gnn(grid, to_node, from_node, 'invCost')
                                    * p_gnn(grid, to_node, from_node, 'annuityFactor')
                                ] // END * v_investTransfer_LP
                        + v_investTransfer_MIP(grid, from_node, to_node, t)${ gn2n_directional_investMIP(grid, from_node, to_node) }
                            * [
                                + p_gnn(grid, from_node, to_node, 'unitSize')
                                    * p_gnn(grid, from_node, to_node, 'invCost')
                                    * p_gnn(grid, from_node, to_node, 'annuityFactor')
                                + p_gnn(grid, to_node, from_node, 'unitSize')
                                    * p_gnn(grid, to_node, from_node, 'invCost')
                                    * p_gnn(grid, to_node, from_node, 'annuityFactor')
                                ] // END * v_investTransfer_MIP
                        ) // END sum(gn2n_directional)
                    ) // END sum(t_invest)

                ] // END * p_s_discountFactor(s)

        ) // END sum(ms)

$ifthen.addterms exist '%input_dir%/2c_additional_objective_terms.gms'
    $$include '%input_dir%/2c_additional_objective_terms.gms';
$endif.addterms
;
