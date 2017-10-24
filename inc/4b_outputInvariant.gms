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
* --- Time independent results ------------------------------------------------
* =============================================================================

* --- Calculate time series results based on realized values ------------------

r_gnConsumption(gn(grid, node), ft_realizedNoReset(f, t))
    = min(ts_influx(grid, node, f, t), 0) // Not necessarily a good idea, as ts_influx contains energy gains as well...
        + sum(gnu_input(grid, node, unit),
            + r_gen(grid, node, unit, f, t)
            ) // END sum(gnu_input)
;

* --- Calculate totals for nodes ----------------------------------------------

loop(m, // Need to loop over the model dimension, as this file is no longer contained in the modelSolves loop...
    // Total generation on each node
    r_gnuTotalGen(gnu_output(grid, node, unit))
        = sum(ft_realizedNoReset(f, t),
            + r_gen(grid, node, unit, f, t)
                * p_stepLengthNoReset(m, f, t)
            ); // END sum(ft_realizedNoReset)
    // Total generation on each node by fuels
    r_gnTotalGenFuel(gn(grid, node), fuel)
        = sum(ft_realizedNoReset(f, t),
            + r_genFuel(grid, node, fuel, f, t)
                * p_stepLengthNoReset(m, f, t)
            ); // END sum(ft_realizedNoReset)
    // Total transfer of energy between nodes
    r_gnnTotalTransfer(gn2n(grid, from_node, to_node))
        = sum(ft_realizedNoReset(f, t),
            + r_transfer(grid, from_node, to_node, f, t)
                * p_stepLengthNoReset(m, f, t)
            ); // END sum(ft_realizedNoReset)
    // Total energy spill from nodes
    r_gnTotalSpill(grid, node_spill(node))
        = sum(ft_realizedNoReset(f, t),
            + r_spill(grid, node, f, t)
                * p_stepLengthNoReset(m, f, t)
            ); // END sum(ft_realizedNoReset)
); // END loop(m)

* --- Calculate system totals -------------------------------------------------

// Total consumption on each gn over the simulation
r_gnTotalConsumption(gn(grid, node))
    = sum(ft_realizedNoReset(f, t),
        + r_gnConsumption(grid, node, f ,t)
        ); // END sum(ft_realizedNoReset)

// Total fuel consumption over the simulation
r_totalGenFuel(fuel)
    = sum(gn(grid, node),
        + r_gnTotalGenFuel(grid, node, fuel)
        ); // END sum(gn)

// Total realized costs on each gn
r_gnTotalRealizedCost(gn(grid, node))
    = sum(ft_realizedNoReset(f, t),
        + r_gnRealizedCost(grid, node, f ,t)
        ); // END sum(ft_realizedNoReset)

// Total realized costs over the simulation
r_totalRealizedCost
    = sum(gn(grid, node),
        + r_gnTotalRealizedCost(grid, node)
        ); // END sum(gn)

