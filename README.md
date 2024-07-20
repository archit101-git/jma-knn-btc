
# Overview

This strategy combines the Jurik Moving Average (JMA), the Average Directional Index (ADX), Chaikin Money Flow (CMF), and a k-Nearest Neighbors (kNN) based prediction model to identify buy opportunities in the market. The strategy aims to filter and confirm buy signals by using multiple indicators and conditions.

# Inputs

JMA Length: Length of the Jurik Moving Average.
JMA Phase: Phase of the JMA.
JMA Power: Power of the JMA.
JMA Source: Source of the JMA calculation (typically the closing price).
Highlight Movements for JMA?: Boolean to highlight upward/downward movements of JMA.
ADX Smoothing: Length for smoothing ADX calculation.
DI Length: Length for Directional Indicator calculation.
CMF Length: Length for the Chaikin Money Flow calculation.
Start Date: The start date for the kNN-based strategy.
Stop Date: The stop date for the kNN-based strategy.
Indicator: The indicator to use for kNN-based strategy (RSI, ROC, CCI, Volume, or All).
Short Period: Short period for kNN calculation.
Long Period: Long period for kNN calculation.
Base No. of Neighbours (K): Base number of neighbors for kNN calculation.
Volatility Filter: Boolean to use a volatility filter.
Bar Threshold: Threshold for the number of bars to consider.
# Calculations

Jurik Moving Average (JMA) Calculation:

The JMA is calculated using the specified length, phase, and power parameters.
The color of the JMA plot changes based on its direction (green for upward, red for downward).
Average Directional Index (ADX) Calculation:

ADX is calculated to identify the strength of the trend.
The ADX value is plotted in red.
Average Candle Length Calculation:

The average length of the candles over the last 50 bars is calculated.
Chaikin Money Flow (CMF) Calculation:

CMF is calculated to measure the volume flow over a specified period.
k-Nearest Neighbors (kNN) Based Prediction:

The strategy uses kNN to predict market direction based on selected indicators (RSI, ROC, CCI, Volume, or a combination).
The prediction is integrated with other indicators to confirm buy signals.
# Conditions for Buy Entry
JMA Direction:
The JMA is green (indicating an upward trend).
ADX Value:
ADX is above 25 (indicating a strong trend).
Touching JMA:
The previous candle's close and low touch the JMA.
Length Condition:
The previous candle's length is greater than 1.2 times the average candle length.
kNN Long Prediction:
The kNN-based prediction is positive.
# Conditions for Exit
JMA Direction:
The JMA is red (indicating a downward trend).
CMF Value:
The CMF line is greater than 0.4.
# Strategy Logic
## Entry:

If all the conditions for a buy entry are met, the strategy enters a long position.
## Exit:

If any of the exit conditions are met, the strategy closes the long position.

