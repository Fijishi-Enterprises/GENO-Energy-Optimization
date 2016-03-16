* --- Parameters for sorting time series
Parameters
    s_rampStarts(rStarts)
    s_sortCount
    s_rampLengthAve
    s_rampWindow
    s_rampSegments
    s_rampExcludeFromSearchLength
    s_maxSegmentLengthWithoutNotch
    s_segmentLengthFound
    s_segmentLengthCurrent
    s_currentMax
    s_currentMaxPos
    s_stop
    s_previousHourOrd
    s_notchCount
    s_notchPos
    s_netLoadChanged
    s_rampWindowPrev
    s_rampSegmentsPrev
    s_maxSegmentLengthWithoutNotchPrev
    s_rampExcludeFromSearchLengthPrev
    s_netLoadAtNotch
;

s_rampWindow = 8760;
s_rampSegments = 70;
s_rampExcludeFromSearchLength = 10;
s_maxSegmentLengthWithoutNotch = 25;

s_rampWindowPrev = 0;
s_rampSegmentsPrev = 0;
s_maxSegmentLengthWithoutNotchPrev = 0;
s_rampExcludeFromSearchLengthPrev = 0;
