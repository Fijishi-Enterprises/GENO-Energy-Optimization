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

* compare to emission cap constraint, 2d_constraints.gms ll. 2783 ff - only use emissions from inputs there
* does including penalites in obj fct change solution although with and without, no dummy generation etc. happens


q_obj ..

    + v_obj                                                                    // Emissions (t)

    =E=

    // Sum over all the samples, forecasts, and time steps in the current model
    
    + sum(msft(m, s, f, t),
        // Probability (weight coefficient) of (s,f,t)
        + p_msft_probability(m, s, f, t)
            * [
                // Time step length dependent costs 
                + p_stepLength(m, f, t)                                         // length of time interval (h)
                    * [

                       // emissions from inputs
                        - sum(gnuft(grid, node, unit, f, t)$gnu_input(grid, node, unit),  // include second condition "and  p_nEmission(node, emission)" for top level sums (ll. 42,55,77)?
                            + v_gen(grid, node, unit, s, f, t)                  // energy generation in interval (MW)
                                *
                                        sum(emission,
                                              p_nEmission(node, emission)       // emission content (kg/MWh)
                                                  / 1e3                         // Conversion to t/MWh from kg/MWh in data
                                          ) // END sum(emission)
                              ) // END sum(gnuft)



                        // emission from outputs
                        + sum(gnuft(grid, node, unit, f, t)$gnu_output(grid, node, unit),
                            + v_gen(grid, node, unit, s, f, t)
                                *
                                        sum(emission,
                                            +  p_nEmission(node, emission)
                                                  / 1e3                         // Conversion to t/MWh from kg/MWh in data
                                        ) // END sum(emission)
                            ) // END sum(gnuft)

                        + 1e6 *                                                 // increase penalty terms by factor of 1e6
                              (
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
                              ) 

                        ] // END * p_stepLength


                // Start-up emissions, initial startup free as units could have been online before model started
                + sum(uft_online(unit, f, t),
                    + sum(unitStarttype(unit, starttype),
                        + [ // Unit startup variables                           // units started up during/after interval (p.u.)
                            + v_startup_LP(unit, starttype, s, f, t)${ uft_onlineLP(unit, f, t) }
                            + v_startup_MIP(unit, starttype, s, f, t)${ uft_onlineMIP(unit, f, t) }
                          ]
                          *
                              sum((nu(node, unit), emission),
                                + p_unStartup(unit, node, starttype)            // MWh/start-up
                                  *  p_nEmission(node, emission)                // emission content (kg/MWh)
                                                  / 1e3                         // Conversion to t/MWh from kg/MWh in data
                              )                                                 // END sum(nu, emission)
                      )                                                         // END sum(starttype)
                  )                                                             // END sum(uft_online)
                  


                ]                                                               // END * p_msft_probability(m,s,f,t)
        )                                                                       // END sum over msft(m, s, f, t)


$ifthen.addterms exist '%input_dir%/2c_additional_objective_terms.gms'
    $$include '%input_dir%/2c_additional_objective_terms.gms';
$endif.addterms


;
