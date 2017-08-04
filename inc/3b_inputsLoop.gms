put log 'ord tSolve: ';
put log ord(tSolve) /;

if (mSettings(mSolve, 'readForecastsInTheLoop') and ord(tSolve) >= tForecastNext(mSolve),
  put_utility 'gdxin' / 'input\forecasts\' tSolve.tl:0 '.gdx';
  execute_load ts_forecast = forecast;
  tLatestForecast(t) = no;
  tLatestForecast(t)$(ord(t) = ord(tSolve)) = yes;

  put_utility 'gdxin' / 'input\tertiary\' tSolve.tl:0 '.gdx';
  execute_load ts_tertiary;
);

putclose log;
