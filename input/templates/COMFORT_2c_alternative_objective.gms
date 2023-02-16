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

Free Variables
          v_tempDiff(grid, node, s, f, t);

Positive Variables
          v_tempDiff_plus(grid, node, s, f, t)
          v_tempDiff_minus(grid, node, s, f, t);
          
Binary Variable
          v_slack(s, f, t);

q_obj ..

    + v_obj                                                                    

    =E=

    // Sum over all the samples, forecasts, and time steps in the current model
    
    + sum(msft(m, s, f, t),
        // Probability (weight coefficient) of (s,f,t)
        + p_msft_probability(m, s, f, t)
            * [
                // Time step length dependent costs 
                + p_stepLength(m, f, t)                                         // length of time interval (h)
                    * [

                                // sum over differences from set temperature
                                + sum(gn_state(grid, node)$gnGroup(grid, node, 'objectiveGroup'),
                                    + v_tempDiff_plus(grid, node, s, f, t)
                                    + v_tempDiff_minus(grid, node, s, f, t)
                                    + p_gnBoundaryPropertiesForStates(grid, node, 'discomfort_offset', 'constant')${p_gnBoundaryPropertiesForStates(grid, node, 'discomfort_offset', 'useConstant')}
                                    ) // END sum(gn_state)

                        +
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
            

                ]                                                               // END * p_msft_probability(m,s,f,t)
        )                                                                       // END sum over msft(m, s, f, t)


$ifthen.addterms exist '%input_dir%/2c_additional_objective_terms.gms'
    $$include '%input_dir%/2c_additional_objective_terms.gms';
$endif.addterms


;
