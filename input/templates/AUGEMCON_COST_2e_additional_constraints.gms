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


*==============================================================================
* --- Additional Constraints --------------------------------------------------
*==============================================================================

* --- Declarations ------------------------------------------------------------

* scalar/parameter definitions should be in 1c_parameters.gms
* equation declaration should be in 2b_eqDeclarations.gms


scalars
          maxTotalCost "Upper limit on total operating costs (MEUR)"
;

$If set maxTotalCost maxTotalCost=%maxTotalCost%;
$If not set maxTotalCost maxTotalCost = inf;


equations
          q_TotalCost "total operating costs (EUR)"
;


* --- Constraints -------------------------------------------------------------

* upper limit on total operating costs, copied from "standard" objective function
* added FOM cost of non-investable units

* OPEN QUESTION
* should we use probabilities and weights here?
* should they be included in emission objective?

q_TotalCost ..


 maxTotalCost * 1e6           // change from EUR to MEUR

 =E=
 
    + v_epsSlack

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

                       ]
                // Start-up costs, initial startup free as units could have been online before model started
                + sum(uft_online(unit, f, t),
                    + sum(unitStarttype(unit, starttype),
                        + [ // Unit startup variables
                            + v_startup_LP(unit, starttype, s, f, t)${ uft_onlineLP(unit, f, t) }
                            + v_startup_MIP(unit, starttype, s, f, t)${ uft_onlineMIP(unit, f, t) }
                          ]
                          * ts_startupCost_(unit, starttype, t)
                      ) // END sum(starttype)
                  ) // END sum(uft_online)

                // Shut-down costs, initial shutdown free?
                + sum(uft_online(unit, f, t),
                    + p_uShutdown(unit, 'cost')
                      * [
                            + v_shutdown_LP(unit, s, f, t)
                                ${ uft_onlineLP(unit, f, t) }
                            + v_shutdown_MIP(unit, s, f, t)
                                ${ uft_onlineMIP(unit, f, t) }
                        ]
                  ) // END sum(uft_online)

                // Ramping costs
                + sum(gnuft_rampCost(grid, node, unit, slack, f, t),
                    + p_gnuBoundaryProperties(grid, node, unit, slack, 'rampCost')
                        * v_genRampUpDown(grid, node, unit, slack, s, f, t)
                  ) // END sum(gnuft_rampCost)

                ]  // END * p_sft_probability(s,f,t) * p_discountFactor

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
* JF: added FOM cost of already installed / not investable units
                    + p_gnu(grid, node, unit, 'capacity')${not unit_investLP(unit) and not unit_investMIP(unit) and sum(msft(m, s, f, t_), uft(unit, f, t_))}
                        * p_gnu(grid, node, unit, 'fomCosts')
                        
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

;