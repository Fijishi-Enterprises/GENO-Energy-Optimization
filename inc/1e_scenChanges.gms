* Read changes for optional scenario inputs

* Then from gdx files (separate for each set or parameter due because GAMS fails if the set or parameter is not present).
* Currently supports two levels of changes: ...2.gdx and ...3.gdx (add more if needed)
$ifthen exist '%input_dir%/grid2.gdx'
    $$gdxin '%input_dir%/grid2.gdx'
    $$loaddcm grid
    $$gdxin
$endif

$ifthen exist '%input_dir%/grid3.gdx'
    $$gdxin '%input_dir%/grid3.gdx'
    $$loaddcm grid
    $$gdxin
$endif

$ifthen exist '%input_dir%/node2.gdx'
    $$gdxin '%input_dir%/node2.gdx'
    $$loaddcm node
    $$gdxin
$endif

$ifthen exist '%input_dir%/node3.gdx'
    $$gdxin '%input_dir%/node3.gdx'
    $$loaddcm node
    $$gdxin
$endif

$ifthen exist '%input_dir%/flow2.gdx'
    $$gdxin '%input_dir%/flow2.gdx'
    $$loaddcm flow
    $$gdxin
$endif

$ifthen exist '%input_dir%/flow3.gdx'
    $$gdxin '%input_dir%/flow3.gdx'
    $$loaddcm flow
    $$gdxin
$endif

$ifthen exist '%input_dir%/unittype2.gdx'
    $$gdxin '%input_dir%/unittype2.gdx'
    $$loaddcm unittype
    $$gdxin
$endif

$ifthen exist '%input_dir%/unittype3.gdx'
    $$gdxin '%input_dir%/unittype3.gdx'
    $$loaddcm unittype
    $$gdxin
$endif

$ifthen exist '%input_dir%/unit2.gdx'
    $$gdxin '%input_dir%/unit2.gdx'
    $$loaddcm unit
    $$gdxin
$endif

$ifthen exist '%input_dir%/unit3.gdx'
    $$gdxin '%input_dir%/unit3.gdx'
    $$loaddcm unit
    $$gdxin
$endif

$ifthen exist '%input_dir%/unitUnittype2.gdx'
    $$gdxin '%input_dir%/unitUnittype2.gdx'
    $$loaddcm unitUnittype
    $$gdxin
$endif

$ifthen exist '%input_dir%/unitUnittype3.gdx'
    $$gdxin '%input_dir%/unitUnittype3.gdx'
    $$loaddcm unitUnittype
    $$gdxin
$endif

$ifthen exist '%input_dir%/unit_fail2.gdx'
    $$gdxin '%input_dir%/unit_fail2.gdx'
    $$loaddcm unit_fail
    $$gdxin
$endif

$ifthen exist '%input_dir%/unit_fail3.gdx'
    $$gdxin '%input_dir%/unit_fail3.gdx'
    $$loaddcm unit_fail
    $$gdxin
$endif

$ifthen exist '%input_dir%/fuel2.gdx'
    $$gdxin '%input_dir%/fuel2.gdx'
    $$loaddcm fuel
    $$gdxin
$endif

$ifthen exist '%input_dir%/fuel3.gdx'
    $$gdxin '%input_dir%/fuel3.gdx'
    $$loaddcm fuel
    $$gdxin
$endif

$ifthen exist '%input_dir%/unitUnitEffLevel2.gdx'
    $$gdxin '%input_dir%/unitUnitEffLevel2.gdx'
    $$loaddcm unitUnitEffLevel
    $$gdxin
$endif

$ifthen exist '%input_dir%/unitUnitEffLevel3.gdx'
    $$gdxin '%input_dir%/unitUnitEffLevel3.gdx'
    $$loaddcm unitUnitEffLevel
    $$gdxin
$endif

$ifthen exist '%input_dir%/uFuel2.gdx'
    $$gdxin '%input_dir%/uFuel2.gdx'
    $$loaddcm uFuel
    $$gdxin
$endif

$ifthen exist '%input_dir%/uFuel3.gdx'
    $$gdxin '%input_dir%/uFuel3.gdx'
    $$loaddcm uFuel
    $$gdxin
$endif

$ifthen exist '%input_dir%/effLevelGroupUnit2.gdx'
    $$gdxin '%input_dir%/effLevelGroupUnit2.gdx'
    $$loaddcm effLevelGroupUnit
    $$gdxin
$endif

$ifthen exist '%input_dir%/effLevelGroupUnit3.gdx'
    $$gdxin '%input_dir%/effLevelGroupUnit3.gdx'
    $$loaddcm effLevelGroupUnit
    $$gdxin
$endif

$ifthen exist '%input_dir%/group2.gdx'
    $$gdxin '%input_dir%/group2.gdx'
    $$loaddcm group
    $$gdxin
$endif

$ifthen exist '%input_dir%/group3.gdx'
    $$gdxin '%input_dir%/group3.gdx'
    $$loaddcm group
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_gn2.gdx'
    $$gdxin '%input_dir%/p_gn2.gdx'
    $$loaddcm p_gn
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_gn3.gdx'
    $$gdxin '%input_dir%/p_gn3.gdx'
    $$loaddcm p_gn
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_gnn2.gdx'
    $$gdxin '%input_dir%/p_gnn2.gdx'
    $$loaddcm p_gnn
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_gnn3.gdx'
    $$gdxin '%input_dir%/p_gnn3.gdx'
    $$loaddcm p_gnn
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_gnu2.gdx'
    $$gdxin '%input_dir%/p_gnu2.gdx'
    $$loaddcm p_gnu
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_gnu3.gdx'
    $$gdxin '%input_dir%/p_gnu3.gdx'
    $$loaddcm p_gnu
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_gnuBoundaryProperties2.gdx'
    $$gdxin '%input_dir%/p_gnuBoundaryProperties2.gdx'
    $$loaddcm p_gnuBoundaryProperties
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_gnuBoundaryProperties3.gdx'
    $$gdxin '%input_dir%/p_gnuBoundaryProperties3.gdx'
    $$loaddcm p_gnuBoundaryProperties
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_unit2.gdx'
    $$gdxin '%input_dir%/p_unit2.gdx'
    $$loaddcm p_unit
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_unit3.gdx'
    $$gdxin '%input_dir%/p_unit3.gdx'
    $$loaddcm p_unit
    $$gdxin
$endif

$ifthen exist '%input_dir%/ts_unit2.gdx'
    $$gdxin '%input_dir%/ts_unit2.gdx'
    $$loaddcm ts_unit
    $$gdxin
$endif

$ifthen exist '%input_dir%/ts_unit3.gdx'
    $$gdxin '%input_dir%/ts_unit3.gdx'
    $$loaddcm ts_unit
    $$gdxin
$endif

$ifthen exist '%input_dir%/restype2.gdx'
    $$gdxin '%input_dir%/restype2.gdx'
    $$loaddcm restype
    $$gdxin
$endif

$ifthen exist '%input_dir%/restype3.gdx'
    $$gdxin '%input_dir%/restype3.gdx'
    $$loaddcm restype
    $$gdxin
$endif

$ifthen exist '%input_dir%/restypeDirection2.gdx'
    $$gdxin '%input_dir%/restypeDirection2.gdx'
    $$loaddcm restypeDirection
    $$gdxin
$endif

$ifthen exist '%input_dir%/restypeDirection3.gdx'
    $$gdxin '%input_dir%/restypeDirection3.gdx'
    $$loaddcm restypeDirection
    $$gdxin
$endif

$ifthen exist '%input_dir%/restypeReleasedForRealization2.gdx'
    $$gdxin '%input_dir%/restypeReleasedForRealization2.gdx'
    $$loaddcm restypeReleasedForRealization
    $$gdxin
$endif

$ifthen exist '%input_dir%/restypeReleasedForRealization3.gdx'
    $$gdxin '%input_dir%/restypeReleasedForRealization3.gdx'
    $$loaddcm restypeReleasedForRealization
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_groupReserves2.gdx'
    $$gdxin '%input_dir%/p_groupReserves2.gdx'
    $$loaddcm p_groupReserves
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_groupReserves3.gdx'
    $$gdxin '%input_dir%/p_groupReserves3.gdx'
    $$loaddcm p_groupReserves
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_groupReserves3D2.gdx'
    $$gdxin '%input_dir%/p_groupReserves3D2.gdx'
    $$loaddcm p_groupReserves3D
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_groupReserves3D3.gdx'
    $$gdxin '%input_dir%/p_groupReserves3D3.gdx'
    $$loaddcm p_groupReserves3D
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_groupReserves4D2.gdx'
    $$gdxin '%input_dir%/p_groupReserves4D2.gdx'
    $$loaddcm p_groupReserves4D
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_groupReserves4D3.gdx'
    $$gdxin '%input_dir%/p_groupReserves4D3.gdx'
    $$loaddcm p_groupReserves4D
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_gnuReserves2.gdx'
    $$gdxin '%input_dir%/p_gnuReserves2.gdx'
    $$loaddcm p_gnuReserves
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_gnuReserves3.gdx'
    $$gdxin '%input_dir%/p_gnuReserves3.gdx'
    $$loaddcm p_gnuReserves
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_gnnReserves2.gdx'
    $$gdxin '%input_dir%/p_gnnReserves2.gdx'
    $$loaddcm p_gnnReserves
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_gnnReserves3.gdx'
    $$gdxin '%input_dir%/p_gnnReserves3.gdx'
    $$loaddcm p_gnnReserves
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_gnuRes2Res2.gdx'
    $$gdxin '%input_dir%/p_gnuRes2Res2.gdx'
    $$loaddcm p_gnuRes2Res
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_gnuRes2Res3.gdx'
    $$gdxin '%input_dir%/p_gnuRes2Res3.gdx'
    $$loaddcm p_gnuRes2Res
    $$gdxin
$endif

$ifthen exist '%input_dir%/ts_reserveDemand2.gdx'
    $$gdxin '%input_dir%/ts_reserveDemand2.gdx'
    $$loaddcm ts_reserveDemand
    $$gdxin
$endif

$ifthen exist '%input_dir%/ts_reserveDemand3.gdx'
    $$gdxin '%input_dir%/ts_reserveDemand3.gdx'
    $$loaddcm ts_reserveDemand
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_gnBoundaryPropertiesForStates2.gdx'
    $$gdxin '%input_dir%/p_gnBoundaryPropertiesForStates2.gdx'
    $$loaddcm p_gnBoundaryPropertiesForStates
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_gnBoundaryPropertiesForStates3.gdx'
    $$gdxin '%input_dir%/p_gnBoundaryPropertiesForStates3.gdx'
    $$loaddcm p_gnBoundaryPropertiesForStates
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_gnPolicy2.gdx'
    $$gdxin '%input_dir%/p_gnPolicy2.gdx'
    $$loaddcm p_gnPolicy
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_gnPolicy3.gdx'
    $$gdxin '%input_dir%/p_gnPolicy3.gdx'
    $$loaddcm p_gnPolicy
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_uFuel2.gdx'
    $$gdxin '%input_dir%/p_uFuel2.gdx'
    $$loaddcm p_uFuel
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_uFuel3.gdx'
    $$gdxin '%input_dir%/p_uFuel3.gdx'
    $$loaddcm p_uFuel
    $$gdxin
$endif

$ifthen exist '%input_dir%/flowUnit2.gdx'
    $$gdxin '%input_dir%/flowUnit2.gdx'
    $$loaddcm flowUnit
    $$gdxin
$endif

$ifthen exist '%input_dir%/flowUnit3.gdx'
    $$gdxin '%input_dir%/flowUnit3.gdx'
    $$loaddcm flowUnit
    $$gdxin
$endif

$ifthen exist '%input_dir%/gngnu_fixedOutputRatio2.gdx'
    $$gdxin '%input_dir%/gngnu_fixedOutputRatio2.gdx'
    $$loaddcm gngnu_fixedOutputRatio
    $$gdxin
$endif

$ifthen exist '%input_dir%/gngnu_fixedOutputRatio3.gdx'
    $$gdxin '%input_dir%/gngnu_fixedOutputRatio3.gdx'
    $$loaddcm gngnu_fixedOutputRatio
    $$gdxin
$endif

$ifthen exist '%input_dir%/gngnu_constrainedOutputRatio2.gdx'
    $$gdxin '%input_dir%/gngnu_constrainedOutputRatio2.gdx'
    $$loaddcm gngnu_constrainedOutputRatio
    $$gdxin
$endif

$ifthen exist '%input_dir%/gngnu_constrainedOutputRatio3.gdx'
    $$gdxin '%input_dir%/gngnu_constrainedOutputRatio3.gdx'
    $$loaddcm gngnu_constrainedOutputRatio
    $$gdxin
$endif

$ifthen exist '%input_dir%/emission2.gdx'
    $$gdxin '%input_dir%/emission2.gdx'
    $$loaddcm emission
    $$gdxin
$endif

$ifthen exist '%input_dir%/emission3.gdx'
    $$gdxin '%input_dir%/emission3.gdx'
    $$loaddcm emission
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_fuelEmission2.gdx'
    $$gdxin '%input_dir%/p_fuelEmission2.gdx'
    $$loaddcm p_fuelEmission
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_fuelEmission3.gdx'
    $$gdxin '%input_dir%/p_fuelEmission3.gdx'
    $$loaddcm p_fuelEmission
    $$gdxin
$endif

$ifthen exist '%input_dir%/ts_cf2.gdx'
    $$gdxin '%input_dir%/ts_cf2.gdx'
    $$loaddcm ts_cf
    $$gdxin
$endif

$ifthen exist '%input_dir%/ts_cf3.gdx'
    $$gdxin '%input_dir%/ts_cf3.gdx'
    $$loaddcm ts_cf
    $$gdxin
$endif

$ifthen exist '%input_dir%/ts_fuelPriceChange2.gdx'
    $$gdxin '%input_dir%/ts_fuelPriceChange2.gdx'
    $$loaddcm ts_fuelPriceChange
    $$gdxin
$endif

$ifthen exist '%input_dir%/ts_fuelPriceChange3.gdx'
    $$gdxin '%input_dir%/ts_fuelPriceChange3.gdx'
    $$loaddcm ts_fuelPriceChange
    $$gdxin
$endif

$ifthen exist '%input_dir%/ts_influx2.gdx'
    $$gdxin '%input_dir%/ts_influx2.gdx'
    $$loaddcm ts_influx
    $$gdxin
$endif

$ifthen exist '%input_dir%/ts_influx3.gdx'
    $$gdxin '%input_dir%/ts_influx3.gdx'
    $$loaddcm ts_influx
    $$gdxin
$endif

$ifthen exist '%input_dir%/ts_node2.gdx'
    $$gdxin '%input_dir%/ts_node2.gdx'
    $$loaddcm ts_node
    $$gdxin
$endif

$ifthen exist '%input_dir%/ts_node3.gdx'
    $$gdxin '%input_dir%/ts_node3.gdx'
    $$loaddcm ts_node
    $$gdxin
$endif

$ifthen exist '%input_dir%/t_invest2.gdx'
    $$gdxin '%input_dir%/t_invest2.gdx'
    $$loaddcm t_invest
    $$gdxin
$endif

$ifthen exist '%input_dir%/t_invest3.gdx'
    $$gdxin '%input_dir%/t_invest3.gdx'
    $$loaddcm t_invest
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_storageValue2.gdx'
    $$gdxin '%input_dir%/p_storageValue2.gdx'
    $$loaddcm p_storageValue
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_storageValue3.gdx'
    $$gdxin '%input_dir%/p_storageValue3.gdx'
    $$loaddcm p_storageValue
    $$gdxin
$endif

$ifthen exist '%input_dir%/uGroup2.gdx'
    $$gdxin '%input_dir%/uGroup2.gdx'
    $$loaddcm uGroup
    $$gdxin
$endif

$ifthen exist '%input_dir%/uGroup3.gdx'
    $$gdxin '%input_dir%/uGroup3.gdx'
    $$loaddcm uGroup
    $$gdxin
$endif

$ifthen exist '%input_dir%/gnuGroup2.gdx'
    $$gdxin '%input_dir%/gnuGroup2.gdx'
    $$loaddcm gnuGroup
    $$gdxin
$endif

$ifthen exist '%input_dir%/gnuGroup3.gdx'
    $$gdxin '%input_dir%/gnuGroup3.gdx'
    $$loaddcm gnuGroup
    $$gdxin
$endif

$ifthen exist '%input_dir%/gn2nGroup2.gdx'
    $$gdxin '%input_dir%/gn2nGroup2.gdx'
    $$loaddcm gn2nGroup
    $$gdxin
$endif

$ifthen exist '%input_dir%/gn2nGroup3.gdx'
    $$gdxin '%input_dir%/gn2nGroup3.gdx'
    $$loaddcm gn2nGroup
    $$gdxin
$endif

$ifthen exist '%input_dir%/gnGroup2.gdx'
    $$gdxin '%input_dir%/gnGroup2.gdx'
    $$loaddcm gnGroup
    $$gdxin
$endif

$ifthen exist '%input_dir%/gnGroup3.gdx'
    $$gdxin '%input_dir%/gnGroup3.gdx'
    $$loaddcm gnGroup
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_groupPolicy2.gdx'
    $$gdxin '%input_dir%/p_groupPolicy2.gdx'
    $$loaddcm p_groupPolicy
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_groupPolicy3.gdx'
    $$gdxin '%input_dir%/p_groupPolicy3.gdx'
    $$loaddcm p_groupPolicy
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_groupPolicy3D2.gdx'
    $$gdxin '%input_dir%/p_groupPolicy3D2.gdx'
    $$loaddcm p_groupPolicy3D
    $$gdxin
$endif

$ifthen exist '%input_dir%/p_groupPolicy3D3.gdx'
    $$gdxin '%input_dir%/p_groupPolicy3D3.gdx'
    $$loaddcm p_groupPolicy3D
    $$gdxin
$endif

$ifthen exist '%input_dir%/gnss_bound2.gdx'
    $$gdxin '%input_dir%/gnss_bound2.gdx'
    $$loaddcm gnss_bound
    $$gdxin
$endif

$ifthen exist '%input_dir%/gnss_bound3.gdx'
    $$gdxin '%input_dir%/gnss_bound3.gdx'
    $$loaddcm gnss_bound
    $$gdxin
$endif

$ifthen exist '%input_dir%/uss_bound2.gdx'
    $$gdxin '%input_dir%/uss_bound2.gdx'
    $$loaddcm uss_bound
    $$gdxin
$endif

$ifthen exist '%input_dir%/uss_bound3.gdx'
    $$gdxin '%input_dir%/uss_bound3.gdx'
    $$loaddcm uss_bound
    $$gdxin
$endif

