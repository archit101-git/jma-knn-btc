//@version=5
strategy("JMA Strategy with ADX Filter (Buy Only)", overlay=true)

// Inputs for Jurik Moving Average
length = input.int(title="JMA Length", defval=51)
phase = input.int(title="JMA Phase", defval=30)
power = input.int(title="JMA Power", defval=3)
src = input.source(title="JMA Source", defval=close)
highlightMovements = input.bool(title="Highlight Movements for JMA?", defval=true)

// Inputs for ADX
adxlen = input.int(title="ADX Smoothing", defval=5)
dilen = input.int(title="DI Length", defval=5)

// Calculate JMA
phaseRatio = phase < -100 ? 0.5 : phase > 100 ? 2.5 : phase / 100 + 1.5
beta = 0.45 * (length - 1) / (0.45 * (length - 1) + 2)
alpha = math.pow(beta, power)

var float jma = na
var float e0 = na
var float e1 = na
var float e2 = na

e0 := (1 - alpha) * src + alpha * nz(e0[1], src)
e1 := (src - e0) * (1 - beta) + beta * nz(e1[1], 0)
e2 := (e0 + phaseRatio * e1 - nz(jma[1], src)) * math.pow(1 - alpha, 2) + math.pow(alpha, 2) * nz(e2[1], 0)
jma := e2 + nz(jma[1], src)

jmaColor = highlightMovements ? (jma > jma[1] ? color.green : color.red) : color.new(#6d1e7f, 0)
plot(jma, title="JMA", linewidth=2, color=jmaColor)

// ADX Calculation
dirmov(len) =>
    up = ta.change(high)
    down = -ta.change(low)
    plusDM = na(up) ? na : (up > down and up > 0 ? up : 0)
    minusDM = na(down) ? na : (down > up and down > 0 ? down : 0)
    truerange = ta.rma(ta.tr, len)
    plus = fixnan(100 * ta.rma(plusDM, len) / truerange)
    minus = fixnan(100 * ta.rma(minusDM, len) / truerange)
    [plus, minus]

adx(dilen, adxlen) =>
    [plus, minus] = dirmov(dilen)
    sum = plus + minus
    adx = 100 * ta.rma(math.abs(plus - minus) / (sum == 0 ? 1 : sum), adxlen)
    adx

adxValue = adx(dilen, adxlen)
plot(adxValue, color=color.red, title="ADX")

// Calculate average candle length (high - low) over the last 50 candles
avg_candle_len = ta.sma(high - low, 50)

// Chaikin Money Flow Calculation
length_cmf = input.int(title="CMF Length", defval=21)
clv = high == low ? 0 : (close - low - (high - close)) / (high - low)
mfv = clv * nz(volume, 1)
cmfLine = math.sum(mfv, length_cmf) / math.sum(nz(volume, 1), length_cmf)

// kNN-based Strategy Logic
int startdate = timestamp('01 Jan 2000 00:00:00 GMT+10')
int stopdate  = timestamp('31 Dec 2025 23:45:00 GMT+10')

StartDate  = input.time  (startdate, 'Start Date')
StopDate   = input.time  (stopdate,  'Stop Date')
Indicator  = input.string('All',     'Indicator',   ['RSI','ROC','CCI','Volume','All'])
ShortWinow = input.int   (14,        'Short Period [1..n]', 1)
LongWindow = input.int   (35,        'Long Period [2..n]',  2)
BaseK      = input.int   (250,       'Base No. of Neighbours (K) [5..n]', 5)
Filter     = input.bool  (true,      'Volatility Filter') // Set default to true
Bars       = input.int   (300,       'Bar Threshold [2..5000]', 2, 5000)

var int BUY   = 1
var int SELL  =-1
var int CLEAR = 0

var int k     = math.floor(math.sqrt(BaseK))  // k Value for kNN algo

var array<float> feature1   = array.new_float(0)  // [0,...,100]
var array<float> feature2   = array.new_float(0)  //    ...
var array<int>   directions = array.new_int(0)    // [-1; +1]

var array<int>   predictions = array.new_int(0)
var float        prediction  = 0.0
var array<int>   bars        = array.new<int>(1, 0) // array used as a container for inter-bar variables

var int          signal      = CLEAR

minimax(float x, int p, float min, float max) => 
    float hi = ta.highest(x, p), float lo = ta.lowest(x, p)
    (max - min) * (x - lo)/(hi - lo) + min

cAqua(int g) => g>9?#0080FFff:g>8?#0080FFe5:g>7?#0080FFcc:g>6?#0080FFb2:g>5?#0080FF99:g>4?#0080FF7f:g>3?#0080FF66:g>2?#0080FF4c:g>1?#0080FF33:#00C0FF19
cPink(int g) => g>9?#FF0080ff:g>8?#FF0080e5:g>7?#FF0080cc:g>6?#FF0080b2:g>5?#FF008099:g>4?#FF00807f:g>3?#FF008066:g>2?#FF00804c:g>1?#FF008033:#FF008019

inside_window(float start, float stop) =>  
    time >= start and time <= stop ? true : false

bool window = inside_window(StartDate, StopDate)

float rs = ta.rsi(close,   LongWindow),        float rf = ta.rsi(close,   ShortWinow)
float cs = ta.cci(close,   LongWindow),        float cf = ta.cci(close,   ShortWinow)
float os = ta.roc(close,   LongWindow),        float of = ta.roc(close,   ShortWinow)
float vs = minimax(volume, LongWindow, 0, 99), float vf = minimax(volume, ShortWinow, 0, 99)

float f1 = switch Indicator
    'RSI'    => rs 
    'CCI'    => cs 
    'ROC'    => os 
    'Volume' => vs 
    => math.avg(rs, cs, os, vs)

float f2 = switch Indicator
    'RSI'    => rf 
    'CCI'    => cf
    'ROC'    => of
    'Volume' => vf 
    => math.avg(rf, cf, of, vf)

int class_label = int(math.sign(close[1] - close[0]))

if window
    array.push(feature1, f1)
    array.push(feature2, f2)
    array.push(directions, class_label)

int   size    = array.size(directions)
float maxdist = -999.0

for i=0 to size-1
    float d = math.sqrt(math.pow(f1 - array.get(feature1, i), 2) + math.pow(f2 - array.get(feature2, i), 2))
    if d > maxdist
        maxdist := d
        if array.size(predictions) >= k
            array.shift(predictions)
        array.push(predictions, array.get(directions, i))

prediction := array.sum(predictions)   

bool filter = Filter ? ta.atr(10) > ta.atr(40) : true
bool knn_long  = prediction > 0 and filter

// Integrate the kNN-based strategy prediction with the JMA and ADX conditions
jmaIsGreen = jma > jma[1]
jmaIsRed = jma < jma[1]
adxIsAbove25 = adxValue >= 25

var touchingJMA = false

if (close[1] >= jma[1] and low[1] <= jma[1])
    touchingJMA := true
else
    touchingJMA := false

prev_candle_len = high[1] - low[1]
length_condition = prev_candle_len > 1.2 * avg_candle_len

if (jmaIsGreen and adxIsAbove25 and touchingJMA and length_condition and knn_long)
    strategy.entry("Buy", strategy.long)

exit_condition = cmfLine > 0.4
if (jmaIsRed or exit_condition)
    strategy.close("Buy")
