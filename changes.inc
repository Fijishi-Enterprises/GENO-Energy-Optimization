*-------------Additional sets---------------------------------------------------
//Base sets
Sets

ww_range                               "Possible ranges for linearization parameters in waste water treatment model"
     /low, mid, high/
ww_flowType                            "Possible types of flows for ranges in waste water treatment model"
     /inflow, airflow/
ww_lowerUpper                          "Lower or upper threshold for ranges in waste water treatment model"
     /lower, upper/

ww_A                                   "Matrix A of parameters which need to be linearized for the wastewater treatment model for different inflow and airflow ranges"
    /A1, A2, A3/
ww_dilution                            "Dilution factors D in the waste water treatment model for different inflow ranges"
    /D/
;

alias(ww_flowType, ww_flowType_);
alias(ww_range, ww_range_);

//Aggregate sets and subsets
Sets

ww_in(ww_flowType)
     /inflow/
ww_air(ww_flowType)
     /airflow/

ww_flowRange(ww_flowType, ww_range)                                       "Ranges of flow in which linearization parameters are valid (e.g. low,mid,high)"
ww_flowRangeflowRange(ww_in, ww_range, ww_air, ww_range_)                 "All possible combinations of flow ranges"
;

ww_flowRange(ww_flowType, ww_range) = yes;
ww_flowRangeflowRange(ww_in, ww_range, ww_air, ww_range_) = yes;

*-----------Additional parameters-----------------------------------------------

Parameters

p_ww_threshold(ww_flowType, ww_range, ww_lowerUpper)                          "Lower and upper thresholds for flow ranges"
p_ww_A(ww_in, ww_range, ww_air, ww_range_, ww_A)                              "Linearization parameters A for the wastewater treatment model"
p_ww_dilution(ww_flowType, ww_range, ww_dilution)                             "Dilution factor D for the waste water treatment model"

;

*---------------------Additional variables--------------------------------------

Binary variables
         v_flowFlag(ww_flowType, ww_range, s, f, t)                             "Flag for the respective flow range [one if inflow lies within respective range]"
         v_flowHelper(ww_in, ww_range, ww_air, ww_range_, s, f, t)              "Helper flag representing the product of the inflow flag and the airflow flag"
;

Free variables
         v_flowState(grid, node, ww_in, ww_range, ww_air, ww_range_, s, f, t)   "The product of the state variable of the node and the binary v_flowHelper"
;

*-------------Additional input data - not necessary when running Backbone from titan------
$ontext
$ifthen exist '%input_dir%/inputData_ext.gdx'
$$gdxin  '%input_dir%/inputData_ext.gdx'
    $$loaddcm grid
    $$loaddcm node
    $$loaddcm flow
    $$loaddcm unittype
    $$loaddcm unit
    $$loaddcm unitUnittype
    $$loaddcm unit_fail
    $$loaddcm commodity
    $$loaddcm unitUnitEffLevel
    $$loaddcm effLevelGroupUnit
    $$loaddcm group
    $$loaddcm p_gn
    $$loaddc p_ww_lin_threshold
    $$loaddc p_ww_lin
    $$loaddc p_ww_dilution
    $$loaddc p_gnn
    $$loaddcm p_gnu_io
    $$loaddcm p_gnuBoundaryProperties
    $$loaddcm p_unit
    $$loaddcm p_unitConstraint
    $$loaddcm p_unitConstraintNode
    $$loaddcm ts_unit
    $$loaddcm restype
    $$loaddcm restypeDirection
    $$loaddcm restypeReleasedForRealization
    $$loaddcm restype_inertia
    $$loaddcm p_groupReserves
    $$loaddcm p_groupReserves3D
    $$loaddcm p_groupReserves4D
    $$loaddcm p_gnuReserves
    $$loaddcm p_gnnReserves
    $$loaddcm p_gnuRes2Res
    $$loaddcm ts_reserveDemand
    $$loaddcm p_gnBoundaryPropertiesForStates
    $$loaddcm p_gnPolicy
    $$loaddcm p_uStartupfuel
    $$loaddcm flowUnit
    $$loaddcm emission
    $$loaddcm p_nEmission
    $$loaddcm ts_cf
    $$loaddcm p_price // Disabled for convenience, see line 278-> ("Determine Fuel Price Representation")
    $$loaddcm ts_priceChange
    $$loaddcm ts_influx
    $$loaddcm ts_node
    $$loaddcm t_invest
    $$loaddcm p_storageValue
    $$loaddcm uGroup
    $$loaddcm gnuGroup
    $$loaddcm gn2nGroup
    $$loaddcm gnGroup
    $$loaddcm p_groupPolicy
    $$loaddcm p_groupPolicy3D
    $$loaddcm gnss_bound
    $$loaddcm uss_bound
$$gdxin
$endif
$offtext

