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

Free Variables
          v_tempDiff(grid, node, s, f, t);

Positive Variables
          v_tempDiff_plus(grid, node, s, f, t)
          v_tempDiff_minus(grid, node, s, f, t);
          
Binary Variable
          v_slack(s, f, t);

Scalar
          maxTotalEmission
          maxTotalDiscomfort;

$If set maxTotalEmission maxTotalEmission=%maxTotalEmission%;
$If not set maxTotalEmission maxTotalEmission = inf;

$If set maxTotalDiscomfort maxTotalDiscomfort=%maxTotalDiscomfort%;
$If not set maxTotalDiscomfort maxTotalDiscomfort = inf;


equations
          q_totalDiscomfort
          q_tempDiff
          q_tempDiff_plus
          q_tempDiff_minus
          q_tempDiff_plusMinus
          q_totalEmission
;

q_tempDiff(grid, node, s, f, t)${ gnGroup(grid, node, 'objectiveGroup') and sft(s,f,t)
        } ..

 v_tempDiff(grid, node, s, f, t) =E=
          (
           + p_gnBoundaryPropertiesForStates(grid, node, 'm_set', 'constant')${p_gnBoundaryPropertiesForStates(grid, node, 'm_set', 'useConstant')}
           + ts_node(grid, node, 'm_set', f, t)${p_gnBoundaryPropertiesForStates(grid, node, 'm_set', 'useTimeseries')}
          )
          *
          (
           v_state(grid, node, s, f, t) 
           - p_gnBoundaryPropertiesForStates(grid, node, 'T_set', 'constant')${p_gnBoundaryPropertiesForStates(grid, node, 'T_set', 'useConstant')}
           - ts_node(grid, node, 'T_set', f, t)${p_gnBoundaryPropertiesForStates(grid, node, 'T_set', 'useTimeseries')}
          )          
;



q_tempDiff_plusMinus(grid, node, s, f, t)${ gnGroup(grid, node, 'objectiveGroup') and sft(s,f,t)
        } ..
 
 v_tempDiff(grid, node, s, f, t) =E= v_tempDiff_plus(grid, node, s, f, t) - v_tempDiff_minus(grid, node, s, f, t);
 

q_tempDiff_plus(grid, node, s, f, t)${ gnGroup(grid, node, 'objectiveGroup') and sft(s,f,t)
        } ..

 v_tempDiff_plus(grid, node, s, f, t) =L= v_slack(s, f, t) * 
            (
            + p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'constant')${p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'useConstant')}
            + ts_node(grid, node, 'upwardLimit', f, t)${p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'useTimeseries')}
            )
            * p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'multiplier') ; 

q_tempDiff_minus(grid, node, s, f, t)${ gnGroup(grid, node, 'objectiveGroup') and sft(s,f,t)
        } ..
        
  v_tempDiff_minus(grid, node, s, f, t) =L= ( 1 - v_slack(s, f, t) ) * 
            (
            + p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'constant')${p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'useConstant')}
            + ts_node(grid, node, 'upwardLimit', f, t)${p_gnBoundaryPropertiesForStates(grid, node, 'upwardLimit', 'useTimeseries')}
            )
            * p_gnBoundaryPropertiesForStates(grid, node,   'upwardLimit', 'multiplier') ;

* discomfort constraint equation
* gnGroup = 'objectiveGroup' hard-coded
q_totalDiscomfort ..

 maxTotalDiscomfort
 
 =E=
 
 + v_epsSlack2 

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
                    
                      ] // end * p_stepLength

             ] // end * p_msft_profitability
       ) // end sum(msft)
;

* emission constraint equation
* emission = 'CO2' and gnGroup = 'emission group' hard-coded
q_totalEmission ..

 maxTotalEmission
 
 =E=

 + v_epsSlack1

    + sum(msft(m, s, f, t),
        + p_msft_Probability(m,s,f,t)
        * [
            // Time step length dependent emissions - calculated from consumption
            + p_stepLength(m, f, t)
                * sum(gnu_input(grid, node, unit)${gnGroup(grid, node, 'emission group') and p_nEmission(node, 'CO2')},
                    - v_gen(grid, node, unit, s, f, t) // multiply by -1 because consumption is negative
                        * p_nEmission(node, 'CO2') // kg/MWh
                        / 1e3 // NOTE!!! Conversion to t/MWh from kg/MWh in data
                  ) // END sum(gnu_input)

            // Start-up emissions
            + sum((uft_online(unit, f, t), starttype)$[unitStarttype(unit, starttype) and p_uStartup(unit, starttype, 'consumption')],
                + [
                    + v_startup_LP(unit, starttype, s, f, t)
                        ${ uft_onlineLP(unit, f, t) }
                    + v_startup_MIP(unit, starttype, s, f, t)
                        ${ uft_onlineMIP(unit, f, t) }
                  ]
                * sum(nu(node, unit)${p_nEmission(node, 'CO2')},
                    + p_unStartup(unit, node, starttype) // MWh/start-up
                        * p_nEmission(node, 'CO2') // kg/MWh
                        / 1e3 // NOTE!!! Conversion to t/MWh from kg/MWh in data
                    ) // END sum(nu, emission)
              ) // sum(uft_online)
          ] // END * p_sft_Probability
      ) // END sum(msft))
;