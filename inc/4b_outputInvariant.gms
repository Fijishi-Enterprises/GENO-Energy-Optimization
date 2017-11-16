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

* --- Calculate total results -------------------------------------------------

// Need to loop over the model dimension, as this file is no longer contained in the modelSolves loop...
loop(m,
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

    // Total reserve provisions over the simulation
    r_nuTotalReserve(nuRescapable(restype, up_down, node, unit))
        = sum(ft_realizedNoReset(f, t),
            + r_reserve(restype, up_down, node, unit, f, t)
                * p_stepLengthNoReset(m, f, t)
            ); // END sum(ft_realizedNoReset)

    // Total sub-unit-hours for units over the simulation
    r_uTotalOnline(unit)
        = sum(ft_realizedNoReset(f, t),
            + r_online(unit, f, t)
                * p_stepLengthNoReset(m, f, t)
            ); // END sum(ft_realizedNoReset)

    // Approximate utilization rates for gnus over the simulation
    r_gnuUtilizationRate(gnu_output(grid, node, unit))
        = r_gnuTotalGen(grid, node, unit)
            / [
                + p_gnu(grid, node, unit, 'maxGen')
                    * (mSettings(m, 't_end') - mSettings(m, 't_start') + 1)
                    * mSettings(m, 'intervalInHours')
                ]; // END division

); // END loop(m)

// Total generation in gn
r_gnTotalGen(gn(grid, node))
    = sum(gnu_output(grid, node, unit), r_gnuTotalGen(grid, node, unit)); // END sum(gnu_output)
// Total generation in g
r_gTotalGen(grid)
    = sum(gn(grid, node), r_gnTotalGen(grid, node));

// Total consumption on each gn over the simulation
r_gnTotalConsumption(gn(grid, node))
    = sum(ft_realizedNoReset(f, t), r_gnConsumption(grid, node, f ,t));
// Total consumption in each grid over the simulation
r_gTotalConsumption(grid)
    = sum(gn(grid, node), r_gnTotalConsumption(grid, node));

// Total fuel consumption in grids over the simulation
r_gTotalGenFuel(grid, fuel)
    = sum(gn(grid, node), r_gnTotalGenFuel(grid, node, fuel));
// Total fuel consumption over the simulation
r_totalGenFuel(fuel)
    = sum(gn(grid, node), r_gnTotalGenFuel(grid, node, fuel));

// Total spilled energy in each grid over the simulation
r_gTotalSpill(grid)
    = sum(gn(grid, node_spill(node)), r_gnTotalSpill(grid, node));

// Total realized costs on each gn over the simulation
r_gnTotalRealizedCost(gn(grid, node))
    = sum(ft_realizedNoReset(f, t), r_gnRealizedCost(grid, node, f ,t));
// Total realized costs on each grid over the simulation
r_gTotalRealizedCost(grid)
    = sum(gn(grid, node), r_gnTotalRealizedCost(grid, node));
// Total realized costs over the simulation
r_totalRealizedCost
    = sum(gn(grid, node), r_gnTotalRealizedCost(grid, node));

// Total reserve provision in nodes over the simulation
r_nTotalReserve(restypeDirectionNode(restype, up_down, node))
    = sum(nuRescapable(restype, up_down, node, unit), r_nuTotalReserve(restype, up_down, node, unit));

// Total unit online hours per sub-unit over the simulation
r_uTotalOnlinePerUnit(unit)
    = r_uTotalOnline(unit)
        / p_unit(unit, 'unitCount');


