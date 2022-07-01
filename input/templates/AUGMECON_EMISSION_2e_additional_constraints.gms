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

* scalar/parameter definitions should be in 1c_parameters.gms
* equation declaration should be in 2b_eqDeclarations.gms

equations
          q_epsEmissionCap "Emission Cap for AUGMECON (tCO2)"
;


* --- Constraints -------------------------------------------------------------

q_epsEmissionCap(group, emission)
    ${  p_groupPolicyEmission(group, 'emissionCap', emission)
        } ..

    + sum(msft(m, s, f, t)${sGroup(s, group)},
        + p_msft_Probability(m,s,f,t)
        * [
            // Time step length dependent emissions - calculated from consumption
            + p_stepLength(m, f, t)
                * sum(gnu_input(grid, node, unit)${gnGroup(grid, node, group) and p_nEmission(node, emission)},
                    - v_gen(grid, node, unit, s, f, t) // multiply by -1 because consumption is negative
                        * p_nEmission(node, emission) // kg/MWh
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
                * sum(nu(node, unit)${p_nEmission(node, emission)},
                    + p_unStartup(unit, node, starttype) // MWh/start-up
                        * p_nEmission(node, emission) // kg/MWh
                        / 1e3 // NOTE!!! Conversion to t/MWh from kg/MWh in data
                    ) // END sum(nu, emission)
              ) // sum(uft_online)
          ] // END * p_sft_Probability
      ) // END sum(msft)

    + v_epsSlack // add positive slack variable for AUGMECON
 
    =E= // change from <= to = for AUGMECON

    // Permitted nodal emission cap
    + p_groupPolicyEmission(group, 'emissionCap', emission)
;


