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

* --- Calculate time step length dependent results ----------------------------

// Need to loop over the model dimension, as this file is no longer contained in the modelSolves loop...
loop(m,
    // Realized energy consumption !!! NOTE !!! This is a bit of an approximation at the moment
    r_gnConsumption(gn(grid, node), ft_realizedNoReset(f, t))
        = p_stepLengthNoReset(m, f, t)
            * [
                + min(ts_influx(grid, node, f, t), 0) // Not necessarily a good idea, as ts_influx contains energy gains as well...
                + sum(gnu_input(grid, node, unit),
                    + r_gen(grid, node, unit, f, t)
                    ) // END sum(gnu_input)
                ];

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

    // Total dummy generation/consumption
    r_gnTotalqGen(inc_dec, gn(grid, node))
        = sum(ft_realizedNoReset(f,t),
            + r_qGen(inc_dec, grid, node, f, t)
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

    // Total dummy reserve provisions over the simulation
    r_nTotalqResDemand(restypeDirectionNode(restype, up_down, node))
        = sum(ft_realizedNoReset(f, t),
            + r_qResDemand(restype, up_down, node, f, t)
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

* --- Total Generation Results ------------------------------------------------

// Total generation in gn
r_gnTotalGen(gn(grid, node))
    = sum(gnu_output(grid, node, unit), r_gnuTotalGen(grid, node, unit));

// Total generation in g
r_gTotalGen(grid)
    = sum(gn(grid, node), r_gnTotalGen(grid, node));

// Total generation gnu/gn shares
r_gnuTotalGenShare(gnu_output(grid, node, unit))${ r_gnTotalGen(grid, node) }
    = r_gnuTotalGen(grid, node, unit)
        / r_gnTotalGen(grid, node);

// Total generation gn/g shares
r_gnTotalGenShare(gn(grid, node))${ r_gTotalGen(grid) }
    = r_gnTotalGen(grid, node)
        / r_gTotalGen(grid);

* --- Total Dummy Generation Results ------------------------------------------

// Total dummy generaion in g
r_gTotalqGen(inc_dec, grid)
    = sum(gn(grid, node), r_gnTotalqGen(inc_dec, grid, node));

* --- Total Energy Consumption Results ----------------------------------------

// Total consumption on each gn over the simulation
r_gnTotalConsumption(gn(grid, node))
    = sum(ft_realizedNoReset(f, t), r_gnConsumption(grid, node, f ,t));

// Total consumption in each grid over the simulation
r_gTotalConsumption(grid)
    = sum(gn(grid, node), r_gnTotalConsumption(grid, node));

// Total consumption gn/g share
r_gnTotalConsumptionShare(gn(grid, node))${ r_gTotalConsumption(grid) }
    = r_gnTotalConsumption(grid, node)
        / r_gTotalConsumption(grid);

* --- Total Fuel Consumption Results ------------------------------------------

// Total fuel consumption in grids over the simulation
r_gTotalGenFuel(grid, fuel)
    = sum(gn(grid, node), r_gnTotalGenFuel(grid, node, fuel));

// Total fuel consumption over the simulation
r_totalGenFuel(fuel)
    = sum(gn(grid, node), r_gnTotalGenFuel(grid, node, fuel));

// Total fuel consumption gn/g shares
r_gnTotalGenFuelShare(gn(grid, node), fuel)${ r_gTotalGenFuel(grid, fuel) }
    = r_gnTotalGenFuel(grid, node, fuel)
        / r_gTotalGenFuel(grid, fuel);

* --- Total Spilled Energy Results --------------------------------------------

// Total spilled energy in each grid over the simulation
r_gTotalSpill(grid)
    = sum(gn(grid, node_spill(node)), r_gnTotalSpill(grid, node));

// Total spilled energy gn/g share
r_gnTotalSpillShare(gn(grid, node_spill))${ r_gTotalSpill(grid) }
    = r_gnTotalSpill(grid, node_spill)
        / r_gTotalSpill(grid);

* --- Total Costs Results -----------------------------------------------------

// Total realized costs on each gn over the simulation
r_gnTotalRealizedCost(gn(grid, node))
    = sum(ft_realizedNoReset(f, t), r_gnRealizedCost(grid, node, f ,t));

// Total realized costs on each grid over the simulation
r_gTotalRealizedCost(grid)
    = sum(gn(grid, node), r_gnTotalRealizedCost(grid, node));

// Total realized costs gn/g share
r_gnTotalRealizedCostShare(gn(grid, node))${ r_gTotalRealizedCost(grid) }
    = r_gnTotalRealizedCost(grid, node)
        / r_gTotalRealizedCost(grid);

// Total realized costs over the simulation
r_totalRealizedCost
    = sum(gn(grid, node), r_gnTotalRealizedCost(grid, node));

* --- Total Reserve Provision Results -----------------------------------------

// Total reserve provision in nodes over the simulation
r_nTotalReserve(restypeDirectionNode(restype, up_down, node))
    = sum(nuRescapable(restype, up_down, node, unit), r_nuTotalReserve(restype, up_down, node, unit));

r_nuTotalReserveShare(nuRescapable(restype, up_down, node, unit))${ r_nTotalReserve(restype, up_down, node) }
    = r_nuTotalReserve(restype, up_down, node, unit)
        / r_nTotalReserve(restype, up_down, node);

* --- Total Unit Online State Results -----------------------------------------

// Total unit online hours per sub-unit over the simulation
r_uTotalOnlinePerUnit(unit)${ p_unit(unit, 'unitCount') }
    = r_uTotalOnline(unit)
        / p_unit(unit, 'unitCount');

// Total sub-unit startups over the simulation
r_uTotalStartup(unit, starttype)
    = sum(ft_realizedNoReset(f, t),
        + r_startup(unit, starttype, f, t)
        ); // END sum(ft_realizedNoReset)

// Total sub-unit shutdowns over the simulation
r_uTotalShutdown(unit)
    = sum(ft_realizedNoReset(f, t),
        + r_shutdown(unit, f, t)
        ); // END sum(ft_realizedNoReset)



