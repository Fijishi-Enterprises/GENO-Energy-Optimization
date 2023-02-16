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


equations
          q_tempDiff
          q_tempDiff_plus
          q_tempDiff_minus
          q_tempDiff_plusMinus
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

