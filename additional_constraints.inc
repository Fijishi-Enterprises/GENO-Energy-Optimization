* ===============================================================================
* --- eqDeclarations - Declaration of additional equations
* ===============================================================================

Equations
//Switching function between locally valid linearisation parameters in order to obtain a globally valid wastewater treatment plant model
q_lowerLimit_flag(ww_flowType, ww_range, s, f, t)                      "Activates the binary variable if flow is bigger than the lower limit of the flow range"
q_lowerLimit_flow(grid, node, ww_flowType, ww_range, s, f, t)          "Activates the binary variable if flow is bigger than the lower limit of the flow range"
q_upperLimit_flag(ww_flowType, ww_range, s, f, t)                      "Activates the binary variable if flow is smaller than the upper limit of the flow range"
q_upperLimit_flow(grid, node, ww_flowType, ww_range, s, f, t)          "Activates the binary variable if flow is smaller than the upper limit of the flow range"

q_flowSum(ww_flowType, s , f, t)                                       "Exactly one of the binary variables for each flow range has to equal one"

//Specific balance equation for the wastewater treatment reaction nodes
q_ww_balance(grid, node, mType, s, f, t)                                  "Reaction within the nodes of the wastewater reaction tank"
q_ww_help1(ww_flowType, ww_in, ww_range, ww_air, ww_range_, s, f, t)      "Helper equation to express the product of the two binary variables for inflow and airflow"
q_ww_help2(ww_in, ww_range, ww_air, ww_range_, s, f, t)                   "Helper equation to express the product of the two binary variables for inflow and airflow"
q_ww_help3(grid, node, ww_in, ww_range, ww_air, ww_range_, s, f, t)
q_ww_help4(grid, node, ww_in, ww_range, ww_air, ww_range_, s, f, t)
q_ww_help5(grid, node, ww_in, ww_range, ww_air, ww_range_, s, f, t)
;

* ===============================================================================
* --- constraints - Formulation of additional equations
* ===============================================================================

*------Switching function for linearisation parameters----------

q_lowerLimit_flag(ww_flowRange(ww_flowType, ww_range), sft(s, f, t))
..

         BIG_M * v_flowFlag(ww_flowType, ww_range, s, f, t)

         =G=

         p_ww_threshold(ww_flowType, ww_range, 'lower') * v_flowFlag(ww_flowType, ww_range, s, f, t)

//this is non-binding if the flow is greater than the lower bound and both sides are zero if the flow is below the lower bound
;

q_lowerLimit_flow(gn(grid, node), ww_flowRange(ww_flowType, ww_range), sft(s, f, t))$(gn2n_directional(grid, 'Inlet_Q', 'Q_reaction') and gnu(grid, 'DO_reaction', 'Blower'))//should only hold for q nodes and blower ..
..
         v_transfer(grid, 'Inlet_Q', node, s, f, t) + v_gen(grid, node, 'Blower', s, f, t)
         + BIG_M * (1 - v_flowFlag(ww_flowType, ww_range, s, f, t))

         =G=

         p_ww_threshold(ww_flowType, ww_range, 'lower') * v_flowFlag(ww_flowType, ww_range, s, f, t)

;

q_upperLimit_flag(ww_flowRange(ww_flowType, ww_range), sft(s, f, t))
..

         BIG_M * v_flowFlag(ww_flowType, ww_range, s, f, t)

         =G=

         - p_ww_threshold(ww_flowType, ww_range, 'upper') * v_flowFlag(ww_flowType, ww_range, s, f, t)

;

q_upperLimit_flow(gn(grid, node), ww_flowRange(ww_flowType, ww_range), sft(s, f, t))$(gn2n_directional(grid, 'Inlet_Q', 'Q_reaction') and gnu(grid, 'DO_reaction', 'Blower'))//it should only hold for the q nodes and blower ..
..
         - v_transfer(grid, 'Inlet_Q', node, s, f, t) - v_gen(grid, node, 'Blower', s, f, t)
         + BIG_M * (1 - v_flowFlag(ww_flowType, ww_range, s, f, t))

         =G=

         - p_ww_threshold(ww_flowType, ww_range, 'upper') * v_flowFlag(ww_flowType, ww_range, s, f, t)

;

q_flowSum(ww_flowType, sft(s , f, t))    //Ensures that v_flowFlag is one ONLY for one element in ww_range
..
         sum(ww_range, v_flowFlag(ww_flowType, ww_range, s, f, t)) =E= 1

;

*------New balance equation for wastewater reaction nodes----------

q_ww_balance(gn(grid, node), msft(m, s, f, t))${ gnGroup(grid, node, 'ww_reactionGroup')}
..

    // The left side of the equation is the change in the state (will be zero if the node doesn't have a state)
    + p_gn(grid, node, 'energyStoredPerUnitOfState')${gn_state(grid, node)} // Unit conversion between v_state of a particular node and energy variables (defaults to 1, but can have node based values if e.g. v_state is in Kelvins and each node has a different heat storage capacity)
        * [
            + v_state(grid, node, s, f+df_central(f,t), t)                   // The difference between current
            - v_state(grid, node, s+ds_state(grid,node,s,t), f+df(f,t+dt(t)), t+dt(t))       // ... and previous state of the node
            ]

    =E=

    // The right side of the equation contains all the changes converted to energy terms
    + p_stepLength(m, f, t) // Multiply with the length of the timestep to convert power into energy
        * (
            // Energy diffusion from this node to neighbouring nodes
            - sum(gnn_state(grid, node, to_node),
                + [p_gnn(grid, node, to_node, 'diffCoeff')
                     * sum(ww_flowType,
                          sum(ww_range,
                             sum(ww_flowType_,
                                 sum(ww_range_,
                             + p_ww_A(ww_flowType, ww_range, ww_flowType_, ww_range_, 'A1')$gn2n_directional(grid, node, 'DO_reaction')
                             + p_ww_A(ww_flowType, ww_range, ww_flowType_, ww_range_, 'A2')$gn2n_directional(grid, node, 'S_reaction')
                             + p_ww_A(ww_flowType, ww_range, ww_flowType_, ww_range_, 'A3')$gn2n_directional(grid, node, 'X_reaction')
                               * v_flowState(grid, node, ww_range, ww_range_, s, f+df_central(f,t), t)
                                 )
                             )
                          )
                       )
                  ]//END sum(ww_flowType)
              ) // END sum(to_node)

            // Energy diffusion from neighbouring nodes to this node
            + sum(gnn_state(grid, from_node, node),
                + [p_gnn(grid, from_node, node, 'diffCoeff')
                     * sum(ww_flowType,
                          sum(ww_range,
                             sum(ww_flowType_,
                                 sum(ww_range_,
                             + p_ww_A(ww_flowType, ww_range, ww_flowType_, ww_range_, 'A1')$gn2n_directional(grid, node, 'DO_reaction')
                             + p_ww_A(ww_flowType, ww_range, ww_flowType_, ww_range_, 'A2')$gn2n_directional(grid, node, 'S_reaction')
                             + p_ww_A(ww_flowType, ww_range, ww_flowType_, ww_range_, 'A3')$gn2n_directional(grid, node, 'X_reaction')
                               * v_flowState(grid, node, ww_range, ww_range_, s, f+df_central(f,t), t)
                                 )
                             )
                          )
                       )// Incoming diffusion based on the state of the neighbouring node
                  ]//END sum(ww_flowType)
                ) // END sum(from_node)

            // Controlled energy transfer, applies when the current node is on the left side of the connection
            - sum(gn2n_directional(grid, node, node_),
                + (1 - p_gnn(grid, node, node_, 'transferLoss')) // Reduce transfer losses
                    * v_transfer(grid, node, node_, s, f, t)
                + p_gnn(grid, node, node_, 'transferLoss') // Add transfer losses back if transfer is from this node to another node
                    * v_transferRightward(grid, node, node_, s, f, t)
                ) // END sum(node_)

            // Controlled energy transfer, applies when the current node is on the right side of the connection
            + sum(gn2n_directional(grid, node_, node),
                + v_transfer(grid, node_, node, s, f, t)
                - p_gnn(grid, node_, node, 'transferLoss') // Reduce transfer losses if transfer is from another node to this node
                    * v_transferRightward(grid, node_, node, s, f, t)
                ) // END sum(node_)

            // Interactions between the node and its units
            + sum(gnuft(grid, node, unit, f, t),
                + v_gen(grid, node, unit, s, f, t) // Unit energy generation and consumption
                )
    ) // END * p_stepLength
;
*------- Helper Constraints for the new balance equation ---------------

q_ww_help1(ww_flowType, ww_flowRangeflowRange(ww_in, ww_range, ww_air, ww_range_), sft(s, f, t))
..

         v_flowFlag(ww_flowType, ww_range, s, f, t)

         =G=

         v_flowHelper(ww_in, ww_range, ww_air, ww_range_, s, f, t)

;

q_ww_help2(ww_flowRangeflowRange(ww_in, ww_range, ww_air, ww_range_), sft(s, f, t))
..

         v_flowHelper(ww_in, ww_range, ww_air, ww_range_, s, f, t)

         =G=

         sum(ww_flowType, v_flowFlag(ww_flowType, ww_range, s, f, t)) - 1

;

q_ww_help3(gn(grid, node), ww_flowRangeflowRange(ww_in, ww_range, ww_air, ww_range_), sft(s, f, t))${ gnGroup(grid, node, 'ww_reactionGroup')}
..

         v_flowHelper(ww_in, ww_range, ww_air, ww_range_, s, f, t) * BIG_M

         =G=

         v_flowState(grid, node, ww_in, ww_range, ww_air, ww_range_, s, f, t)
;

q_ww_help4(gn(grid, node), ww_flowRangeflowRange(ww_in, ww_range, ww_air, ww_range_), sft(s, f, t))${ gnGroup(grid, node, 'ww_reactionGroup')}
..

         v_state(grid, node, s, f, t)

         =G=

         v_flowState(grid, node, ww_in, ww_range, ww_air, ww_range_, s, f, t)

;

q_ww_help5(gn(grid, node), ww_flowRangeflowRange(ww_in, ww_range, ww_air, ww_range_), sft(s, f, t))${ gnGroup(grid, node, 'ww_reactionGroup')}
..

         v_flowState(grid, node, ww_in, ww_range, ww_air, ww_range_, s, f, t)

         =G=

         v_state(grid, node, s, f, t) - [(1-v_flowHelper(ww_in, ww_range, ww_air, ww_range_, s, f, t)) * BIG_M]
;






$ontext //this part of the code is moved to the respective parts of Backbone
* ===============================================================================
* --- 3b_periodicLoop - Initialize variables and equations in order to save memory -
* ===============================================================================

* --- Variables -----------------------------------------------------------------

// Free Variables
Option clear = v_flowState;
// Integer Variables
Option clear = v_flowFlag;
Option clear = v_flowHelper;

* --- Equations -----------------------------------------------------------------
//Switching function
Option clear = q_lowerLimit_flag;
Option clear = q_lowerLimit_flow;
Option clear = q_upperLimit_flag;
Option clear = q_upperLimit_flow;
Option clear = q_flowSum;

//Specific balance equation for the wastewater treatment reaction nodes
Option clear = q_ww_balance;

//Helper constraints for the binary variables
Option clear = q_ww_help1;
Option clear = q_ww_help2;
Option clear = q_ww_help3;
Option clear = q_ww_help4;
Option clear = q_ww_help5;

* =============================================================================
* --- Variable limits ---------------------------------------------------------
* =============================================================================

v_flowState.lo(grid, node, ww_range, ww_range_, s, f, t) = 0; //v_flowState has zero as a lower bound



$ontext //I should probably also adjust the constraint q_outputRatioFixed, but double check whether necessary...
* --- Fixed Output Ratio ------------------------------------------------------
q_outputRatioFixed(gngnu_fixedOutputRatio(grid, node, grid_, node_, unit), sft(s, f, t))
    ${  uft(unit, f, t)
        } ..

    // Generation in grid
    + v_gen(grid, node, unit, s, f, t)
        / [p_gnu(grid, node, unit, 'conversionFactor')
           + sum(ww_flowType,
               sum(ww_range, p_ww_dilution(ww_flowType, ww_range, ww_dilution)
               )
             )${ gnGroup(grid, node, 'ww_reactionGroup')}
          ]
    =E=

    // Generation in grid_
    + v_gen(grid_, node_, unit, s, f, t)
        / p_gnu(grid_, node_, unit, 'conversionFactor')
           + sum(ww_flowType,
               sum(ww_range, p_ww_dilution(ww_flowType, ww_range, ww_dilution)
               )
             )${ gnGroup(grid, node, 'ww_reactionGroup')}
          ]
;

q_lin_param_D(ww_dilution, s, f, t) ..

        v_wwD(ww_dilution, s, f, t)

        =E=

        sum(ww_flowType,
               sum(ww_range,
                   p_ww_dilution(ww_flowType, ww_range, ww_dilution)*v_flowFlag('inflow', ww_range, s, f, t)
            )
        )//the sum of all possible dilution factors multiplied by the inflow range flags.

//The selected dilution factor is the one where the respective inflow range flag is one, i.e. when the inflow lies in the respective flow range.
;
$offtext
