* the model reads changes.inc after input data gdx and after 1e_scenchanges.gms
* changes.inc can be used for may uses, e.g. modifying input data or reading second input file


* ------------------------
* Reading additional input data
* ------------------------

// proceeding only if additional input data excel exists
$ifthen exist '%input_dir%/bb_inputData2.xlsx'

// Convert additional excel input
$call 'gdxxrw Input="%input_dir%/bb_inputData2.xlsx" Output="%input_dir%/bb_inputData2.gdx" index=index!A1'
$ife %system.errorlevel%>0 $abort gdxxrw failed!

    // load input data
    $$gdxin  '%input_dir%/bb_inputData2.gdx'
    // this list can contain all or selected input data tables
    // but all items in this list must be included in the index table of the bb_inputData2.xlsx
    $$loaddcm grid
    $$loaddcm node
    $$loaddcm flow
    $$loaddcm unittype
    $$loaddcm unit
    $$loaddcm unitUnittype
    $$loaddcm unit_fail
    $$loaddcm unitUnitEffLevel
    $$loaddcm effLevelGroupUnit
    $$loaddcm p_gn
    $$loaddcm p_gnn
    $$loaddcm p_gnu_io
    $$loaddcm p_gnuBoundaryProperties
    $$loaddcm p_unit

    $$gdxin
$endif


