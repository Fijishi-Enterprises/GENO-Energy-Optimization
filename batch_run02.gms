$ontext
Batch run file for energy modelling of buildings

Toni Lastusilta (VTT) , 2022-12-16
$offtext

*TESTING
*$call gams Backbone.gms --run_title=spot --year=2016 --t_jump=2190 --t_horizon=4380 --input_file_gdx=inputDataAdjusted1.gdx  --plot=1
*$call gams Backbone.gms --run_title=spot --year=2015 --t_jump=4380 --t_horizon=8760 --input_file_gdx=inputDataAdjusted1.gdx  --plot=1

*BATCH 1
$call gams Backbone.gms --run_title=flat --year=2015 --t_jump=1  --t_horizon=12   --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=flat --year=2016 --t_jump=1  --t_horizon=12   --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=flat --year=2017 --t_jump=1  --t_horizon=12   --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=flat --year=2018 --t_jump=1  --t_horizon=12   --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=flat --year=2019 --t_jump=1  --t_horizon=12   --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=flat --year=2020 --t_jump=1  --t_horizon=12   --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=flat --year=2021 --t_jump=1  --t_horizon=12   --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=flat --year=2022 --t_jump=1  --t_horizon=12   --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2015 --t_jump=1  --t_horizon=12   --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2016 --t_jump=1  --t_horizon=12   --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2017 --t_jump=1  --t_horizon=12   --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2018 --t_jump=1  --t_horizon=12   --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2019 --t_jump=1  --t_horizon=12   --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2020 --t_jump=1  --t_horizon=12   --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2021 --t_jump=1  --t_horizon=12   --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2022 --t_jump=1  --t_horizon=12   --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0

*BATCH 2
* Disabled
$ontext
$call gams Backbone.gms --run_title=spot --year=2021 --t_jump=1    --t_horizon=12    --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2021 --t_jump=1    --t_horizon=24    --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2021 --t_jump=1    --t_horizon=36    --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2021 --t_jump=8736 --t_horizon=8760  --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2020 --t_jump=1    --t_horizon=12    --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2020 --t_jump=1    --t_horizon=24    --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2020 --t_jump=1    --t_horizon=36    --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2020 --t_jump=8736 --t_horizon=8760  --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2019 --t_jump=1    --t_horizon=12    --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2019 --t_jump=1    --t_horizon=24    --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2019 --t_jump=1    --t_horizon=36    --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2019 --t_jump=8736 --t_horizon=8760  --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2018 --t_jump=1    --t_horizon=12    --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2018 --t_jump=1    --t_horizon=24    --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2018 --t_jump=1    --t_horizon=36    --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2018 --t_jump=8736 --t_horizon=8760  --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2017 --t_jump=1    --t_horizon=12    --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2017 --t_jump=1    --t_horizon=24    --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2017 --t_jump=1    --t_horizon=36    --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2017 --t_jump=8736 --t_horizon=8760  --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2016 --t_jump=1    --t_horizon=12    --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2016 --t_jump=1    --t_horizon=24    --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2016 --t_jump=1    --t_horizon=36    --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2016 --t_jump=8736 --t_horizon=8760  --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2015 --t_jump=1    --t_horizon=12    --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2015 --t_jump=1    --t_horizon=24    --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2015 --t_jump=1    --t_horizon=36    --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2015 --t_jump=8736 --t_horizon=8760  --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2022 --t_jump=1    --t_horizon=12    --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2022 --t_jump=1    --t_horizon=24    --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2022 --t_jump=1    --t_horizon=36    --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$call gams Backbone.gms --run_title=spot --year=2022 --t_jump=8736 --t_horizon=8760  --input_file_gdx=inputDataAdjusted1.gdx  --plot=1  Suppress=1 lo=0
$offtext