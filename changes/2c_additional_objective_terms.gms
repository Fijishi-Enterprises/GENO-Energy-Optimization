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
* --- Additions to Objective Function -------------------------------------------
* =============================================================================

    // Transfer link variable costs/ direct transfer costs
    + sum(msft(m, s, f, t),
        // Probability (weight coefficient) of (s,f,t)
        + p_msft_probability(m, s, f, t)
            * [
                // Time step length dependent costs
                + p_stepLength(m, f, t)
                    * [
                         + sum(gn2n_directional(grid, from_node, to_node),
                                 + v_transfer(grid, from_node, to_node, s, f, t)
                                 * [+ p_gnn(grid, from_node, to_node, 'transferCost')]
                           ) // END sum(gn2n_directional)
                ] // END * p_stepLength
          ]  // END * p_sft_probability(s,f,t)
      ) // END sum over msft(m, s, f, t)

;
