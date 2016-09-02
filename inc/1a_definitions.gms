* --- Model parameters, features and switches ---------------------------------
Sets  // Model related selections
    mType "model types in the Backbone" /invest, storage, schedule, realtime/
    mSetting "setting categories for models" /t_start, t_jump, t_horizon, t_forecastLength, t_end, samples, forecasts, intervalEnd, intervalLength, t_aggregate/
    counter "general counter set" /c000*c999/;
;

* Numeric parameters
Parameter
    mSettings(mType, mSetting)
    mInterval(mType, mSetting, counter)
    t_skip_counter
;


Parameter params(*) /
$if exist 'params.inc' $include 'params.inc'
/;


* Model features
Set feature "Set of optional model features" /
    findStorageStart "Solve for optimal storage start levels"
    storageValue     "Use storage value instead of fixed control"
    storageEnd       "Expected storage end levels greater than starting levels"
    addOn            "Use StoSSch as a storage add-on to a larger model"
    extraRes         "Use extra tertiary reserves for error in elec. load during time step"
    rampSched        "Use power based scheduling"
/;

Set active(feature) "Set membership tells active model features" /
$if exist 'features.inc' $include 'features.inc'
/;

* --- Parse command line options and store values -----------------------------

* Features
$if set findStorageStart active('findStorageStart') = %findStorageStart%;
$if set storageValue active('storageValue') = %storageValue%;
$if set storageEnd active('storageEnd') = %storageEnd%;
$if set addOn active('addOn') = %addOn%;
$if set extraRes active('extraRes') = %extraRes%;
$if set rampSched active('rampSched') = %rampSched%;




