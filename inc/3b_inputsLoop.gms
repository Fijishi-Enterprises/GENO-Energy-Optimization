put log 'ord tSolve: ';
put log ord(tSolve) /;

if (mSettings(mSolve, 'readForecastsInTheLoop') and ord(tSolve) >= tForecastNext(mSolve),
  put_utility 'gdxin' / 'input\forecasts\' tSolve.tl:0 '.gdx';
  execute_load ts_forecast = forecast;
  tLatestForecast(t) = no;
  tLatestForecast(t)$(ord(t) = ord(tSolve)) = yes;

  put_utility 'gdxin' / 'input\tertiary\' tSolve.tl:0 '.gdx';
  execute_load ts_tertiary;
  ts_reserveDemand('tertiary','up','FI_R',f,t)$(ord(f) <= mSettings(mSolve, 'forecasts') + 1) = min(500,ts_tertiary('wind','74FI',tSolve,'up',t) * p_gnu('elec','FI_R','Wind_FI_R','maxGen'));
  ts_reserveDemand('tertiary','up','SE_N',f,t)$(ord(f) <= mSettings(mSolve, 'forecasts') + 1) = min(300,ts_tertiary('wind','86SE',tSolve,'up',t) * p_gnu('elec','SE_N','Wind_SE_N','maxGen'));
  ts_reserveDemand('tertiary','down','FI_R',f,t)$(ord(f) <= mSettings(mSolve, 'forecasts') + 1) = min(500,ts_tertiary('wind','74FI',tSolve,'down',t) * p_gnu('elec','FI_R','Wind_FI_R','maxGen'));
  ts_reserveDemand('tertiary','down','SE_N',f,t)$(ord(f) <= mSettings(mSolve, 'forecasts') + 1) = min(300,ts_tertiary('wind','86SE',tSolve,'down',t) * p_gnu('elec','SE_N','Wind_SE_N','maxGen'));
);

putclose log;
