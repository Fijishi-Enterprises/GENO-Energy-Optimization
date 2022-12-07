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


// for performance, get rid of any zeros in selected tables. Many zero values missing already and these remove the remaining ones.
r_gen_gnuft(gnu, f, t)$((r_gen_gnuft(gnu, f, t)=0)$r_gen_gnuft(gnu, f, t))=0;
r_state_gnft(grid, node, f, t)$((r_state_gnft(grid, node, f, t)=0)$r_state_gnft(grid, node, f, t))=0;
r_reserve_gnuft(restype, up_down, gnu, f, t)$((r_reserve_gnuft(restype, up_down, gnu, f, t)=0)$r_reserve_gnuft(restype, up_down, gnu, f, t))=0;

* =============================================================================
* --- Time Step Dependent Results ---------------------------------------------
* =============================================================================

// Need to loop over the model dimension, as this file is no longer contained in the modelSolves loop...
loop(m,

    option clear=t_startp;
    t_startp(t)
      ${(ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod'))
        and (ord(t) <= mSettings(m, 't_end')+1)
        and sum((s,f), sft_realizedNoReset(s, f , t))
        } =yes;

* --- Node result Symbols -----------------------------------------------------------
* --- Spill results -----------------------------------------------------------

    // Total energy spill from nodes
    r_spill_gn(grid, node_spill(node))
        = sum(ft_realizedNoReset(f, t_startp(t)),
            + r_spill_gnft(grid, node, f, t)
                * p_stepLengthNoReset(m, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
            ); // END sum(ft_realizedNoReset)

    // Total spilled energy in each grid over the simulation
    r_spill_g(grid)
        = sum(gn(grid, node_spill(node)), r_spill_gn(grid, node));

    // Total spilled energy gn/g share
    r_spill_gnShare(gn(grid, node_spill))${ r_spill_g(grid) > 0 }
        = r_spill_gn(grid, node_spill)
            / r_spill_g(grid);

* --- Energy Transfer results -----------------------------------------------------------

    // Total transfer of energy between nodes
    r_transfer_gnn(gn2n(grid, from_node, to_node))
        = sum(ft_realizedNoReset(f, t_startp(t)),
            + r_transfer_gnnft(grid, from_node, to_node, f, t)
                * p_stepLengthNoReset(m, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
            ); // END sum(ft_realizedNoReset)

* --- Marginal value of energy results -----------------------------------------------------------

    r_balance_marginalValue_gnAverage(gn(grid, node))
        = sum(ft_realizedNoReset(f, t_startp(t)),
             + r_balance_marginalValue_gnft(grid, node, f, t)
                // * p_stepLengthNoReset(m, f, t)   // not including steplength due to division by number of timesteps
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
            ) // END sum(ft_realizedNoReset)
            / sum(t, t_realized(t)*1) // divided by number of realized time steps
            ;

   // Transfer marginal value (Me) calculated from r_transfer * balanceMarginal * transferLosses
   r_transferValue_gnnft(gn2n_directional(grid, node_, node), ft_realizedNoReset(f,t_startp(t)))
        = p_stepLengthNoReset(m, f, t)
            * [ r_transferRightward_gnnft(grid, node_, node, f, t)
                * r_balance_marginalValue_gnft(grid, node, f, t)
                - r_transferLeftward_gnnft(grid, node_, node, f, t)
                * r_balance_marginalValue_gnft(grid, node_, f, t)
              ]
            * [ 1 - p_gnn(grid, node_, node, 'transferLoss')${not gn2n_timeseries(grid, node_, node, 'transferLoss')}
                - ts_gnn_(grid, node_, node, 'transferLoss', f, t)${gn2n_timeseries(grid, node_, node, 'transferLoss')}
              ]
    ;

    // Total transfer marginal value over the simulation
    r_transferValue_gnn(gn2n_directional(grid, node_, node))
        = sum(ft_realizedNoReset(f,t_startp(t)),
            + r_transferValue_gnnft(grid, node_, node, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s) * p_s_discountFactor(s))
            )
    ;

* --- Other node related results -----------------------------------------------------------

    r_curtailments_gnft(gn(grid, node), ft_realizedNoReset(f,t_startp(t)))
        ${sum(flow, flowNode(flow, node)) }
        = sum(flowUnit(flow, unit),
            // + (capacity + investments) * ts_cf   for generating units only
            + [p_gnu(grid, node, unit, 'capacity')$gnu_output(grid, node, unit)
               + r_invest_unitCount_u(unit)$gnu_output(grid, node, unit)
              ]
            * ts_cf(flow, node, f ,t)

            // - actual generation
            - r_gen_gnuft(grid, node, unit, f, t)
        ); // END sum(flowUnit)

    r_curtailments_gn(gn(grid, node))
        ${sum(flow, flowNode(flow, node))}
        = sum(ft_realizedNoReset(f,t_startp(t)), r_curtailments_gnft(grid, node, f, t)
          ); // END sum (ft_realizedNoReset)


    // Diffusion from node to node_
    // Note that this result paramater does not necessarily consider the
    // implicit node state variable dynamics properly if energyStoredPerUnitOfState
    // is not equal to 0
    r_diffusion_gnnft(gn_state(grid, node), node_, ft_realizedNoReset(f,t_startp(t)))
        ${gnn_state(grid, node, node_) or gnn_state(grid, node_, node)}
        = p_gnn(grid, node, node_, 'diffCoeff') * r_state_gnft(grid, node, f, t)
            - p_gnn(grid, node_, node, 'diffCoeff') * r_state_gnft(grid, node_, f, t)
    ;

    // Total diffusion of energy between nodes
    r_diffusion_gnn(gn2n(grid, from_node, to_node))
        = sum(ft_realizedNoReset(f, t_startp(t)),
            + r_diffusion_gnnft(grid, from_node, to_node, f, t)
                * p_stepLengthNoReset(m, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
            ); // END sum(ft_realizedNoReset)


* --- Energy Generation/Consumption Result Symbols -----------------------------------------------------------
* --- Energy Generation results-------------------------------------------------------

    // Total energy generation in gnu
    r_gen_gnu(gnu(grid, node, unit))
        = sum(ft_realizedNoReset(f, t_startp(t)),
            + r_gen_gnuft(grid, node, unit, f, t)
                * p_stepLengthNoReset(m, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
            ); // END sum(ft_realizedNoReset)

    // energy generation for each gridnode (MW)
    r_gen_gnft(gn(grid, node), ft_realizedNoReset(f, t_startp(t)))
        = sum(unit, r_gen_gnuft(grid, node, unit, f, t));

    // Total generation in gn
    r_gen_gn(gn(grid, node))
        = sum(unit, r_gen_gnu(grid, node, unit));

    // Total generation in g
    r_gen_g(grid)
       = sum(gn(grid, node), r_gen_gn(grid, node));

    // Total generation gnu/gn shares
    r_gen_gnuShare(gnu(grid, node, unit))${ r_gen_gn(grid, node) <> 0 }
       = r_gen_gnu(grid, node, unit)
           / r_gen_gn(grid, node);

    // Total generation gn/g shares
    r_gen_gnShare(gn(grid, node))${ r_gen_g(grid) <> 0 }
       = r_gen_gn(grid, node)
           / r_gen_g(grid);

* --- Approximate utilization rates ---------------------------------------

    // Approximate utilization rates for gnus over the simulation
    r_utilizationRate_gnu(gnu(grid, node, unit))${ r_gen_gnu(grid, node, unit)
                                                         and ( p_gnu(grid, node, unit, 'capacity')
                                                               or (r_invest_unitCount_u(unit) and p_gnu(grid, node, unit, 'unitSize'))
                                                               )
                                                         }
        = r_gen_gnu(grid, node, unit)
            / [
                + (p_gnu(grid, node, unit, 'capacity') + r_invest_unitCount_u(unit)*p_gnu(grid, node, unit, 'unitSize'))
                    * (mSettings(m, 't_end') - (mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')) + 1)
                    * mSettings(m, 'stepLengthInHours')
                ]; // END division

* --- Energy generation results based on input unittype, or group -------------------------------------------------------

    // Calculates wrong with storages when there is a loop, e.g. elecGrid -> elecStorage -> elecGrid
    // Energy output to a node based on inputs from another node or flows
    r_genByFuel_gnft(gn(grid, node), node_, ft_realizedNoReset(f, t_startp(t)))
        ${sum(gnu_input(grid_, node_, unit)$gnu_output(grid, node, unit),r_gen_gnuft(grid_, node_, unit, f, t)) }
        = sum(gnu_output(grid, node, unit)$sum(gnu_input(grid_, node_, unit), 1),
            + r_gen_gnuft(grid, node, unit, f, t)
          );
// The calculation with multiple inputs needs to be fixed below (right share for different commodities - now units with multiple input commodities will get the same amount allocated which will then be too big
//          * sum((grid_, unit)$gnu_output(grid, node, unit),
//                r_gen_gnuft(grid_, commodity, unit, f, t))
//                  / sum(gnu_input(grid__, node_, unit), r_gen_gnuft(grid__, node_, unit, f, t));

    r_genByFuel_gnft(gn(grid, node), flow, ft_realizedNoReset(f, t))$flowNode(flow, node)
        = sum(gnu_output(grid, node, unit)$flowUnit(flow, unit),
            + r_gen_gnuft(grid, node, unit, f, t));

    // Total energy generation in gn per input type over the simulation
    r_genByFuel_gn(gn(grid, node), node_)
        = sum(ft_realizedNoReset(f, t_startp(t)),
            + r_genByFuel_gnft(grid, node, node_, f, t)
                * p_stepLengthNoReset(m, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
            ); // END sum(ft_realizedNoReset)
    r_genByFuel_gn(gn(grid, node), flow)
        = sum(ft_realizedNoReset(f, t_startp(t)),
            + r_genByFuel_gnft(grid, node, flow, f, t)
                * p_stepLengthNoReset(m, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
            ); // END sum(ft_realizedNoReset)

    // Total energy generation in grids per input type over the simulation
    r_genByFuel_g(grid, node_)
        = sum(gn(grid, node), r_genByFuel_gn(grid, node, node_));
    r_genByFuel_g(grid, flow)
        = sum(gn(grid, node), r_genByFuel_gn(grid, node, flow));

    // Total overall energy generation per input type over the simulation
    r_genByFuel_fuel(node_)
        = sum(gn(grid, node), r_genByFuel_gn(grid, node, node_));
    r_genByFuel_fuel(flow)
        = sum(gn(grid, node), r_genByFuel_gn(grid, node, flow));

    // Total energy generation in gn per input type as a share of total energy generation in gn across all input types
    r_genByFuel_gnShare(gn(grid, node), node_)${ r_gen_gn(grid, node) }
        = r_genByFuel_gn(grid, node, node_)
            / r_gen_gn(grid, node);
    r_genByFuel_gnShare(gn(grid, node), flow)${ r_gen_gn(grid, node) }
        = r_genByFuel_gn(grid, node, flow)
            / r_gen_gn(grid, node);

    // Energy generation for each unittype
    r_genByUnittype_gnft(gn(grid, node), unittype, ft_realizedNoReset(f,t_startp(t)))
        = sum(gnu(grid, node, unit)$unitUnittype(unit, unittype),
            + r_gen_gnuft(grid, node, unit, f, t)
            ); // END sum(unit)

    // Total energy generation in gnu by unit type
    r_genByUnittype_gn(gn(grid, node), unittype)${ sum(unit$unitUnittype(unit, unittype), 1) }
      = sum(gnu(grid,node,unit)$unitUnittype(unit, unittype),
             + r_gen_gnu(grid, node, unit)
            );

    // gnTotalgen in units that belong to gnuGroups over the simulation
    r_genByGnuGroup_gn(grid, node, group)
        = sum(unit $ {gnuGroup(grid, node, unit, group)},
            + r_gen_gnu(grid, node, unit)
            ); // END sum(unit)

* --- Energy consumption during startups --------------------------------------

    // Unit start-up consumption
    r_consumption_unitStartup_nu(nu_startup(node, unit), ft_realizedNoReset(f,t_startp(t)))
        ${sum(starttype, unitStarttype(unit, starttype))}
        = sum(unitStarttype(unit, starttype),
            + r_startup_uft(starttype, unit, f, t)
                * p_unStartup(unit, node, starttype) // MWh/start-up
            ); // END sum(unitStarttype)

* --- Unit Online, startup, and shutdown Result Symbols ---------------------------------------
* --- other online, startup, and shutdown results ---------------------------------------


    // Total sub-unit-hours for units over the simulation
    r_online_u(unit)
        = sum(ft_realizedNoReset(f, t_startp(t)),
            + r_online_uft(unit, f, t)
                * p_stepLengthNoReset(m, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
            ); // END sum(ft_realizedNoReset)

    // Total unit online hours per sub-unit over the simulation
    r_online_perUnit_u(unit)${ p_unit(unit, 'unitCount') > 0 }
        = r_online_u(unit)
            / p_unit(unit, 'unitCount');

    // Total sub-unit startups over the simulation
    r_startup_u(unit, starttype)
        = sum(ft_realizedNoReset(f, t_startp(t)),
            + r_startup_uft(starttype, unit, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
            ); // END sum(ft_realizedNoReset)

    // Total sub-unit shutdowns over the simulation
    r_shutdown_u(unit)
        = sum(ft_realizedNoReset(f, t_startp(t)),
            + r_shutdown_uft(unit, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
            ); // END sum(ft_realizedNoReset)




* --- Investment Result Symbols ---------------------------------------
* --- Invested unit count and capacity ---------------------------------------------

    // Capacity of unit investments
    r_invest_unitCapacity_gnu(grid, node, unit)${ r_invest_unitCount_u(unit) }
        = r_invest_unitCount_u(unit) *p_gnu(grid, node, unit, 'unitSize')
    ;






* --- Emission results ---------------------------------------
* --- Emissions by activity type ---------------------------------------------

    // Emissions during normal operation (tEmission)
    r_emission_operationEmissions_gnuft(gn(grid, node), emission, unit, ft_realizedNoReset(f,t_startp(t)))
        $ {p_nEmission(node, emission)
           or p_gnuEmission(grid, node, unit, emission, 'vomEmissions')
          }
        =   + p_stepLengthNoReset(m, f, t)
            * (
               // Emissions from fuel use (gn related emissions)
               // multiply by -1 because consumption in r_gen is negative and production positive
               -r_gen_gnuft(grid, node, unit, f, t) * p_nEmission(node, emission)
               // Emissions from unit operation (gnu related vomEmissions)
               // absolute values as all unit specific emission factors are considered as emissions by default
               + abs(r_gen_gnuft(grid, node, unit, f, t)) * p_gnuEmission(grid, node, unit, emission, 'vomEmissions') // t/MWh
              ); // END *p_stepLengthNoReset

    // Emission sums from normal operation input
    r_emission_operationEmissions_nu(nu(node, unit), emission)
        = sum(ft_realizedNoReset(f, t_startp(t)),
            + sum(gn(grid, node), r_emission_operationEmissions_gnuft(grid, node, emission, unit, f, t))
                 * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
            ); // END sum(ft_realizedNoReset)

    // Emissions from unit start-ups (tEmission)
    r_emission_startupEmissions_nuft(node, emission, unit, ft_realizedNoReset(f,t_startp(t)))
        ${sum(starttype, p_unStartup(unit, node, starttype))
          and p_nEmission(node, emission)
         }
        = sum(unitStarttype(unit, starttype),
            + r_startup_uft(starttype, unit, f, t) // number of startups
                * p_unStartup(unit, node, starttype) // MWh_fuel/startup
                * p_nEmission(node, emission) // tEmission/MWh_fuel
            ); // END sum(starttype)

    // Emission sums from start-ups
    r_emission_StartupEmissions_nu(nu_startup(node, unit), emission)
        = sum(ft_realizedNoReset(f, t_startp(t)),
            + r_emission_startupEmissions_nuft(node, emission, unit, f, t)
                 * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
            ); // END sum(ft_realizedNoReset)

    // Emissions from fixed o&m emissions and investments (tEmission)
    r_emission_capacityEmissions_nu(node, unit, emission)
        ${(sum(gn, p_gnuEmission(gn, unit, emission, 'fomEmissions'))
          or sum(gn, p_gnuEmission(gn, unit, emission, 'invEmissions')))
          }
        = + sum(grid$p_gnuEmission(grid, node, unit, emission, 'fomEmissions'),
               p_gnuEmission(grid, node, unit, emission, 'fomEmissions')
               * (p_gnu(grid, node, unit, 'capacity')
                  + r_invest_unitCapacity_gnu(grid, node, unit))
            ) // END sum(gn)
          + sum(grid$p_gnuEmission(grid, node, unit, emission, 'invEmissions'),
               p_gnuEmission(grid, node, unit, emission, 'invEmissions')
               * r_invest_unitCapacity_gnu(grid, node, unit)
               * p_gnuEmission(grid, node, unit, emission, 'invEmissionsFactor')
            ); // END sum(gn)

* --- Emission Sum Results ----------------------------------------------------

    // Emission in gnGroup
    r_emissionByNodeGroup(emission, group)
        = sum(ft_realizedNoReset(f, t_startp(t)),
            // Emissions from operation: consumption and production of fuels - gn related emissions (tEmission)
            + sum(gnu(grid, node, unit)${gnGroup(grid, node, group) and p_nEmission(node, emission)},
                 // multiply by -1 because consumption in r_gen is negative and production positive
                 - p_stepLengthNoReset(m, f, t)
                 * r_gen_gnuft(grid, node, unit, f, t)
                 * p_nEmission(node, emission)
                 * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
              ) // END sum(gnu)
            // Emissions from operation: gnu related vomEmissions (tEmission)
            + sum(gnu(grid, node, unit)${gnGroup(grid, node, group) and p_gnuEmission(grid, node, unit, emission, 'vomEmissions')},
                 // absolute values as all gnu specific emission factors are considered emissions
                 + p_stepLengthNoReset(m, f, t)
                 * abs(r_gen_gnuft(grid, node, unit, f, t))
                 * p_gnuEmission(grid, node, unit, emission, 'vomEmissions')
                 * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
              ) // END sum(gnu)
            // Emissions from operation: Start-up emissions (tEmission)
            + sum(nu_startup(node, unit)${sum(grid, gnGroup(grid, node, group)) and p_nEmission(node, emission)},
                 r_emission_startupEmissions_nuft(node, emission, unit, f, t)
                 * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
              ) // END sum(nu_startup)
          ) // END sum(ft_realizedNoReset)

          // Emissions from capacity: fixed o&m emissions and investment emissions (tEmission)
          + sum(gnu(gn, unit)${ p_gnuEmission(gn, unit, emission, 'fomEmissions') and gnGroup(gn, group) },
               p_gnuEmission(gn, unit, emission, 'fomEmissions')
               * (p_gnu(gn, unit, 'capacity')
                  + r_invest_unitCapacity_gnu(gn, unit))
               * sum(ms(m, s), p_msProbability(m, s) * p_msWeight(m, s))
            ) // END sum(gnu)
          + sum(gnu(grid, node, unit)${ p_gnuEmission(grid, node, unit, emission, 'invEmissions') and gnGroup(grid, node, group) },
               p_gnuEmission(grid, node, unit, emission, 'invEmissions')
               * r_invest_unitCapacity_gnu(grid, node, unit)
               * p_gnuEmission(grid, node, unit, emission, 'invEmissionsFactor')
               * sum(ms(m, s), p_msProbability(m, s) * p_msWeight(m, s))
            ) // END sum(gnu)
    ;

    // Emission sums
    r_emission_nu(nu(node, unit), emission)
        = r_emission_operationEmissions_nu(node, unit, emission)
            + r_emission_StartupEmissions_nu(node, unit, emission)
            + r_emission_capacityEmissions_nu(node, unit, emission)
    ;

    r_emission_n(node, emission)
        = sum(unit, r_emission_nu(node, unit, emission))
    ;

    r_emission_u(unit, emission)
        = sum(node, r_emission_nu(node, unit, emission))
    ;

    r_emission(emission)
        = sum(node, r_emission_n(node, emission))
    ;




* --- Reserve Result Symbols ---------------------------------------
* --- Unit level reserve Results ---------------------------------------------

    // Total reserve provisions over the simulation
    r_reserve_gnu(gnuRescapable(restype, up_down, grid, node, unit))
        = sum(ft_realizedNoReset(f, t_startp(t)),
            + r_reserve_gnuft(restype, up_down, grid, node, unit, f, t)
                * p_stepLengthNoReset(m, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
            ); // END sum(ft_realizedNoReset)

    // Total reserve provisions over the simulation
    r_reserve_gn(restype, up_down, grid, node)
        =  sum(unit, r_reserve_gnu(restype, up_down, grid, node, unit))
    ;

    // Group sum of reserves of specific types (MW)
    r_reserveByGroup_ft(restypeDirectionGroup(restype, up_down, group), f, t)
        = sum(gnu(grid, node, unit)${ gnGroup(grid, node, group)
                                              and groupRestype(group, restype)
                                              },
            + r_reserve_gnuft(restype, up_down, grid, node, unit, f, t)
          ); // END sum(gnu)

    // Total reserve provision in groups over the simulation
    r_reserveByGroup(restypeDirectionGroup(restype, up_down, group))
        = sum(gnuRescapable(restype, up_down, grid, node, unit)${gnGroup(grid, node, group)},
            + r_reserve_gnu(restype, up_down, grid, node, unit)
        ); // END sum(gnuRescapable)

    r_reserve_gnuShare(gnuRescapable(restype, up_down, grid, node, unit))
        ${ sum(gnGroup(grid, node, group), r_reserveByGroup(restype, up_down, group)) > 0 }
        = r_reserve_gnu(restype, up_down, grid, node, unit)
            / sum(gnGroup(grid, node, group), r_reserveByGroup(restype, up_down, group));

    // Calculate the overlapping reserve provisions
    r_reserve2Reserve_gnuft(gnuRescapable(restype, up_down, grid, node, unit), restype_, ft_realizedNoReset(f, t))
        ${ p_gnuRes2Res(grid, node, unit, restype, up_down, restype_) }
        = r_reserve_gnuft(restype, up_down, grid, node, unit, f, t)
            * p_gnuRes2Res(grid, node, unit, restype, up_down, restype_);

* --- Other reserve Results ---------------------------------------------

    r_reserve_marginalValue_average(restype, up_down, group)
        = sum(ft_realizedNoReset(f, t_startp(t)),
             + r_reserve_marginalValue_ft(restype, up_down, group, f, t)
                // * p_stepLengthNoReset(m, f, t)   // not including steplength due to division by number of timesteps
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
            ) // END sum(ft_realizedNoReset)
            / sum(t, t_realized(t)*1) // divided by number of realized time steps
            ;

    // Total reserve transfer rightward over the simulation
    r_reserveTransferRightward_gnn(restype, up_down, grid, node, to_node)
        = sum(ft_realizedNoReset(f, t_startp(t)),
            + r_reserveTransferRightward_gnnft(restype, up_down, grid, node, to_node, f, t)
                * p_stepLengthNoReset(m, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
            ); // END sum(ft_realizedNoReset)

    // Total reserve transfer leftward over the simulation
    r_reserveTransferLeftward_gnn(restype, up_down, grid, node, to_node)
        = sum(ft_realizedNoReset(f, t_startp(t)),
            + r_reserveTransferLeftward_gnnft(restype, up_down, grid, node, to_node, f, t)
                * p_stepLengthNoReset(m, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
            ); // END sum(ft_realizedNoReset)


* --- Dummy Result Symbols ----------------------------------------------------
* --- Results regarding solution feasibility ----------------------------------

    // Total dummy generation/consumption in gn
    r_qGen_gn(inc_dec, gn(grid, node))
        = sum(ft_realizedNoReset(f,t_startp(t)),
            + r_qGen_gnft(inc_dec, grid, node, f, t)
                * p_stepLengthNoReset(m, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
            ); // END sum(ft_realizedNoReset)

    // Total dummy generation in g
    r_qGen_g(inc_dec, grid)
        = sum(gn(grid, node), r_qGen_gn(inc_dec, grid, node));

    // Total dummy reserve provisions over the simulation
    r_qReserveDemand(restypeDirectionGroup(restype, up_down, group))
        = sum(ft_realizedNoReset(f, t_startp(t)),
            + r_qReserveDemand_ft(restype, up_down, group, f, t)
                * p_stepLengthNoReset(m, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s))
            ); // END sum(ft_realizedNoReset)



* --- Cost result Symbols -----------------------------------------------------------
* --- Unit operational Cost Components ----------------------------------------------

    // Variable O&M costs
    r_cost_unitVOMCost_gnuft(gnu(grid, node, unit), ft_realizedNoReset(f, t_startp(t)))
        = 1e-6 // Scaling to MEUR
            * p_stepLengthNoReset(m, f, t)
            * abs(r_gen_gnuft(grid, node, unit, f, t))
            * p_gnu(grid, node, unit, 'vomCosts');

    // Total VOM costs
    r_cost_unitVOMCost_gnu(gnu(grid, node, unit))
        = sum(ft_realizedNoReset(f, t_startp(t)),
            + r_cost_unitVOMCost_gnuft(grid, node, unit, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s) * p_s_discountFactor(s))
            );

    // Fuel and emission costs during normal operation
    // Note that this result calculation uses ts_price directly while the
    // objective function uses ts_price_ that is average over the intervals. There can
    // be differences if realized intervals contain several time steps.
    r_cost_unitFuelEmissionCost_gnuft(gnu(grid, node, unit), ft_realizedNoReset(f, t_startp(t)))
        = 1e-6 // Scaling to MEUR
            * p_stepLengthNoReset(m, f, t)
            * r_gen_gnuft(grid, node, unit, f, t)
            * [ // gn specific costs are positive for input (cost) and negative for output (income).
                // negative sign in equations as r_gen is negative for input, positive for output
                // gn specific costs from node
                - p_price(node, 'price')$p_price(node, 'useConstant')
                - ts_price(node, t)$p_price(node, 'useTimeSeries')
                // gn specific costs from node emissions
                - sum(emissionGroup(emission, group)$p_nEmission(node, emission),
                   + p_nEmission(node, emission)  // t/MWh
                   * ( + p_emissionPrice(emission, group, 'price')$p_emissionPrice(emission, group, 'useConstant')
                       + ts_emissionPrice(emission, group, t)$p_emissionPrice(emission, group, 'useTimeSeries')
                     )
                  ) // end sum(emissiongroup)
              ]
             // gnu specific costs from node emissions are positive (cost) for both input and output
            + p_stepLengthNoReset(m, f, t)
            * abs(r_gen_gnuft(grid, node, unit, f, t))
            * sum(emissionGroup(emission, group)$p_gnuEmission(grid, node, unit, emission, 'vomEmissions'),
                   + p_gnuEmission(grid, node, unit, emission, 'vomEmissions') // t/MWh
                   * ( + p_emissionPrice(emission, group, 'price')$p_emissionPrice(emission, group, 'useConstant')
                       + ts_emissionPrice(emission, group, t)$p_emissionPrice(emission, group, 'useTimeSeries')
                     )
              ) // end sum(emissiongroup)
    ;

    // Total fuel & emission costs
    r_cost_unitFuelEmissionCost_u(gnu(grid, node, unit))
        = sum(ft_realizedNoReset(f, t_startp(t)),
            + r_cost_unitFuelEmissionCost_gnuft(grid, node, unit, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s) * p_s_discountFactor(s))
            );

    // Unit startup costs
    r_cost_unitStartupCost_uft(unit, ft_realizedNoReset(f, t_startp(t)))$sum(starttype, unitStarttype(unit, starttype))
        = 1e-6 // Scaling to MEUR
            * sum(unitStarttype(unit, starttype),
                + r_startup_uft(starttype, unit, f, t)
                    * [
                        // Fuel costs
                        + p_uStartup(unit, starttype, 'cost') // CUR/start-up
                        // Start-up fuel and emission costs
                        + sum(nu_startup(node,unit),
                            + p_unStartup(unit, node, starttype) // MWh/start-up
                              * [ // fuel costs
                                  + p_price(node, 'price')$p_price(node, 'useConstant') // CUR/MWh
                                  + ts_price(node, t)$p_price(node, 'useTimeseries') // CUR/MWh
                                  // Emission costs from node specific emissions and emission prices
                                  + sum(emissionGroup(emission, group)$p_nEmission(node, emission),
                                     + p_nEmission(node, emission) // t/MWh
                                     * ( + p_emissionPrice(emission, group, 'price')$p_emissionPrice(emission, group, 'useConstant')
                                         + ts_emissionPrice(emission, group, t)$p_emissionPrice(emission, group, 'useTimeSeries')
                                       )
                                    ) // end sum(emissionGroup)
                                 ] // END * p_unStartup
                            ) // END sum(nu_startup)
                      ] // END * r_startup_uft
              ); // END sum(starttype)

    // Total unit startup costs
    r_cost_unitStartupCost_u(unit)$sum(starttype, unitStarttype(unit, starttype))
        = sum(ft_realizedNoReset(f, t_startp(t)),
            + r_cost_unitStartupCost_uft(unit, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s) * p_s_discountFactor(s))
            );

    // Unit shutdown costs (MEUR)
    r_cost_unitShutdownCost_uft(unit, f, t)
        = 1e-6 // Scaling to MEUR
            * r_shutdown_uft(unit, f, t) // number of shutdowns
            * p_uShutdown(unit, 'cost') // EUR/shutdown
          ;

    // Total unit shutdown costs over the simulation (MEUR)
    r_cost_unitShutdownCost_u(unit)
        = sum(ft_realizedNoReset(f, t_startp(t)),
            + r_cost_unitShutdownCost_uft(unit, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s) * p_s_discountFactor(s))
            );

    // Total gnu fixed O&M costs over the simulation, existing and invested units (MEUR)
    r_cost_unitFOMCost_gnu(gnu(grid, node, unit))
        ${ sum(msft(m, s, f, t), usft(unit, s, f, t)) }
        = 1e-6 // Scaling to MEUR
            * sum(ms(m, s)${ sum(msft_realizedNoReset(m, s, f, t), 1) }, // consider ms only if it has active msft_realizedNoReset
                + [
                    + p_gnu(grid, node, unit, 'capacity')
                    + r_invest_unitCount_u(unit)
                        * p_gnu(grid, node, unit, 'unitSize')
                    ]
                    * p_msAnnuityWeight(m, s) // Sample weighting to calculate annual costs
                    * p_s_discountFactor(s) // Discount costs
                ) // END * sum(ms)
            * p_gnu(grid, node, unit, 'fomCosts');

    // Unit investment costs
    r_cost_unitInvestmentCost_gnu(gnu(grid, node, unit))
        = 1e-6 // Scaling to MEUR
            * sum(ms(m, s)${ sum(msft_realizedNoReset(m, s, f, t), 1) }, // consider ms only if it has active msft_realizedNoReset
                + r_invest_unitCount_u(unit)
                    * p_msAnnuityWeight(m, s) // Sample weighting to calculate annual costs
                    * p_s_discountFactor(s) // Discount costs
                ) // END * sum(ms)
            * p_gnu(grid, node, unit, 'unitSize')
            * p_gnu(grid, node, unit, 'invCosts')
            * p_gnu(grid, node, unit, 'annuityFactor');

    // Cost from unit FOM emissions and investment emissions (MEUR)
    r_cost_unitCapacityEmissionCost_nu(node, unit)
        ${ sum(msft(m, s, f, t), usft(unit, s, f, t)) }
        = 1e-6 // Scaling to MEUR
            * sum(ms(m, s)${ sum(msft_realizedNoReset(m, s, f, t), 1) }, // consider ms only if it has active msft_realizedNoReset
                +p_msAnnuityWeight(m, s) // Sample weighting to calculate annual costs
                * p_s_discountFactor(s) // Discount costs

                * sum(emissionGroup(emission, group)$p_nEmission(node, emission),
                    + r_emission_capacityEmissions_nu(node, unit, emission)
                    * [ + p_emissionPrice(emission, group, 'price')$p_emissionPrice(emission, group, 'useConstant')
                        + (sum(t_realized(t), ts_emissionPrice(emission, group, t))/card(t_realized))$p_emissionPrice(emission, group, 'useTimeSeries')
                      ]// END * p_gnuEmssion
                    ) // END sum(emissionGroup)
                ); // END * sum(ms)


* --- Transfer Link Operational Cost Components ----------------------------------------------

    //Variable Transfer Costs
    r_cost_linkVOMCost_gnnft(gn2n_directional(grid, node_, node), ft_realizedNoReset(f, t_startp(t)))
        = 1e-6 // Scaling to MEUR
            * p_stepLengthNoReset(m, f, t)
                    *[+ p_gnn(grid, node, node_, 'variableTransCost')
                    * r_transferLeftward_gnnft(grid, node_, node, f, t)
                    + p_gnn(grid, node_, node, 'variableTransCost')
                    * r_transferRightward_gnnft(grid, node_, node, f, t)];

    // Total Variable Transfer costs
    r_cost_linkVOMCost_gnn(gn2n_directional(grid, node_, node))
        = sum(ft_realizedNoReset(f, t_startp(t)),
            + r_cost_linkVOMCost_gnnft(grid, node_, node, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s) * p_s_discountFactor(s))
            );

    // Transfer link investment costs
    r_cost_linkInvestmentCost_gnn(gn2n_directional(grid, from_node, to_node)) // gn2n_directional only, as in q_obj
        = 1e-6 // Scaling to MEUR
            * sum(ms(m, s)${ sum(msft_realizedNoReset(m, s, f, t), 1) }, // consider ms only if it has active msft_realizedNoReset
                + sum(t_invest(t)${ord(t) <= msEnd(m, s)}, // only if investment was made before or during the sample
                    + r_invest_transferCapacity_gnn(grid, from_node, to_node, t)
                    )
                    * p_msAnnuityWeight(m, s) // Sample weighting to calculate annual costs
                    * p_s_discountFactor(s) // Discount costs
                ) // END * sum(ms)
            * [
                + p_gnn(grid, from_node, to_node, 'invCost')
                    * p_gnn(grid, from_node, to_node, 'annuityFactor')
                + p_gnn(grid, to_node, from_node, 'invCost')
                    * p_gnn(grid, to_node, from_node, 'annuityFactor')
                ]; // END * r_invest_transferCapacity_gnn;


* --- Nodel Cost Components ----------------------------------------------

    // Node state slack costs
    r_cost_stateSlackCost_gnt(gn_stateSlack(grid, node), ft_realizedNoReset(f, t_startp(t)))
        = 1e-6 // Scaling to MEUR
            * p_stepLengthNoReset(m, f, t)
            * sum(slack${ p_gnBoundaryPropertiesForStates(grid, node, slack, 'slackCost') },
                + r_stateSlack_gnft(slack, grid, node, f, t)
                    * p_gnBoundaryPropertiesForStates(grid, node, slack, 'slackCost')
                ); // END sum(slack)



    // Total state variable slack costs
    r_cost_stateSlackCost_gn(gn_stateSlack(grid, node))
        = sum(ft_realizedNoReset(f, t_startp(t)),
            + r_cost_stateSlackCost_gnt(grid, node, f, t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s) * p_s_discountFactor(s))
            );

    // Storage Value Change
    r_cost_storageValueChange_gn(gn_state(grid, node))${ active(m, 'storageValue') }
        = 1e-6
            * [
                + sum(ft_realizedNoReset(f,t)${ ord(t) = mSettings(m, 't_end') + 1 },
                    + [
                        + p_storageValue(grid, node)${ not p_gn(grid, node, 'storageValueUseTimeSeries') }
                        + ts_storageValue(grid, node, f, t)${ p_gn(grid, node, 'storageValueUseTimeSeries') }
                      ]
                        * r_state_gnft(grid, node, f, t)
                    ) // END sum(ft_realizedNoReset)
                - sum(ft_realizedNoReset(f,t)${ ord(t) = mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod') }, // INITIAL v_state NOW INCLUDED IN THE RESULTS
                    + [
                        + p_storageValue(grid, node)${ not p_gn(grid, node, 'storageValueUseTimeSeries') }
                        + ts_storageValue(grid, node, f, t)${ p_gn(grid, node, 'storageValueUseTimeSeries') }
                      ]
                        * r_state_gnft(grid, node, f, t)
                    ) // END sum(ft_realizedNoReset)
                ]; // END * 1e-6

* --- Realized System Operating Costs ---------------------------------------------

    // Total realized gn operating costs
    r_cost_realizedOperatingCost_gnft(gn(grid, node), ft_realizedNoReset(f, t_startp(t)))
        = + sum(gnu(grid, node, unit),
              // VOM costs
              + r_cost_unitVOMCost_gnuft(grid, node, unit, f, t)
              + r_cost_unitFuelEmissionCost_gnuft(grid, node, unit, f, t)
            )

          // Allocate startup costs on energy basis, but for output nodes only
          + sum(unit$(r_gen_gnuft(grid, node, unit, f, t)$gnu_output(grid, node, unit)),
              + abs{r_gen_gnuft(grid, node, unit, f, t)}  // abs is due to potential negative outputs like energy from a cooling unit. It's the energy contribution that matters, not direction.
                   / sum(gnu_output(grid_output, node_output, unit),
                       + abs{r_gen_gnuft(grid_output, node_output, unit, f, t)}
                     ) // END sum(gnu_output)
                * r_cost_unitStartupCost_uft(unit, f, t)
            )
          + sum(gn2n_directional(grid, node_, node),
              // Variable Transfer costs
              + r_cost_linkVOMCost_gnnft(grid, node_, node, f, t)
            )
          // Node state slack costs
          + r_cost_stateSlackCost_gnt(grid, node, f, t);


    // Total realized operating costs on each gn over the simulation
    r_cost_realizedOperatingCost_gn(gn(grid, node))
        = sum(ft_realizedNoReset(f, t_startp(t)),
            + r_cost_realizedOperatingCost_gnft(grid, node, f ,t)
                * sum(msft_realizedNoReset(m, s, f, t), p_msProbability(m, s) * p_msWeight(m, s) * p_s_discountFactor(s))
        );

    // Total realized operating costs on each grid over the simulation
    r_cost_realizedOperatingCost_g(grid)
        = sum(gn(grid, node), r_cost_realizedOperatingCost_gn(grid, node));

    // Total realized operating costs over the simulation
    r_cost_realizedOperatingCost
        = sum(gn(grid, node), r_cost_realizedOperatingCost_gn(grid, node));

    // Total realized operating costs gn/g share
    r_cost_realizedOperatingCost_gnShare(gn(grid, node))${ r_cost_realizedOperatingCost_g(grid) <> 0 }
        = r_cost_realizedOperatingCost_gn(grid, node)
            / r_cost_realizedOperatingCost_g(grid);


    // Total realized net operating costs on each gn over the simulation
    r_cost_realizedNetOperatingCost_gn(gn(grid, node))
        = r_cost_realizedOperatingCost_gn(grid, node) - r_cost_storageValueChange_gn(grid, node);

    // Total realized net operating costs on each grid over the simulation
    r_cost_realizedNetOperatingCost_g(grid)
        = sum(gn(grid, node), r_cost_realizedNetOperatingCost_gn(grid, node));

    // Total realized net operating costs over the simulation
    r_cost_realizedNetOperatingCost
        = sum(gn(grid, node), r_cost_realizedNetOperatingCost_gn(grid, node));

* --- Realized System Costs ---------------------------------------------

    // Total realized costs on each gn over the simulation
    r_cost_realizedCost_gn(gn(grid, node))
        = r_cost_realizedOperatingCost_gn(grid, node)
            + sum(gnu(grid, node, unit),
                + r_cost_unitFOMCost_gnu(grid, node, unit)
                + r_cost_unitInvestmentCost_gnu(grid, node, unit)
                )
            + sum(gn2n_directional(grid, from_node, node),
                + r_cost_linkInvestmentCost_gnn(grid, from_node, node)
                    / 2 // Half of the link costs are allocated to the receiving end
                )
            + sum(gn2n_directional(grid, node, to_node),
                + r_cost_linkInvestmentCost_gnn(grid, node, to_node)
                    / 2 // Half of the link costs are allocated to the sending end
            );

    // Total realized costs on each grid over the simulation
    r_cost_realizedCost_g(grid)
        = sum(gn(grid, node), r_cost_realizedCost_gn(grid, node));

    // Total realized costs over the simulation
    r_cost_realizedCost
        = sum(gn(grid, node), r_cost_realizedCost_gn(grid, node));

    // Total realized costs gn/g share
    r_cost_realizedCost_gnShare(gn(grid, node))${ r_cost_realizedCost_g(grid) <> 0 }
        = r_cost_realizedCost_gn(grid, node)
            / r_cost_realizedCost_g(grid);

    // Total realized net costs on each gn over the simulation
    r_cost_realizedNetCost_gn(gn(grid, node))
        = r_cost_realizedCost_gn(grid, node) - r_cost_storageValueChange_gn(grid, node);

    // Total realized net costs on each grid over the simulation
    r_cost_realizedNetCost_g(grid)
        = sum(gn(grid, node), r_cost_realizedNetCost_gn(grid, node));

    // Total realized net operating costs over the simulation
    r_cost_realizedNetCost
        = sum(gn(grid, node), r_cost_realizedNetCost_gn(grid, node));


* --- Info and diagnostic Result Symbols --------------------------------------
* --- info Results ------------------------------------------------------------

    // copying model settings
    r_info_mSettings(mSetting) = mSettings(m, mSetting);

    // copying realized t
    r_info_t_realized(t_startp(t))${ sum(f, ft_realizedNoReset(f, t)) } = yes;


* --- Diagnostic Results ------------------------------------------------------

// Only include these if '--diag=yes' given as a command line argument
$iftheni.diag '%diag%' == yes
// Estimated coefficients of performance
d_cop(unit, ft_realizedNoReset(f, t_startp(t)))$sum(gnu_input(grid, node, unit), 1)
    = sum(gnu_output(grid, node, unit),
        + r_gen_gnuft(grid, node, unit, f, t)
        ) // END sum(gnu_output)
        / [ sum(gnu_input(grid_, node_, unit),
                -r_gen_gnuft(grid_, node_, unit, f, t)
                ) // END sum(gnu_input)
            + 1${not sum(gnu_input(grid_, node_, unit), -r_gen_gnuft(grid_, node_, unit, f, t))}
            ]
        + Eps; // Eps to correct GAMS plotting (zeroes are not skipped)

// Estimated efficiency, calculated from inputs
d_eff(unit(unit), ft_realizedNoReset(f, t))$[ord(t) > mSettings(m, 't_start') + mSettings(m, 't_initializationPeriod')]
    = sum(gnu_output(grid, node, unit),
        + r_gen_gnuft(grid, node, unit, f, t)
        ) // END sum(gnu_output)
        / [ sum(gnu_input(grid, node, unit),
                + abs(r_gen_gnuft(grid, node, unit, f, t))
                ) // END sum(gnu_input)
            + 1${not sum(gnu_input(grid, node, unit), abs(r_gen_gnuft(grid, node, unit, f, t)))}
            ]
        + Eps; // Eps to correct GAMS plotting (zeroes are not skipped)
$endif.diag

); // END loop(m)

