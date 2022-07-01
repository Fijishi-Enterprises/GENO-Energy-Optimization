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
          q_epsGenCap "Generation Cap for uGroups for AUGMECON (MWh)"
;


scalars
          maxTotalGeneration "Upper limit on total generation from uGroups (MWh)"
;

$If set maxTotalGeneration maxTotalGeneration=%maxTotalGeneration%;
$If not set maxTotalGeneration maxTotalGeneration = inf;

* --- Constraints -------------------------------------------------------------

q_epsGenCap
    ${  %maxTotalGeneration%
        } ..

+ sum(msft(m, s, f, t),
        // Probability (weight coefficient) of (s,f,t)
        + p_msft_probability(m, s, f, t)
            * [
                // Time step length dependent costs 
                + p_stepLength(m, f, t)                                         // length of time interval (h)
                    * [

                        sum(group$p_groupPolicy(group, 'objectiveWeight'),  // sum over groups, for which "objectiveWeight" is defined

                        + p_groupPolicy(group, 'objectiveWeight')
                            * [


                             // generation from inputs
                               - sum(gnuft(grid, node, unit, f, t)${ gnu_input(grid, node, unit)
                                                                and uGroup(unit, group)
                                                                },  
                               + v_gen(grid, node, unit, s, f, t)                  // energy generation in interval (MW)
                            
                                ) // END sum(gnuft)

                            // generation from outputs
                            //+ sum(gnuft(grid, node, unit, f, t)${ gnu_output(grid, node, unit)
                            //                                      and uGroup(unit, group)
                            //                                      },
                            //    + v_gen(grid, node, unit, s, f, t)
                            //       
                            //    ) // END sum(gnuft)

                        ] // END * p_stepLength             

                ]                                                               // END * p_msft_probability(m,s,f,t)
        )                                                                       // END sum over msft(m, s, f, t)


    + v_epsSlack // add positive slack variable for AUGMECON
 
    =E= // change from <= to = for AUGMECON

    // Permitted generation cap
    + maxTotalGeneration

;


