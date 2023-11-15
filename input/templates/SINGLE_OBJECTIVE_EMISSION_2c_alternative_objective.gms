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

q_obj ..

    + v_obj

    =E=

    + sum(msft(m, s, f, t)${sGroup(s, 'emissionObjectiveGroup')},
        + p_msft_Probability(m,s,f,t)
        * [
            // Time step length dependent emissions

            // Emissions from operation: consumption and production of fuels - gn related emissions (tEmission)
            // if consumption -> emissions, if production -> emission reductions due to emissions bound to product
            + p_stepLength(m, f, t)
                * sum(gnu(grid, node, unit)${gnGroup(grid, node, 'emissionObjectiveGroup')
                                             and p_nEmission(node, 'CO2')
                                             and usft(unit, s, f, t) },
                    - v_gen(grid, node, unit, s, f, t) // multiply by -1 because consumption is negative and production positive
                        * p_nEmission(node, 'CO2') // tEmission/MWh
                  ) // END sum(gnu_input)

            // Emissions from operation: gnu related vomEmissions (tEmission)
            // emissions from input and output are both calculated as emissions
            + p_stepLength(m, f, t)
                * sum(gnu_input(grid, node, unit)${gnGroup(grid, node, 'emissionObjectiveGroup')
                                                   and p_gnuEmission(grid, node, unit, 'CO2', 'vomEmissions')
                                                   and usft(unit, s, f, t) },
                    - v_gen(grid, node, unit, s, f, t) // multiply by -1 because consumption is negative
                        * p_gnuEmission(grid, node, unit, 'CO2', 'vomEmissions') // tEmission/MWh
                  ) // END sum(gnu_input)
            + p_stepLength(m, f, t)
                * sum(gnu_output(grid, node, unit)${gnGroup(grid, node, 'emissionObjectiveGroup')
                                                    and p_gnuEmission(grid, node, unit, 'CO2', 'vomEmissions')
                                                    and usft(unit, s, f, t) },
                    + v_gen(grid, node, unit, s, f, t)
                        * p_gnuEmission(grid, node, unit, 'CO2', 'vomEmissions') // tEmission/MWh
                  ) // END sum(gnu_input)

            // Emissions from operation: Start-up emissions (tEmission)
            + sum((usft_online(unit, s, f, t), starttype)$[unitStarttype(unit, starttype) and p_uStartup(unit, starttype, 'consumption')],
                + [
                    + v_startup_LP(starttype, unit, s, f, t)
                        ${ usft_onlineLP(unit, s, f, t) }
                    + v_startup_MIP(starttype, unit, s, f, t)
                        ${ usft_onlineMIP(unit, s, f, t) }
                  ]
                * [
                   // node specific emissions
                   +sum(nu_startup(node, unit)${sum(grid, gnGroup(grid, node, 'emissionObjectiveGroup')) and p_nEmission(node, 'CO2')},
                      + p_unStartup(unit, node, starttype) // MWh/start-up
                          * p_nEmission(node, 'CO2') // t/MWh
                    ) // END sum(nu, 'CO2')
                  ]
              ) // sum(usft_online)

          ] // END * p_msft_Probability
      ) // END sum(msft)


    + sum(ms(m, s)${ sum(msft(m, s, f, t), 1) and sGroup(s, 'emissionObjectiveGroup') }, // consider ms only if it has active msft and belongs to group
        + p_msAnnuityWeight(m, s) // Sample weighting to calculate annual emissions
        * [
            // capacity emissions: fixed o&M emissions (tEmission)
            + sum(gnu(grid, node, unit)${p_gnuEmission(grid, node, unit, 'CO2', 'fomEmissions')
                                         and sum(msft(m, s, f, t), usft(unit, s, f, t)) // consider unit only if it is active in the sample
                                         and gnGroup(grid, node, 'emissionObjectiveGroup') },
                + p_gnuEmission(grid, node, unit, 'CO2', 'fomEmissions')       // (tEmissions/MW)
                    * p_gnu(grid, node, unit, 'unitSize')   // (MW/unit)
                    * [
                        // Existing capacity
                        + p_unit(unit, 'unitCount')         // (number of existing units)

                        // Investments to new capacity
                        + v_invest_LP(unit)${unit_investLP(unit)}        // (number of invested units)
                        + v_invest_MIP(unit)${unit_investMIP(unit)}      // (number of invested units)
                      ] // END * p_gnuEmssion
                ) // END sum(gnu)

            // capacity emissions: investment emissions (tEmission)
            + sum(gnu(grid, node, unit)${p_gnuEmission(grid, node, unit, 'CO2', 'invEmissions')
                                         and (unit_investLP(unit) or unit_investMIP(unit))
                                         and sum(msft(m, s, f, t), usft(unit, s, f, t)) // consider unit only if it is active in the sample
                                         and gnGroup(grid, node, 'emissionObjectiveGroup') },
                // Capacity restriction
                + p_gnuEmission(grid, node, unit, 'CO2', 'invEmissions')    // (tEmission/MW)
                    * p_gnuEmission(grid, node, unit, 'CO2', 'invEmissionsFactor')    // factor dividing emissions to N years
                    * p_gnu(grid, node, unit, 'unitSize')     // (MW/unit)
                    * [
                        // Investments to new capacity
                        + v_invest_LP(unit)${unit_investLP(unit)}         // (number of invested units)
                        + v_invest_MIP(unit)${unit_investMIP(unit)}       // (number of invested units)
                      ] // END * p_gnuEmssion
                ) // END sum(gnu)
          ] // END * p_msProbability
      ) // END sum(ms)

;
