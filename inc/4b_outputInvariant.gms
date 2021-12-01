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


// for performance, get rid of any zeros in r_gen and r_reserve. Many zero values missing anyway.
r_gen(gnu, f, t)$((r_gen(gnu, f, t)=0)$r_gen(gnu, f, t))=0;
r_reserve(restype, up_down, gnu, f, t)$((r_reserve(restype, up_down, gnu, f, t)=0)$r_reserve(restype, up_down, gnu, f, t))=0;

* =============================================================================
* --- Time Step Dependent Results ---------------------------------------------
* =============================================================================

// Need to loop over the model dimension, as this file is no longer contained in the modelSolves loop...
loop(m,

    option clear=startp; startp(t)$(ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod'))=yes;
* --- Realized Individual Costs ----------------------------------------------

    // Variable O&M costs
    r_gnuVOMCost(gnu(grid, node, unit), ft_realizedNoReset(f,startp(t)))
        = 1e-6 // Scaling to MEUR
            * p_stepLengthNoReset(m, f, t)
            * abs(r_gen(grid, node, unit, f, t))
            * p_gnu(grid, node, unit, 'vomCosts');

    // Fuel and emission costs during normal operation
    // Note that this result calculation uses ts_price directly while the
    // objective function uses ts_price average over the interval. There can
    // be differences if realized intervals contain several time steps.
    r_uFuelEmissionCost(gnu(grid, node, unit), ft_realizedNoReset(f,startp(t)))
        = 1e-6 // Scaling to MEUR
            * p_stepLengthNoReset(m, f, t)
            * abs(r_gen(grid, node, unit, f, t))
            * [ + p_price(node, 'price')${p_price(node, 'useConstant') and gnu_input(grid, node, unit)}
                + ts_price(node, t)${p_price(node, 'useTimeSeries') and gnu_input(grid, node, unit)}
                - p_price(node, 'price')${p_price(node, 'useConstant') and gnu_output(grid, node, unit)}
                - ts_price(node, t)${p_price(node, 'useTimeSeries') and gnu_output(grid, node, unit)}
                // Emission costs
                + sum(emission, p_unitEmissionCost(unit, node, emission))
              ];

    // Unit startup costs
    r_uStartupCost(unit, ft_realizedNoReset(f,startp(t)))$sum(starttype, unitStarttype(unit, starttype))
        = 1e-6 // Scaling to MEUR
            * sum(unitStarttype(unit, starttype),
                + r_startup(unit, starttype, f, t)
                    * [
                        // Fuel costs
                        + p_uStartup(unit, starttype, 'cost') // CUR/start-up
                        // Start-up fuel and emission costs
                        + sum(nu_startup(node,unit),
                            + p_unStartup(unit, node, starttype) // MWh/start-up
                              * [
                                  + p_price(node, 'price')$p_price(node, 'useConstant') // CUR/MWh
                                  + ts_price(node, t)$p_price(node, 'useTimeseries') // CUR/MWh
                                  // Emission costs
                                  + sum(emission$p_nEmission(node, emission),
                                       + p_nEmission(node, emission) // kg/MWh
                                          / 1e3 // NOTE!!! Conversion to t/MWh from kg/MWh in data
                                          * sum(gnGroup(grid, node, group),
                                              + p_groupPolicyEmission(group, 'emissionTax', emission) // CUR/t
                                              ) // END sum(gnGroup)
                                      ) // END sum(emission)
                                ] // END * p_unStartup
                            ) // END sum(nu_startup)
                      ] // END * r_startup
              ); // END sum(starttype)

    //Variable Trnasfer Costs
    r_gnnVariableTransCost(gn2n_directional(grid, node_, node), ft_realizedNoReset(f,startp(t)))
        = 1e-6 // Scaling to MEUR
            * p_stepLengthNoReset(m, f, t)
                    *[+ p_gnn(grid, node, node_, 'variableTransCost')
                    * r_transferLeftward(grid, node_, node, f, t)
                    + p_gnn(grid, node_, node, 'variableTransCost')
                    * r_transferRightward(grid, node_, node, f, t)];

   // Transfer marginal value (Me) calculated from r_transfer * balanceMarginal * transferLosses
   r_gnnTransferValue(gn2n_directional(grid, node_, node), ft_realizedNoReset(f,startp(t)))
        = p_stepLengthNoReset(m, f, t)
            * [ r_transferRightward(grid, node_, node, f, t)
                * r_balanceMarginal(grid, node, f, t)
                - r_transferLeftward(grid, node_, node, f, t)
                * r_balanceMarginal(grid, node_, f, t)
              ]
            * [ 1 - p_gnn(grid, node_, node, 'transferLoss')${not gn2n_timeseries(grid, node_, node, 'transferLoss')}
                - ts_gnn_(grid, node_, node, 'transferLoss', f, t)${gn2n_timeseries(grid, node_, node, 'transferLoss')}
              ]
    ;

    // Node state slack costs
    r_gnStateSlackCost(gn_stateSlack(grid, node), ft_realizedNoReset(f,startp(t)))
        = 1e-6 // Scaling to MEUR
            * p_stepLengthNoReset(m, f, t)
            * sum(slack${ p_gnBoundaryPropertiesForStates(grid, node, slack, 'slackCost') },
                + r_stateSlack(grid, node, slack, f, t)
                    * p_gnBoundaryPropertiesForStates(grid, node, slack, 'slackCost')
                ); // END sum(slack)

    // Storage Value Change
    r_gnStorageValueChange(gn_state(grid, node))${ active(m, 'storageValue') }
        = 1e-6
            * [
                + sum(ft_realizedNoReset(f,t)${ ord(t) = mSettings(m, 't_end') + 1 },
                    + [
                        + p_storageValue(grid, node)${ not p_gn(grid, node, 'storageValueUseTimeSeries') }
                        + ts_storageValue(grid, node, f, t)${ p_gn(grid, node, 'storageValueUseTimeSeries') }
                      ]
                        * r_state(grid, node, f, t)
                    ) // END sum(ft_realizedNoReset)
                - sum(ft_realizedNoReset(f,t)${ ord(t) = mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod') }, // INITIAL v_state NOW INCLUDED IN THE RESULTS
                    + [
                        + p_storageValue(grid, node)${ not p_gn(grid, node, 'storageValueUseTimeSeries') }
                        + ts_storageValue(grid, node, f, t)${ p_gn(grid, node, 'storageValueUseTimeSeries') }
                      ]
                        * r_state(grid, node, f, t)
                    ) // END sum(ft_realizedNoReset)
                ]; // END * 1e-6

    // Diffusion from node to node_
    // Note that this result paramater does not necessarily consider the
    // implicit node state variable dynamics properly if energyStoredPerUnitOfState
    // is not equal to 0
    r_gnnDiffusion(gn_state(grid, node), node_, ft_realizedNoReset(f,startp(t)))
        ${gnn_state(grid, node, node_) or gnn_state(grid, node_, node)}
        = p_gnn(grid, node, node_, 'diffCoeff') * r_state(grid, node, f, t)
            - p_gnn(grid, node_, node, 'diffCoeff') * r_state(grid, node_, f, t)
            ;

* --- Total Cost Components (discounted) --------------------------------------

    // Total VOM costs
    r_gnuTotalVOMCost(gnu_output(grid, node, unit))
        = sum(ft_realizedNoReset(f,startp(t)),
            + r_gnuVOMCost(grid, node, unit, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s) * p_s_discountFactor(s))
            );

    // Total Variable Transfer costs
    r_gnnTotalVariableTransCost(gn2n_directional(grid, node_, node))
        = sum(ft_realizedNoReset(f,startp(t)),
            + r_gnnVariableTransCost(grid, node_, node, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s) * p_s_discountFactor(s))
            );

    // Total transfer marginal value over the simulation
    r_gnnTotalTransferValue(gn2n_directional(grid, node_, node))
        = sum(ft_realizedNoReset(f,startp(t)),
            + r_gnnTransferValue(grid, node_, node, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s) * p_s_discountFactor(s))
            )
    ;

    // Total fuel & emission costs
    r_uTotalFuelEmissionCost(gnu(grid, node, unit))
        = sum(ft_realizedNoReset(f,startp(t)),
            + r_uFuelEmissionCost(grid, node, unit, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s) * p_s_discountFactor(s))
            );

    // Total unit startup costs
    r_uTotalStartupCost(unit)$sum(starttype, unitStarttype(unit, starttype))
        = sum(ft_realizedNoReset(f,startp(t)),
            + r_uStartupCost(unit, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s) * p_s_discountFactor(s))
            );

    // Total state variable slack costs
    r_gnTotalStateSlackCost(gn_stateSlack(grid, node))
        = sum(ft_realizedNoReset(f,startp(t)),
            + r_gnStateSlackCost(grid, node, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s) * p_s_discountFactor(s))
            );

    // Fixed O&M costs
    r_gnuFOMCost(gnu(grid, node, unit))
        = 1e-6 // Scaling to MEUR
            * sum(ms(m, s)${ sum(msft_realizedNoReset(m, s, f, t_), 1) }, // consider ms only if it has active msft_realizedNoReset
                + [
                    + p_gnu(grid, node, unit, 'capacity')$sum(msft_realizedNoReset(m, s, f, t_), uft(unit, f, t_)) // Not in v_obj; only units active in msft_realizedNoReset
                    + r_invest(unit)$sum(msft_realizedNoReset(m, s, f, t_), uft(unit, f, t_)) // only units active in msft_realizedNoReset
                        * p_gnu(grid, node, unit, 'unitSize')
                    ]
                    * p_msAnnuityWeight(m, s) // Sample weighting to calculate annual costs
                    * p_s_discountFactor(s) // Discount costs
                ) // END * sum(ms)
            * p_gnu(grid, node, unit, 'fomCosts');

    // Unit investment costs
    r_gnuUnitInvestmentCost(gnu(grid, node, unit))
        = 1e-6 // Scaling to MEUR
            * sum(ms(m, s)${ sum(msft_realizedNoReset(m, s, f, t_), 1) }, // consider ms only if it has active msft_realizedNoReset
                + r_invest(unit)$sum(msft_realizedNoReset(m, s, f, t_), uft(unit, f, t_)) // only units active in msft_realizedNoReset
                    * p_msAnnuityWeight(m, s) // Sample weighting to calculate annual costs
                    * p_s_discountFactor(s) // Discount costs
                ) // END * sum(ms)
            * p_gnu(grid, node, unit, 'unitSize')
            * p_gnu(grid, node, unit, 'invCosts')
            * p_gnu(grid, node, unit, 'annuity');

    // Transfer link investment costs
    r_gnnLinkInvestmentCost(gn2n_directional(grid, from_node, to_node)) // gn2n_directional only, as in q_obj
        = 1e-6 // Scaling to MEUR
            * sum(ms(m, s)${ sum(msft_realizedNoReset(m, s, f, t_), 1) }, // consider ms only if it has active msft_realizedNoReset
                + sum(t_invest(t)${ord(t) <= msEnd(m, s)}, // only if investment was made before or during the sample
                    + r_investTransfer(grid, from_node, to_node, t)
                    )
                    * p_msAnnuityWeight(m, s) // Sample weighting to calculate annual costs
                    * p_s_discountFactor(s) // Discount costs
                ) // END * sum(ms)
            * [
                + p_gnn(grid, from_node, to_node, 'invCost')
                    * p_gnn(grid, from_node, to_node, 'annuity')
                + p_gnn(grid, to_node, from_node, 'invCost')
                    * p_gnn(grid, to_node, from_node, 'annuity')
                ]; // END * r_investTransfer;

* --- Realized Nodal System Costs ---------------------------------------------

    // Total realized gn operating costs
    r_gnRealizedOperatingCost(gn(grid, node), ft_realizedNoReset(f, startp(t)))
        = + sum(gnu(grid, node, unit),
              // VOM costs
              + r_gnuVOMCost(grid, node, unit, f, t)
              + r_uFuelEmissionCost(grid, node, unit, f, t)
            )

          // Allocate startup costs on energy basis, but for output nodes only
          + sum(unit$(r_gen(grid, node, unit, f, t)$gnu_output(grid, node, unit)),
              + abs{r_gen(grid, node, unit, f, t)}  // abs is due to potential negative outputs like energy from a cooling unit. It's the energy contribution that matters, not direction.
                   / sum(gnu_output(grid_output, node_output, unit),
                       + abs{r_gen(grid_output, node_output, unit, f, t)}
                     ) // END sum(gnu_output)
                * r_uStartupCost(unit, f, t)
            )
          + sum(gn2n_directional(grid, node_, node),
              // Variable Transfer costs
              + r_gnnVariableTransCost(grid, node_, node, f, t)
            )
          // Node state slack costs
          + r_gnStateSlackCost(grid, node, f, t);

* --- Realized Nodal Energy Consumption ---------------------------------------
// !!! NOTE !!! This is a bit of an approximation at the moment !!!!!!!!!!!!!!!

    r_gnConsumption(gn(grid, node), ft_realizedNoReset(f, startp(t)))
        = p_stepLengthNoReset(m, f, t)
            * [
                + min(ts_influx(grid, node, f, t), 0) // Not necessarily a good idea, as ts_influx contains energy gains as well...
                + sum(gnu_input(grid, node, unit),
                    + r_gen(grid, node, unit, f, t)
                    ) // END sum(gnu_input)
                ];

* --- Total Energy Generation -------------------------------------------------

    // Total energy generation
    r_gnuTotalGen(gnu_output(grid, node, unit))
        = sum(ft_realizedNoReset(f, startp(t)),
            + r_gen(grid, node, unit, f, t)
                * p_stepLengthNoReset(m, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
            ); // END sum(ft_realizedNoReset)

    r_gen_gnUnittype(gn(grid, node), unittype)$sum(unit$unitUnittype(unit, unittype), 1)
      = sum(gnu(grid,node,unit)$unitUnittype(unit, unittype),
            sum(ft_realizedNoReset(f, startp(t)),
              + r_gen(grid, node, unit, f, t)
                  * p_stepLengthNoReset(m, f, t)
                  * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
            ) // END sum(ft_realizedNoReset)
        );

    // Energy output to a node based on inputs from another node or flows
    r_genFuel(gn(grid, node), node_, ft_realizedNoReset(f, startp(t)))$sum(gnu_input(grid_, node_, unit)$gnu_output(grid, node, unit),r_gen(grid_, node_, unit, f, t))
        = sum(gnu_output(grid, node, unit)$sum(gnu_input(grid_, node_, unit), 1),
            + r_gen(grid, node, unit, f, t)
          );
// The calculation with multiple inputs needs to be fixed below (right share for different commodities - now units with multiple input commodities will get the same amount allocated which will then be too big
//          * sum((grid_, unit)$gnu_output(grid, node, unit),
//                r_gen(grid_, commodity, unit, f, t))
//                  / sum(gnu_input(grid__, node_, unit), r_gen(grid__, node_, unit, f, t));

    r_genFuel(gn(grid, node), flow, ft_realizedNoReset(f, t))$flowNode(flow, node)
        = sum(gnu_output(grid, node, unit)$flowUnit(flow, unit),
            + r_gen(grid, node, unit, f, t));

    // Energy generation for each unittype
    r_genUnittype(gn(grid, node), unittype, ft_realizedNoReset(f,startp(t)))
        = sum(gnu_output(grid, node, unit)$unitUnittype(unit, unittype),
            + r_gen(grid, node, unit, f, t)
            ); // END sum(unit)

    // Total energy generation in gn per input type over the simulation
    r_gnTotalGenFuel(gn(grid, node), node_)
        = sum(ft_realizedNoReset(f, startp(t)),
            + r_genFuel(grid, node, node_, f, t)
                * p_stepLengthNoReset(m, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
            ); // END sum(ft_realizedNoReset)

    // Total dummy generation/consumption
    r_gnTotalqGen(inc_dec, gn(grid, node))
        = sum(ft_realizedNoReset(f,startp(t)),
            + r_qGen(inc_dec, grid, node, f, t)
                * p_stepLengthNoReset(m, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
            ); // END sum(ft_realizedNoReset)

    // Unit start-up consumption
    r_nuStartupConsumption(nu_startup(node, unit), ft_realizedNoReset(f,startp(t)))
        ${sum(starttype, unitStarttype(unit, starttype))}
        = sum(unitStarttype(unit, starttype),
            + r_startup(unit, starttype, f, t)
                * p_unStartup(unit, node, starttype) // MWh/start-up
            ); // END sum(unitStarttype)

* --- Emission Results --------------------------------------------------------

    // Emissions of units (not including start-up fuels)
    // Only taking into account emissions from input because emissions from output
    // do not cause costs and are not considered in emission cap
    r_emissions(grid, node, emission, unit, ft_realizedNoReset(f,startp(t)))
       $gnu_input(grid, node, unit)
        =   + p_stepLengthNoReset(m, f, t)
            * abs(r_gen(grid, node, unit, f, t))
            * p_nEmission(node, emission)
            / 1e3 // NOTE!!! Conversion to t/MWh from kg/MWh in data
    ;

    // Emissions from unit outputs
    r_emissionsFromOutput(grid, node, emission, unit, ft_realizedNoReset(f,startp(t)))
        $gnu_output(grid, node, unit)
        =   + p_stepLengthNoReset(m, f, t)
            * r_gen(grid, node, unit, f, t)
            * p_nEmission(node, emission)
            / 1e3 // NOTE!!! Conversion to t/MWh from kg/MWh in data
    ;

    // Emissions from unit start-ups
    r_emissionsStartup(node, emission, unit, ft_realizedNoReset(f,startp(t)))
        ${sum(starttype, p_unStartup(unit, node, starttype))
          and p_nEmission(node, emission)}
        = sum(unitStarttype(unit, starttype),
            + r_startup(unit, starttype, f, t)
                * p_unStartup(unit, node, starttype) // MWh/start-up
                * p_nEmission(node, emission) // kg/MWh
                / 1e3 // NOTE!!! Conversion to t/MWh from kg/MWh in data
            ); // END sum(starttype)

    // Emission sums from normal operation input
    r_nuTotalEmissionsOperation(nu(node, unit), emission)
        = sum(ft_realizedNoReset(f, startp(t)),
            + sum(gn(grid, node), r_emissions(grid, node, emission, unit, f, t))
                 * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
            )
    ;

    // Emission sums from unit outputs
    r_nuTotalEmissionsFromOutput(nu(node, unit), emission)
        = sum(ft_realizedNoReset(f, startp(t)),
            + sum(gn(grid, node), r_emissionsFromOutput(grid, node, emission, unit, f, t))
                 * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
            )
    ;

    // Emission sums from start-ups
    r_nuTotalEmissionsStartup(nu_startup(node, unit), emission)
        = sum(ft_realizedNoReset(f, startp(t)),
            + r_emissionsStartup(node, emission, unit, f, t)
                 * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
            )
    ;

    // Emission sums (normal operation input and start-ups)
    r_nuTotalEmissions(node, unit, emission)
        = r_nuTotalEmissionsOperation(node, unit, emission)
            + r_nuTotalEmissionsStartup(node, unit, emission)
    ;

    r_nTotalEmissions(node, emission)
        = sum(unit, r_nuTotalEmissions (node, unit, emission))
    ;

    r_uTotalEmissions(unit, emission)
        = sum(node, r_nuTotalEmissions (node, unit, emission))
    ;

    r_totalEmissions (emission)
        = sum(node, r_nTotalEmissions(node, emission))
    ;

* --- Total Unit Online Results -----------------------------------------------

    // Total sub-unit-hours for units over the simulation
    r_uTotalOnline(unit)
        = sum(ft_realizedNoReset(f, startp(t)),
            + r_online(unit, f, t)
                * p_stepLengthNoReset(m, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
            ); // END sum(ft_realizedNoReset)

    // Approximate utilization rates for gnus over the simulation
    r_gnuUtilizationRate(gnu_output(grid, node, unit))${ r_gnuTotalGen(grid, node, unit)
                                                         and ( p_gnu(grid, node, unit, 'capacity')
                                                               or r_invest(unit)
                                                               )
                                                         }
        = r_gnuTotalGen(grid, node, unit)
            / [
                + (p_gnu(grid, node, unit, 'capacity') + r_invest(unit)*p_gnu(grid, node, unit, 'unitSize'))
                    * (mSettings(m, 't_end') - (mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')) + 1)
                    * mSettings(m, 'stepLengthInHours')
                ]; // END division

* --- Total Reserve Provision -------------------------------------------------

    // Total reserve provisions over the simulation
    r_gnuTotalReserve(gnuRescapable(restype, up_down, grid, node, unit))
        = sum(ft_realizedNoReset(f, startp(t)),
            + r_reserve(restype, up_down, grid, node, unit, f, t)
                * p_stepLengthNoReset(m, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
            ); // END sum(ft_realizedNoReset)

    // Total dummy reserve provisions over the simulation
    r_groupTotalqResDemand(restypeDirectionGroup(restype, up_down, group))
        = sum(ft_realizedNoReset(f, startp(t)),
            + r_qResDemand(restype, up_down, group, f, t)
                * p_stepLengthNoReset(m, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
            ); // END sum(ft_realizedNoReset)

* --- Total Transfer and Spill ------------------------------------------------

    // Total transfer of energy between nodes
    r_gnnTotalTransfer(gn2n(grid, from_node, to_node))
        = sum(ft_realizedNoReset(f, startp(t)),
            + r_transfer(grid, from_node, to_node, f, t)
                * p_stepLengthNoReset(m, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
            ); // END sum(ft_realizedNoReset)

    // Total energy spill from nodes
    r_gnTotalSpill(grid, node_spill(node))
        = sum(ft_realizedNoReset(f, startp(t)),
            + r_spill(grid, node, f, t)
                * p_stepLengthNoReset(m, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
            ); // END sum(ft_realizedNoReset)

* =============================================================================
* --- Futher Time Step Independent Results ------------------------------------
* =============================================================================

* --- Scaling Marginal Values to EUR/MWh from MEUR/MWh ------------------------

// Energy balance
r_balanceMarginal(gn(grid, node), ft_realizedNoReset(f, startp(t)))
    = 1e6 * r_balanceMarginal(grid, node, f, t);

// Reserve balance
r_resDemandMarginal(restypeDirectionGroup(restype, up_down, group), ft_realizedNoReset(f, startp(t)))
    = 1e6 * r_resDemandMarginal(restype, up_down, group, f, t);

* --- Total Generation Results ------------------------------------------------

// Total generation in gn
r_gnTotalGen(gn(grid, node))
    = sum(gnu_output(grid, node, unit), r_gnuTotalGen(grid, node, unit));

// Total generation in g
r_gTotalGen(grid)
    = sum(gn(grid, node), r_gnTotalGen(grid, node));

// Total generation gnu/gn shares
r_gnuTotalGenShare(gnu_output(grid, node, unit))${ r_gnTotalGen(grid, node) > 0 }
    = r_gnuTotalGen(grid, node, unit)
        / r_gnTotalGen(grid, node);

// Total generation gn/g shares
r_gnTotalGenShare(gn(grid, node))${ r_gTotalGen(grid) > 0 }
    = r_gnTotalGen(grid, node)
        / r_gTotalGen(grid);

* --- Total Dummy Generation Results ------------------------------------------

// Total dummy generaion in g
r_gTotalqGen(inc_dec, grid)
    = sum(gn(grid, node), r_gnTotalqGen(inc_dec, grid, node));

* --- Total Energy Consumption Results ----------------------------------------

// Total consumption on each gn over the simulation
r_gnTotalConsumption(gn(grid, node))
    = sum(ft_realizedNoReset(f, startp(t)),
        + r_gnConsumption(grid, node, f ,t)
            * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
        );

// Total consumption in each grid over the simulation
r_gTotalConsumption(grid)
    = sum(gn(grid, node), r_gnTotalConsumption(grid, node));

// Total consumption gn/g share
r_gnTotalConsumptionShare(gn(grid, node))${ r_gTotalConsumption(grid) > 0 }
    = r_gnTotalConsumption(grid, node)
        / r_gTotalConsumption(grid);

* --- Total Energy Generation Results Per Input Type --------------------------

// Total energy generation in grids per input type over the simulation
r_gTotalGenFuel(grid, node_)
    = sum(gn(grid, node), r_gnTotalGenFuel(grid, node, node_));

// Total overall energy generation per input type over the simulation
r_totalGenFuel(node_)
    = sum(gn(grid, node), r_gnTotalGenFuel(grid, node, node_));

// Total energy generation in gn per input type as a share of total energy generation in gn across all input types
r_gnTotalGenFuelShare(gn(grid, node), node_)${ r_gnTotalGen(grid, node) }
    = r_gnTotalGenFuel(grid, node, node_)
        / r_gnTotalGen(grid, node);

* --- Total Spilled Energy Results --------------------------------------------

// Total spilled energy in each grid over the simulation
r_gTotalSpill(grid)
    = sum(gn(grid, node_spill(node)), r_gnTotalSpill(grid, node));

// Total spilled energy gn/g share
r_gnTotalSpillShare(gn(grid, node_spill))${ r_gTotalSpill(grid) > 0 }
    = r_gnTotalSpill(grid, node_spill)
        / r_gTotalSpill(grid);

* --- Total Costs Results (discounted) ----------------------------------------

// Total realized operating costs on each gn over the simulation
r_gnTotalRealizedOperatingCost(gn(grid, node))
    = sum(ft_realizedNoReset(f, startp(t)),
        + r_gnRealizedOperatingCost(grid, node, f ,t)
            * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s) * p_s_discountFactor(s))
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
r_gnTotalRealizedOperatingCostShare(gn(grid, node))${ r_gTotalRealizedOperatingCost(grid) > 0 }
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
                / 2 // Half of the link costs are allocated to the receiving end
            )
        + sum(gn2n_directional(grid, node, to_node),
            + r_gnnLinkInvestmentCost(grid, node, to_node)
                / 2 // Half of the link costs are allocated to the sending end
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
r_gnTotalRealizedCostShare(gn(grid, node))${ r_gTotalRealizedCost(grid) > 0 }
    = r_gnTotalRealizedCost(grid, node)
        / r_gTotalRealizedCost(grid);

// Total realized costs over the simulation
r_totalRealizedCost
    = sum(gn(grid, node), r_gnTotalRealizedCost(grid, node));

// Total realized net operating costs over the simulation
r_totalRealizedNetCost
    = sum(gn(grid, node), r_gnTotalRealizedNetCost(grid, node));

// Total realized fixed costs on each gn over the simulation
r_gnTotalRealizedFixedCost(gn(grid, node))
    = r_gnTotalRealizedCost(grid, node)
        - r_gnTotalRealizedOperatingCost(grid, node);

// Total realized fixed costs on each grid over the simulation
r_gTotalRealizedFixedCost(grid)
    = r_gTotalRealizedCost(grid)
        - r_gTotalRealizedOperatingCost(grid);

// Total realized fixed costs gn/g share
r_gnTotalRealizedFixedCostShare(gn(grid, node))${ r_gTotalRealizedFixedCost(grid) > 0 }
    = r_gnTotalRealizedFixedCost(grid, node)
        / r_gTotalRealizedFixedCost(grid);

// Total realized fixed costs over the simulation
r_totalRealizedFixedCost
    = r_totalRealizedCost
        - r_totalRealizedOperatingCost;

* --- Reserve Provision Overlap Results ---------------------------------------

// Calculate the overlapping reserve provisions
r_reserve2Reserve(gnuRescapable(restype, up_down, grid, node, unit), restype_, ft_realizedNoReset(f, t))
    ${ p_gnuRes2Res(grid, node, unit, restype, up_down, restype_) }
    = r_reserve(restype, up_down, grid, node, unit, f, t)
        * p_gnuRes2Res(grid, node, unit, restype, up_down, restype_);

* --- Total Reserve Provision Results -----------------------------------------

// Total reserve provision in groups over the simulation
r_groupTotalReserve(restypeDirectionGroup(restype, up_down, group))
    = sum(gnuRescapable(restype, up_down, grid, node, unit)${gnGroup(grid, node, group)},
        + r_gnuTotalReserve(restype, up_down, grid, node, unit)
    ); // END sum(gnuRescapable)

r_gnuTotalReserveShare(gnuRescapable(restype, up_down, grid, node, unit))
    ${ sum(gnGroup(grid, node, group), r_groupTotalReserve(restype, up_down, group)) > 0 }
    = r_gnuTotalReserve(restype, up_down, grid, node, unit)
        / sum(gnGroup(grid, node, group), r_groupTotalReserve(restype, up_down, group));

* --- Total Unit Online State Results -----------------------------------------

// Total unit online hours per sub-unit over the simulation
r_uTotalOnlinePerUnit(unit)${ p_unit(unit, 'unitCount') > 0 }
    = r_uTotalOnline(unit)
        / p_unit(unit, 'unitCount');

// Total sub-unit startups over the simulation
r_uTotalStartup(unit, starttype)
    = sum(ft_realizedNoReset(f, startp(t)),
        + r_startup(unit, starttype, f, t)
            * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
        ); // END sum(ft_realizedNoReset)

// Total sub-unit shutdowns over the simulation
r_uTotalShutdown(unit)
    = sum(ft_realizedNoReset(f, startp(t)),
        + r_shutdown(unit, f, t)
            * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
        ); // END sum(ft_realizedNoReset)

* --- Sum results for groups --------------------------------------------------

// gnTotalgen in units that belong to gnuGroups over the simulation
r_gnTotalGenGnuGroup(grid, node, group)
    = sum(unit $ {gnuGroup(grid, node, unit, group)},
        + r_gnuTotalGen(grid, node, unit)
         ); // END sum(unit)

* --- Diagnostic Results ------------------------------------------------------

// Only include these if '--diag=yes' given as a command line argument
$iftheni.diag '%diag%' == yes
// Estimated coefficients of performance
d_cop(unit, ft_realizedNoReset(f, startp(t)))$sum(gnu_input(grid, node, unit), 1)
    = sum(gnu_output(grid, node, unit),
        + r_gen(grid, node, unit, f, t)
        ) // END sum(gnu_output)
        / [ sum(gnu_input(grid_, node_, unit),
                -r_gen(grid_, node_, unit, f, t)
                ) // END sum(gnu_input)
            + 1${not sum(gnu_input(grid_, node_, unit), -r_gen(grid_, node_, unit, f, t))}
            ]
        + Eps; // Eps to correct GAMS plotting (zeroes are not skipped)

// Estimated efficiency, calculated from inputs
d_eff(unit(unit), ft_realizedNoReset(f, t))$[ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')]
    = sum(gnu_output(grid, node, unit),
        + r_gen(grid, node, unit, f, t)
        ) // END sum(gnu_output)
        / [ sum(gnu_input(grid, node, unit),
                + abs(r_gen(grid, node, unit, f, t))
                ) // END sum(gnu_input)
            + 1${not sum(gnu_input(grid, node, unit), abs(r_gen(node, unit, f, t)))}
            ]
        + Eps; // Eps to correct GAMS plotting (zeroes are not skipped)
$endif.diag

); // END loop(m)

