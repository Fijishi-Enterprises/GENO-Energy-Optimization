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
* --- Time Step Dependent Results ---------------------------------------------
* =============================================================================

// Need to loop over the model dimension, as this file is no longer contained in the modelSolves loop...
loop(m,

* --- Realized Individual Costs ----------------------------------------------

    // Variable O&M costs
    r_gnuVOMCost(gnu_output(grid, node, unit), ft_realizedNoReset(f,t))$[ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')]
        = 1e-6 // Scaling to MEUR
            * p_stepLengthNoReset(m, f, t)
            * r_gen(grid, node, unit, f, t)
            * p_unit(unit, 'omCosts');

    // Fuel and emission costs during normal operation
    r_uFuelEmissionCost(fuel, unit_fuel(unit), ft_realizedNoReset(f,t))${ uFuel(unit, 'main', fuel) and [ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')]}
        = 1e-6 // Scaling to MEUR
            * p_stepLengthNoReset(m, f, t)
            * r_fuelUse(fuel, unit, f, t)
            * [ // Fuel price
                + ts_fuelPrice(fuel, t)
                // Emission costs
                + sum(emission, p_unitFuelEmissionCost(unit, fuel, emission))
                ];

    // Unit startup costs
    r_uStartupCost(unit, ft_realizedNoReset(f,t))${uft_online(unit, f, t) and sum(starttype, unitStarttype(unit, starttype)) and [ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')]}
        = 1e-6 // Scaling to MEUR
            * sum(unitStarttype(unit, starttype),
                + r_startup(unit, starttype, f, t)
                    * [ // Startup VOM
                        + p_uStartup(unit, starttype, 'cost')

                        // Startup fuel consumption and emissions
                        + sum(uFuel(unit, 'startup', fuel),
                            + p_uStartup(unit, starttype, 'consumption')
                                * p_uFuel(unit, 'startup', fuel, 'fixedFuelFraction')
                                * [ // Fuel price
                                    + ts_fuelPrice(fuel, t)
                                    // Emission costs
                                    + sum(emission, // Emission taxes
                                        + p_unitFuelEmissionCost(unit, fuel, emission)
                                        ) // END sum(emission)
                                    ] // END * p_uStartup
                            ) // END sum(uFuel)
                        ] // END * r_startup
                ); // END sum(unitStarttype)

    // Node state slack costs
    r_gnStateSlackCost(gn_stateSlack(grid, node), ft_realizedNoReset(f,t))$[ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')]
        = 1e-6 // Scaling to MEUR
            * p_stepLengthNoReset(m, f, t)
            * sum(slack${ p_gnBoundaryPropertiesForStates(grid, node, slack, 'slackCost') },
                + r_stateSlack(grid, node, slack, f, t)
                    * p_gnBoundaryPropertiesForStates(grid, node, slack, 'slackCost')
                ); // END sum(slack)

    // Storage Value Change
    r_gnStorageValueChange(gn_state(grid, node))${ sum(t_full(t), p_storageValue(grid, node, t)) }
        = 1e-6
            * [
                + sum(ft_realizedNoReset(f,t)${ ord(t) = mSettings(m, 't_end') + 1 },
                    + p_storageValue(grid, node, t)
                        * r_state(grid, node, f, t)
                    ) // END sum(ft_realizedNoReset)
                - sum(ft_realizedNoReset(f,t)${ ord(t) = mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod') }, // INITIAL v_state NOW INCLUDED IN THE RESULTS
                    + p_storageValue(grid, node, t)
                        * r_state(grid, node, f, t)
                    ) // END sum(ft_realizedNoReset)
                ]; // END * 1e-6

* --- Total Cost Components ---------------------------------------------------

    // Total VOM costs
    r_gnuTotalVOMCost(gnu_output(grid, node, unit))
        = sum(ft_realizedNoReset(f,t)$[ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')],
            + r_gnuVOMCost(grid, node, unit, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s))
            );

    // Total fuel & emission costs
    r_uTotalFuelEmissionCost(fuel, unit)${ uFuel(unit, 'main', fuel) }
        = sum(ft_realizedNoReset(f,t)$[ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')],
            + r_uFuelEmissionCost(fuel, unit, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s))
            );

    // Total unit startup costs
    r_uTotalStartupCost(unit)${ sum(starttype, unitStarttype(unit, starttype)) }
        = sum(ft_realizedNoReset(f,t)$[ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')],
            + r_uStartupCost(unit, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s))
            );

    // Total state variable slack costs
    r_gnTotalStateSlackCost(gn_stateSlack(grid, node))
        = sum(ft_realizedNoReset(f,t)$[ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')],
            + r_gnStateSlackCost(grid, node, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s))
            );

    // Fixed O&M costs
    r_gnuFOMCost(gnu(grid, node, unit))
        = 1e-6 // Scaling to MEUR
            * (p_gnu(grid, node, unit, 'maxGen') + r_invest(unit)*p_gnu(grid, node, unit, 'unitSizeGen'))
            * p_gnu(grid, node, unit, 'fomCosts');

    // Unit investment costs
    r_gnuUnitInvestmentCost(gnu(grid, node, unit))
        = 1e-6 // Scaling to MEUR
            * r_invest(unit)*p_gnu(grid, node, unit, 'unitSizeGen')
            * p_gnu(grid, node, unit, 'invCosts')
            * p_gnu(grid, node, unit, 'annuity');

    // Transfer link investment costs
    r_gnnLinkInvestmentCost(grid, from_node, to_node)
        = 1e-6 // Scaling to MEUR
            * sum(t_invest, r_investTransfer(grid, from_node, to_node, t_invest))
            * [
                + p_gnn(grid, from_node, to_node, 'invCost')
                    * p_gnn(grid, from_node, to_node, 'annuity')
                + p_gnn(grid, to_node, from_node, 'invCost')
                    * p_gnn(grid, to_node, from_node, 'annuity')
                ]; // END * r_investTransfer;

* --- Realized Nodal System Costs ---------------------------------------------

    // Total realized gn operating costs
    r_gnRealizedOperatingCost(gn(grid, node), ft_realizedNoReset(f, t))$[ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')]
        = sum(gnu_output(grid, node, unit),

            // VOM costs
            + r_gnuVOMCost(grid, node, unit, f, t)

            // Divide fuel and startup costs based on output capacities
            + [
                + p_gnu(grid, node, unit, 'maxGen')${p_unit(unit, 'outputCapacityTotal')}
                + p_gnu(grid, node, unit, 'unitSizeGen')${not p_unit(unit, 'outputCapacityTotal')}
                ]
                    / [
                        + p_unit(unit, 'outputCapacityTotal')${p_unit(unit, 'outputCapacityTotal')}
                        + p_unit(unit, 'unitOutputCapacityTotal')${not p_unit(unit, 'outputCapacityTotal')}
                        ] // END /
                    * [
                        + sum(uFuel(unit, 'main', fuel), r_uFuelEmissionCost(fuel, unit, f, t))
                        + r_uStartupCost(unit, f, t)
                        ] // END *
            ) // END sum(gnu_output)

            // Node state slack costs
            + r_gnStateSlackCost(grid, node, f, t);

* --- Realized Nodal Energy Consumption ---------------------------------------
// !!! NOTE !!! This is a bit of an approximation at the moment !!!!!!!!!!!!!!!

    r_gnConsumption(gn(grid, node), ft_realizedNoReset(f, t))$[ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')]
        = p_stepLengthNoReset(m, f, t)
            * sum(msft(m, s, f, t), p_msft_probability(m, s, f, t))
            * [
                + min(ts_influx(grid, node, f, t), 0) // Not necessarily a good idea, as ts_influx contains energy gains as well...
                + sum(gnu_input(grid, node, unit),
                    + r_gen(grid, node, unit, f, t)
                    ) // END sum(gnu_input)
                ];

* --- Total Energy Generation -------------------------------------------------

    // Total energy generation
    r_gnuTotalGen(gnu_output(grid, node, unit))
        = sum(ft_realizedNoReset(f, t)$[ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')],
            + r_gen(grid, node, unit, f, t)
                * p_stepLengthNoReset(m, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s))
            ); // END sum(ft_realizedNoReset)

    // Energy generation by fuels
    r_genFuel(gn(grid, node), fuel, ft_realizedNoReset(f, t))$[ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')]
        = sum(uFuel(unit, 'main', fuel)${ gnu_output(grid, node, unit) },
            + r_gen(grid, node, unit, f, t)
            ); // END sum(uFuel)

    // Energy generation by fuels
    r_genUnittype(gn(grid, node), unittype, t)${  sum(f,ft_realizedNoReset(f,t))
                                                  and sum(unit,gnu_output(grid, node, unit))
                                                  and [ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')]
                                                  }
        = sum(unit${unitUnittype(unit, unittype) and gnu_output(grid, node, unit)},
            + sum(f,r_gen(grid, node, unit, f, t))
            ); // END sum(unit)

    // Total generation on each node by fuels
    r_gnTotalGenFuel(gn(grid, node), fuel)
        = sum(ft_realizedNoReset(f, t)$[ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')],
            + r_genFuel(grid, node, fuel, f, t)
                * p_stepLengthNoReset(m, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s))
            ); // END sum(ft_realizedNoReset)

    // Total dummy generation/consumption
    r_gnTotalqGen(inc_dec, gn(grid, node))
        = sum(ft_realizedNoReset(f,t)$[ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')],
            + r_qGen(inc_dec, grid, node, f, t)
                * p_stepLengthNoReset(m, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s))
            ); // END sum(ft_realizedNoReset)

* --- Total Unit Online Results -----------------------------------------------

    // Total sub-unit-hours for units over the simulation
    r_uTotalOnline(unit)
        = sum(ft_realizedNoReset(f, t)$[ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')],
            + r_online(unit, f, t)
                * p_stepLengthNoReset(m, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s))
            ); // END sum(ft_realizedNoReset)

    // Approximate utilization rates for gnus over the simulation
    r_gnuUtilizationRate(gnu_output(grid, node, unit))${r_gnuTotalGen(grid, node, unit)}
        = r_gnuTotalGen(grid, node, unit)
            / [
                + (p_gnu(grid, node, unit, 'maxGen') + r_invest(unit)*p_gnu(grid, node, unit, 'unitSizeGen'))
                    * (mSettings(m, 't_end') - (mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')) + 1)
                    * mSettings(m, 'stepLengthInHours')
                ]; // END division

* --- Total Reserve Provision -------------------------------------------------

    // Total reserve provisions over the simulation
    r_nuTotalReserve(nuRescapable(restype, up_down, node, unit))
        = sum(ft_realizedNoReset(f, t)$[ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')],
            + r_reserve(restype, up_down, node, unit, f, t)
                * p_stepLengthNoReset(m, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s))
            ); // END sum(ft_realizedNoReset)

    // Total dummy reserve provisions over the simulation
    r_nTotalqResDemand(restypeDirectionNode(restype, up_down, node))
        = sum(ft_realizedNoReset(f, t)$[ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')],
            + r_qResDemand(restype, up_down, node, f, t)
                * p_stepLengthNoReset(m, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s))
            ); // END sum(ft_realizedNoReset)

* --- Total Transfer and Spill ------------------------------------------------

    // Total transfer of energy between nodes
    r_gnnTotalTransfer(gn2n(grid, from_node, to_node))
        = sum(ft_realizedNoReset(f, t)$[ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')],
            + r_transfer(grid, from_node, to_node, f, t)
                * p_stepLengthNoReset(m, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s))
            ); // END sum(ft_realizedNoReset)

    // Total energy spill from nodes
    r_gnTotalSpill(grid, node_spill(node))
        = sum(ft_realizedNoReset(f, t)$[ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')],
            + r_spill(grid, node, f, t)
                * p_stepLengthNoReset(m, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s))
            ); // END sum(ft_realizedNoReset)

* =============================================================================
* --- Futher Time Step Independent Results ------------------------------------
* =============================================================================

* --- Scaling Marginal Values to EUR/MWh --------------------------------------

// Energy balance
r_balanceMarginal(gn(grid, node), ft_realizedNoReset(f, t))$[ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')]
    = 1e6 * r_balanceMarginal(grid, node, f, t);

// Reserve balance
r_resDemandMarginal(restypeDirectionNode(restype, up_down, node), ft_realizedNoReset(f, t))$[ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')]
    = 1e6 * r_resDemandMarginal(restype, up_down, node, f, t);

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
    = sum(ft_realizedNoReset(f, t)$[ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')],
        + r_gnConsumption(grid, node, f ,t)
            * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s))
        );

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
r_gnTotalGenFuelShare(gn(grid, node), fuel)${ r_gnTotalGen(grid, node) }
    = r_gnTotalGenFuel(grid, node, fuel)
        / r_gnTotalGen(grid, node);

* --- Total Spilled Energy Results --------------------------------------------

// Total spilled energy in each grid over the simulation
r_gTotalSpill(grid)
    = sum(gn(grid, node_spill(node)), r_gnTotalSpill(grid, node));

// Total spilled energy gn/g share
r_gnTotalSpillShare(gn(grid, node_spill))${ r_gTotalSpill(grid) }
    = r_gnTotalSpill(grid, node_spill)
        / r_gTotalSpill(grid);

* --- Total Costs Results -----------------------------------------------------

// Total realized operating costs on each gn over the simulation
r_gnTotalRealizedOperatingCost(gn(grid, node))
    = sum(ft_realizedNoReset(f, t)$[ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')],
        + r_gnRealizedOperatingCost(grid, node, f ,t)
            * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s))
        );

// Total realized net operating costs on each gn over the simulation
r_gnTotalRealizedNetOperatingCost(gn(grid, node))
    = r_gnTotalRealizedOperatingCost(grid, node) - r_gnStorageValueChange(grid, node);

// Total realized operating costs on each grid over the simulation
r_gTotalRealizedOperatingCost(grid)
    = sum(gn(grid, node), r_gnTotalRealizedOperatingCost(grid, node));

// Total realized net operating costs on each grid over the simulation
r_gTotalRealizedNetOperatingCost(grid)
    = sum(gn(grid, node), r_gnTotalRealizedNetOperatingCost(grid, node));

// Total realized operating costs gn/g share
r_gnTotalRealizedOperatingCostShare(gn(grid, node))${ r_gTotalRealizedOperatingCost(grid) }
    = r_gnTotalRealizedOperatingCost(grid, node)
        / r_gTotalRealizedOperatingCost(grid);

// Total realized operating costs over the simulation
r_totalRealizedOperatingCost
    = sum(gn(grid, node), r_gnTotalRealizedOperatingCost(grid, node));

// Total realized net operating costs over the simulation
r_totalRealizedNetOperatingCost
    = sum(gn(grid, node), r_gnTotalRealizedNetOperatingCost(grid, node));

// Total realized costs on each gn over the simulation
r_gnTotalRealizedCost(gn(grid, node))
    = r_gnTotalRealizedOperatingCost(grid, node)
        + sum(gnu(grid, node, unit),
            + r_gnuFOMCost(grid, node, unit)
            + r_gnuUnitInvestmentCost(grid, node, unit)
            )
        + sum(gn2n_directional(grid, from_node, node),
            + r_gnnLinkInvestmentCost(grid, from_node, node)
                / 2
            )
        + sum(gn2n_directional(grid, node, to_node),
            + r_gnnLinkInvestmentCost(grid, node, to_node)
                / 2
            );

// Total realized net costs on each gn over the simulation
r_gnTotalRealizedNetCost(gn(grid, node))
    = r_gnTotalRealizedCost(grid, node) - r_gnStorageValueChange(grid, node);

// Total realized costs on each grid over the simulation
r_gTotalRealizedCost(grid)
    = sum(gn(grid, node), r_gnTotalRealizedCost(grid, node));

// Total realized net costs on each grid over the simulation
r_gTotalRealizedNetCost(grid)
    = sum(gn(grid, node), r_gnTotalRealizedNetCost(grid, node));

// Total realized costs gn/g share
r_gnTotalRealizedCostShare(gn(grid, node))${ r_gTotalRealizedCost(grid) }
    = r_gnTotalRealizedCost(grid, node)
        / r_gTotalRealizedCost(grid);

// Total realized costs over the simulation
r_totalRealizedCost
    = sum(gn(grid, node), r_gnTotalRealizedCost(grid, node));

// Total realized net operating costs over the simulation
r_totalRealizedNetCost
    = sum(gn(grid, node), r_gnTotalRealizedNetCost(grid, node));

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
    = sum(ft_realizedNoReset(f, t)$[ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')],
        + r_startup(unit, starttype, f, t)
            * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s))
        ); // END sum(ft_realizedNoReset)

// Total sub-unit shutdowns over the simulation
r_uTotalShutdown(unit)
    = sum(ft_realizedNoReset(f, t)$[ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')],
        + r_shutdown(unit, f, t)
            * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s))
        ); // END sum(ft_realizedNoReset)

* --- Diagnostic Results ------------------------------------------------------

// Estimated coefficients of performance
d_cop(unit, ft_realizedNoReset(f, t))${  [ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')]
                                         and sum(gnu_input(grid, node, unit), 1)
                                         }
    = sum(gnu_output(grid, node, unit),
        + r_gen(grid, node, unit, f, t)
        ) // END sum(gnu_output)
        / [ sum(gnu_input(grid_, node_, unit),
                -r_gen(grid_, node_, unit, f, t)
                ) // END sum(gnu_input)
            + 1${not sum(gnu_input(grid_, node_, unit), -r_gen(grid_, node_, unit, f, t))}
            ];

// Estimated efficiency
d_eff(unit_fuel(unit), ft_realizedNoReset(f, t))$[ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')]
    = sum(gnu_output(grid, node, unit),
        + r_gen(grid, node, unit, f, t)
        ) // END sum(gnu_output)
        / [ sum(uFuel(unit, 'main', fuel),
                + r_fuelUse(fuel, unit, f, t)
                ) // END sum(uFuel)
            + 1${not sum(uFuel(unit, 'main', fuel), r_fuelUse(fuel, unit, f, t))}
            ];


); // END loop(m)

