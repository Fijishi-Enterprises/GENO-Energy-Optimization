* ===============================================================================
* --- eqDeclarations - Declaration of additional equations
* ===============================================================================

Equations
//General comments: s is the set for samples (only one sample in use here), f is the forecast used (deterministic model, so
//only one forecast f00), t is the time stamp
//node is aliased with node_ to indicate the relation to another related node
// Equation numbers correspond to numbers in the manuscript in Overleaf

//Switching function between locally valid linearisation parameters in order to obtain a globally valid wastewater treatment plant model
//The linearisation parameters change according to the level of water inflow into the plant
//Eq. 45 and 47
q_ww_lowerLimit(grid, node, unit, ww_flowType, ww_range, s, f, t)  "Activates v_flagGen if flow is bigger than the lower limit of the flow range"
//Eq. 46 and 48
q_ww_upperLimit(grid, node, unit, ww_flowType, ww_range, s, f, t)  "Activates v_flagGen if flow is smaller than the upper limit of the flow range"
//Eq. 35,36
q_ww_flowSum(ww_flowType, s , f, t)                                 "Exactly one of the binary variables for each flow range has to equal one"

//Specific balance equation for the wastewater treatment reaction nodes
//Eq. 25 (eq. 30)
q_ww_balance(grid, node, mType, s, f, t)                          "Reaction within the nodes of the wastewater reaction tank"

//Eq. 37
q_ww_flagState1(grid, node, ww_flowType, ww_range, s, f, t)       "Helper equation to limit v_flagState, the product of v_flowFlag and v_state"
//Eq. 38
q_ww_flagState2(grid, node, ww_flowType, ww_range, s, f, t)       "Helper equation to limit v_flagState, the product of v_flowFlag and v_state"
//Eq. 39
q_ww_flagState3(grid, node, ww_flowType, ww_range, s, f, t)       "Helper equation to limit v_flagState, the product of v_flowFlag and v_state"

q_ww_flagGen1(grid, node, unit, ww_flowType, ww_range, s, f, t)   "Helper equation to limit v_flagGen, the product of v_flowFlag and v_gen"
q_ww_flagGen2(grid, node, unit, ww_flowType, ww_range, s, f, t)   "Helper equation to limit v_flagGen, the product of v_flowFlag and v_gen"
q_ww_flagGen3(grid, node, unit, ww_flowType, ww_range, s, f, t)   "Helper equation to limit v_flagGen, the product of v_flowFlag and v_gen"

//Helper equations to limit the product of a binary and a continuous variable
//Eq. 37
//q_ww_flagTransfer1(grid, node, node_, ww_flowType, ww_range, s, f, t)     "Helper equation to limit v_flagTransfer, the product of v_flowFlag and v_transfer"
//Eq. 38
//q_ww_flagTransfer2(grid, node, node_, ww_flowType, ww_range, s, f, t)     "Helper equation to limit v_flagTransfer, the product of v_flowFlag and v_transfer"
//Eq. 39
//q_ww_flagTransfer3(grid, node, node_, ww_flowType, ww_range, s, f, t)     "Helper equation to limit v_flagTransfer, the product of v_flowFlag and v_transfer"

;

* ===============================================================================
* --- constraints - Formulation of additional equations
* ===============================================================================

*------Switching function for linearisation parameters--------------------------

*------ Limits for switching function ------------------------------------------
//Equations 45-48 in the manuscript
q_ww_lowerLimit(gnu(grid, node, unit), ww_flowRange(ww_flowType, ww_range), sft(s, f, t))
         ${gnuGroup(grid, node, unit,'ww_inflowNode')}
..

         v_flagGen(grid, node, unit, ww_flowType, ww_range, s, f, t)

         =G=

         p_ww_threshold(ww_flowType, ww_range, 'lower')* v_flowFlag(ww_flowType, ww_range, s, f, t)

;

q_ww_upperLimit(gnu(grid, node, unit), ww_flowRange(ww_flowType, ww_range), sft(s, f, t))
         ${gnuGroup(grid, node, unit,'ww_inflowNode')}//should only hold for inflow node and DO reaction ..
..

         v_flagGen(grid, node, unit, ww_flowType, ww_range, s, f, t)

         =L=

         p_ww_threshold(ww_flowType, ww_range, 'upper')* v_flowFlag(ww_flowType, ww_range, s, f, t)

;
//Equation 35(36) in manuscript
q_ww_flowSum(ww_flowType, sft(s , f, t))    //Ensures that v_flowFlag is one ONLY for one element in ww_range
..
         sum(ww_range, v_flowFlag(ww_flowType, ww_range, s, f, t)) =E= 1

;

*------New balance equation for wastewater reaction nodes-----------------------
//This corresponds to eq. 25 and eq. 30

q_ww_balance(gn(grid, node), msft(m, s, f, t))
    ${  not p_gn(grid, node, 'boundAll')
        and gnGroup(grid, node, 'ww_reactionGroup')}
..

    // The left side of the equation is the change in the state (will be zero if the node doesn't have a state)
    + p_gn(grid, node, 'energyStoredPerUnitOfState')${gn_state(grid, node)} // Unit conversion between v_state of a particular node and
                                                                            // energy variables (defaults to 1, but can have node based values
                                                                            // if e.g. v_state is in Kelvins and each node has a different heat storage capacity)
        * [
            v_state(grid, node, s, f+df_central(f,t), t)   // The difference between current
            - v_state(grid, node, s+ds_state(grid,node,s,t), f+df(f,t+dt(t)), t+dt(t))// ... and previous state of the node
         ]
    =E=
//    + p_stepLength(m, f, t) * (
            // Self discharge out of the model boundaries
            - p_gn(grid, node, 'selfDischargeLoss')${ gn_state(grid, node) }
                * v_state(grid, node, s, f+df_central(f,t), t) // The current state of the node

            // Energy diffusion from this node to neighbouring nodes
            // in the WWTP model, this is the influence of this node's concentration on the other node's concentration
            - sum(gnn_state(grid, node, to_node),
                + [p_gnn(grid, node, to_node, 'diffCoeff_out')
                     * sum(ww_flowType,
                         sum(ww_range,
                             + p_ww_A(ww_flowType, ww_range, node, to_node, 'diff_out')
                             * p_ww_dilution(ww_flowType, ww_range, node, to_node)
                             * v_flagState(grid, node, ww_flowType, ww_range, s, f+df_central(f,t), t)
                          )
                       )//END sum(ww_flowType)
                  ]
                ) // END sum(to_node)

            // Energy diffusion from neighbouring nodes to this node
            // in the WWTP model, this is the influence of the other node's concentration on the node's concentration
            + sum(gnn_state(grid, from_node, node),
                + [p_gnn(grid, from_node, node, 'diffCoeff_in')
                     * sum(ww_flowType,
                         sum(ww_range,
                             + p_ww_A(ww_flowType, ww_range, from_node, node, 'diff_in')
                             * p_ww_dilution(ww_flowType, ww_range, from_node, node)
                             * v_flagState(grid, from_node, ww_flowType, ww_range, s, f+df_central(f,t), t)
                          )
                       )//END sum(ww_flowType)
                  ]
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
                  sum(ww_flowType,
                         sum(ww_range,
                             + p_ww_dilutionUnit(ww_flowType, ww_range, node, unit)
                             * v_flagGen(grid, node, unit, ww_flowType, ww_range, s, f, t) // Unit energy generation and consumption
                         )
                  )
              ) // END sum(gnuft)

            // Decay and recycle of X
            - sum(gnn_state(grid, node, to_node),
                + [p_gnn(grid, node, to_node, 'decay')
                * v_state(grid, node, s, f, t)
                ]
              )

            + sum(gnn_state(grid, from_node, node),
                + [p_gnn(grid, from_node, node, 'recycle')
                * v_state(grid, from_node, s, f, t)
                ]
              )

            // Power inflow and outflow timeseries to/from the node
            + ts_influx_(grid, node, s, f, t)   // Incoming (positive) and outgoing (negative) absolute value time series

            // Dummy generation variables, for feasibility purposes
//            + vq_gen('increase', grid, node, s, f, t) // Note! When stateSlack is permitted, have to take caution with the penalties so that it will be used first
//            - vq_gen('decrease', grid, node, s, f, t) // Note! When stateSlack is permitted, have to take caution with the penalties so that it will be used first
//    ) // END * p_stepLength
;
*------- Helper Constraints for the products of continuous variables and the binary v_flowFlag ---------

*------------ Constraints for binding the product of v_state and v_flowFlag ---------
//Eq. 37
q_ww_flagState1(gn(grid, node), ww_flowRange(ww_flowType, ww_range), sft(s, f, t))
                 ${ gnGroup(grid, node, 'ww_flagState')}
..

         v_flowFlag(ww_flowType, ww_range, s, f, t) * BIG_M

         =G=

         v_flagState(grid, node, ww_flowType, ww_range, s, f+df_central(f,t), t)
;
//Eq. 38
q_ww_flagState2(gn(grid, node), ww_flowRange(ww_flowType, ww_range), sft(s, f, t))
                 ${ gnGroup(grid, node, 'ww_flagState')}
..

         v_state(grid, node, s, f+df_central(f,t), t)

         =G=

         v_flagState(grid, node, ww_flowType, ww_range, s, f+df_central(f,t), t)

;
//Eq. 39
//(Eq. 40 being implied by v_flagState defined as a positive variable)
q_ww_flagState3(gn(grid, node), ww_flowRange(ww_flowType, ww_range), sft(s, f, t))
                 ${ gnGroup(grid, node, 'ww_flagState')}
..

         v_flagState(grid, node, ww_flowType, ww_range, s, f+df_central(f,t), t)

         =G=

         v_state(grid, node, s, f+df_central(f,t), t) - [(1-v_flowFlag(ww_flowType, ww_range, s, f, t)) * BIG_M]
;
*------------ Constraints for binding the product of v_gen and v_flowFlag ---------
//Eq. 37
q_ww_flagGen1(gnu(grid, node, unit), ww_flowRange(ww_flowType, ww_range), sft(s, f, t))
                 ${ gnuGroup(grid, node, unit, 'ww_flagGen')}
..

         v_flowFlag(ww_flowType, ww_range, s, f, t) * BIG_M

         =G=

         v_flagGen(grid, node, unit, ww_flowType, ww_range, s, f, t)
;
//Eq. 38
q_ww_flagGen2(gnu(grid, node, unit), ww_flowRange(ww_flowType, ww_range), sft(s, f, t))
                 ${ gnuGroup(grid, node, unit, 'ww_flagGen')}
..

         v_gen(grid, node, unit, s, f, t)

         =G=

         v_flagGen(grid, node, unit, ww_flowType, ww_range, s, f, t)

;
//Eq. 39
//(Eq. 40 being implied by v_flagState defined as a positive variable)
q_ww_flagGen3(gnu(grid, node, unit), ww_flowRange(ww_flowType, ww_range), sft(s, f, t))
                 ${ gnuGroup(grid, node, unit, 'ww_flagGen')}
..

         v_flagGen(grid, node, unit, ww_flowType, ww_range, s, f, t)

         =G=

         v_gen(grid, node, unit, s, f, t) - [(1-v_flowFlag(ww_flowType, ww_range, s, f, t)) * BIG_M]
;

$ontext
*------------- Constraints for binding the product of v_transfer and v_flowFlag ------------------------
//Eq. 37
q_ww_flagTransfer1(gn2n_directional(grid, node, node_), ww_flowRange(ww_flowType, ww_range), sft(s, f, t))
         ${gn2nGroup(grid, node, node_,'ww_flagTransfer')}
..

         BIG_M * v_flowFlag(ww_flowType, ww_range, s, f, t)

         =G=

         v_flagTransfer(grid, node, node_, ww_flowType, ww_range, s, f, t)

;
//Eq. 38
q_ww_flagTransfer2(gn2n_directional(grid, node, node_), ww_flowRange(ww_flowType, ww_range), sft(s, f, t))
         ${gn2nGroup(grid, node, node_,'ww_flagTransfer')}
..

         v_transfer(grid, node, node_, s, f, t)

         =G=

         v_flagTransfer(grid, node, node_, ww_flowType, ww_range, s, f, t)
;
//Eq. 39
//(Eq. 40 being implied by v_flagTransfer defined as a positive variable)
q_ww_flagTransfer3(gn2n_directional(grid, node, node_), ww_flowRange(ww_flowType, ww_range), sft(s, f, t))
         ${gn2nGroup(grid, node, node_,'ww_flagTransfer')}
..

         v_flagTransfer(grid, node, node_, ww_flowType, ww_range, s, f, t)

         =G=

         v_transfer(grid, node, node_, s, f, t) - ((1- v_flowFlag(ww_flowType, ww_range, s, f, t))* BIG_M)
;
$offtext
