//+------------------------------------------------------------------+
//|                                                      Equity Line |
//|                                      Copyright © 2025, EarnForex |
//|                                        https://www.earnforex.com |
//+------------------------------------------------------------------+
#property copyright "www.EarnForex.com, 2025"
#property link      "https://www.earnforex.com/indicators/Equity-Line/"
#property version   "1.01"
#property indicator_chart_window
#property strict

#property description "Displays projected equity at a draggable price line."
#property description "Takes into account P&L of open trades in the current symbol."
#property description "You can hide/show the line by pressing Shift+E."

input int    UpdateFrequency = 1;              // Update frequency (seconds)
input color  LineColor = clrDodgerBlue;        // Projection line color
input int    LineWidth = 2;                    // Projection line width
input ENUM_LINE_STYLE LineStyle = STYLE_SOLID; // Projection line style
input bool   ShowLabel = true;                 // Show equity label
input color  LabelPositiveChangeColor = clrGreen; // Equity label color (positive change)
input color  LabelNegativeChangeColor = clrRed; // Equity label color (negative change)
input int    InitialPriceOffset = 50;          // Initial price offset in points

// Global variables:
string LineObjectName = "EquityProjectionLine";
string EquityLabelObjectName = "EquityProjectionLabel";
double ProjectionPrice = 0;
double ProjectedEquity = 0;
double totalFloatingProfit = 0;

void OnInit()
{
    if (ObjectFind(ChartID(), LineObjectName) < 0) // If the line doesn't exist yet.
    {
        // Initialize projection price near current price.
        double point = MarketInfo(_Symbol, MODE_POINT);
        ProjectionPrice = Bid + (InitialPriceOffset * point);
        ProjectionPrice = NormalizeDouble(ProjectionPrice, (int)MarketInfo(_Symbol, MODE_DIGITS));
        CalculateProjectedEquity();
        DrawProjectionLine();
    }
    EventSetTimer(UpdateFrequency);
}

void OnDeinit(const int reason)
{
    DeleteLineAndLabels();
    EventKillTimer();
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    CalculateProjectedEquity();
    
    return rates_total;
}

void OnTimer()
{
    CalculateProjectedEquity();
}

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
    // Handle line dragging.
    if (id == CHARTEVENT_OBJECT_DRAG)
    {
        if (sparam == LineObjectName)
        {
            // Get new price from line position.
            ProjectionPrice = ObjectGetDouble(0, LineObjectName, OBJPROP_PRICE);
            ProjectionPrice = NormalizeDouble(ProjectionPrice, (int)MarketInfo(_Symbol, MODE_DIGITS));
            CalculateProjectedEquity();
        }
    }
    // Update label position on chart change/scroll.
    else if (id == CHARTEVENT_CHART_CHANGE)
    {
        UpdateLabel();
    }
    // Toggle visibility with Shift+E.
    else if (id == CHARTEVENT_KEYDOWN)
    {
        if ((lparam == 'E') && (TerminalInfoInteger(TERMINAL_KEYSTATE_SHIFT) < 0))
        {
            if (ObjectGetInteger(0, LineObjectName, OBJPROP_TIMEFRAMES) == OBJ_NO_PERIODS) // Was hidden.
            {
                ObjectSetInteger(0, LineObjectName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
                ObjectSetInteger(0, EquityLabelObjectName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
            }
            else // Was visible.
            {
                ObjectSetInteger(0, LineObjectName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
                ObjectSetInteger(0, EquityLabelObjectName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
            }
            ChartRedraw();
        }
    }
}

// Calculate projected equity based on current positions and projection price.
void CalculateProjectedEquity()
{
    // Get current account information.
    double currentEquity = AccountEquity();
    AccCurrency = AccountCurrency();
    
    double point_value_risk = CalculatePointValue(Symbol(), Risk);
    if (point_value_risk == 0) return; // No symbol information yet.
    double point_value_reward = CalculatePointValue(Symbol(), Reward);
    if (point_value_reward == 0) return; // No symbol information yet.

    // Get current price.
    double currentBid = Bid;
    double currentAsk = Ask;
    
    // Calculate total P&L change for positions in current symbol.
    double totalPLChange = 0;
    
    double floatingProfit = 0;

    // Scan all positions.
    int totalOrders = OrdersTotal();
    for (int i = 0; i < totalOrders; i++)
    {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
        
        // Check if position is for current symbol.
        if (OrderSymbol() == _Symbol)
        {
            // Skip pending orders.
            if (OrderType() > OP_SELL) continue;
            
            double posLots = OrderLots();
            
            // Calculate projected P&L at projection price.
            double projectedPL = 0;
            
            if (OrderType() == OP_BUY)
            {
                double priceDiff = ProjectionPrice - currentBid;
                if (priceDiff > 0) projectedPL = priceDiff * point_value_reward * posLots;
                else projectedPL = priceDiff * point_value_risk * posLots;
            }
            else if (OrderType() == OP_SELL)
            {
                // Note: for sell positions, we need to account for spread.
                double spread = currentAsk - currentBid;
                double projectedAsk = ProjectionPrice + spread;
                double priceDiff = currentAsk - projectedAsk;
                if (priceDiff < 0) projectedPL = priceDiff * point_value_reward * posLots;
                else projectedPL = priceDiff * point_value_risk * posLots;
            }
            floatingProfit += OrderProfit() + OrderSwap() + OrderCommission();
            totalPLChange += projectedPL;
        }
    }
    
    // Calculate projected equity.
    ProjectedEquity = currentEquity + totalPLChange;
    
    // For output.
    totalFloatingProfit = totalPLChange + floatingProfit;

    // Update display.
    UpdateLabel();
}

// Draw projection line on chart.
void DrawProjectionLine()
{
    if (ProjectionPrice <= 0) return;
    
    // Create or move horizontal line.
    if (ObjectFind(ChartID(), LineObjectName) < 0)
    {
        // Create new line.
        ObjectCreate(ChartID(), LineObjectName, OBJ_HLINE, 0, 0, ProjectionPrice);
        ObjectSetInteger(ChartID(), LineObjectName, OBJPROP_COLOR, LineColor);
        ObjectSetInteger(ChartID(), LineObjectName, OBJPROP_WIDTH, LineWidth);
        ObjectSetInteger(ChartID(), LineObjectName, OBJPROP_STYLE, LineStyle);
        ObjectSetInteger(ChartID(), LineObjectName, OBJPROP_SELECTABLE, true);
        ObjectSetInteger(ChartID(), LineObjectName, OBJPROP_SELECTED, true);
        ObjectSetString(ChartID(), LineObjectName, OBJPROP_TOOLTIP, "Drag to change projection price.");
    }
    else
    {
        // Update existing line.
        ObjectSetDouble(ChartID(), LineObjectName, OBJPROP_PRICE, ProjectionPrice);
    }
    
    // Add or update labels.
    UpdateLabel();
    ChartRedraw();
}

// Update label position and text.
void UpdateLabel()
{
    if (ProjectionPrice <= 0 || !ShowLabel || iBars(Symbol(), Period()) == 0) return;

    if (ObjectFind(ChartID(), LineObjectName) < 0) DrawProjectionLine(); // If user deleted it.

    // Get the leftmost and rightmost visible bars.
    int firstVisibleBar = (int)ChartGetInteger(ChartID(), CHART_FIRST_VISIBLE_BAR);

    string equityText = "Equity: " + FormatDouble(DoubleToString(ProjectedEquity, 2), 2) + " " + AccCurrency + " (Floating profit: " + FormatDouble(DoubleToString(totalFloatingProfit, 2), 2) + " " + AccCurrency + ")";

    // Calculate color based on equity change.
    double currentEquity = AccountEquity();
    color equityColor = LineColor;
    if (ProjectedEquity > currentEquity) equityColor = LabelPositiveChangeColor;
    else if (ProjectedEquity < currentEquity) equityColor = LabelNegativeChangeColor;

    int labelBar = firstVisibleBar;
    if (labelBar < 0) labelBar = 0;
    datetime labelTime = iTime(Symbol(), Period(), labelBar);

    if (ObjectFind(ChartID(), EquityLabelObjectName) < 0)
    {
        // Create new label.
        ObjectCreate(ChartID(), EquityLabelObjectName, OBJ_TEXT, 0, labelTime, ProjectionPrice);
        ObjectSetInteger(ChartID(), EquityLabelObjectName, OBJPROP_FONTSIZE, 10);
        ObjectSetInteger(ChartID(), EquityLabelObjectName, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
        ObjectSetInteger(ChartID(), EquityLabelObjectName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(ChartID(), EquityLabelObjectName, OBJPROP_SELECTED, false);
        ObjectSetInteger(ChartID(), EquityLabelObjectName, OBJPROP_BACK, false);
    }
    else
    {
        // Update existing label.
        ObjectSetDouble(ChartID(), EquityLabelObjectName, OBJPROP_PRICE, ProjectionPrice);
        ObjectSetInteger(ChartID(), EquityLabelObjectName, OBJPROP_TIME, labelTime);
    }
    ObjectSetString(ChartID(), EquityLabelObjectName, OBJPROP_TEXT, equityText);
    ObjectSetInteger(ChartID(), EquityLabelObjectName, OBJPROP_COLOR, equityColor);
    ChartRedraw();
}

void DeleteLineAndLabels()
{
    ObjectDelete(ChartID(), LineObjectName);
    ObjectDelete(ChartID(), EquityLabelObjectName);
    ChartRedraw();
    ProjectionPrice = 0;
    ProjectedEquity = 0;
}

enum mode_of_operation
{
    Risk,
    Reward
};

string AccCurrency;
double CalculatePointValue(string cp, mode_of_operation mode)
{
    double UnitCost;

    int ProfitCalcMode = (int)MarketInfo(cp, MODE_PROFITCALCMODE);
    string ProfitCurrency = SymbolInfoString(cp, SYMBOL_CURRENCY_PROFIT);
    
    if (ProfitCurrency == "RUR") ProfitCurrency = "RUB";
    // If Symbol is CFD or futures but with different profit currency.
    if ((ProfitCalcMode == 1) || ((ProfitCalcMode == 2) && ((ProfitCurrency != AccCurrency))))
    {
        if (ProfitCalcMode == 2) UnitCost = MarketInfo(cp, MODE_TICKVALUE); // Futures, but will still have to be adjusted by CCC.
        else UnitCost = SymbolInfoDouble(cp, SYMBOL_TRADE_TICK_SIZE) * SymbolInfoDouble(cp, SYMBOL_TRADE_CONTRACT_SIZE); // Apparently, it is more accurate than taking TICKVALUE directly in some cases.
        // If profit currency is different from account currency.
        if (ProfitCurrency != AccCurrency)
        {
            double CCC = CalculateAdjustment(ProfitCurrency, mode); // Valid only for loss calculation.
            // Adjust the unit cost.
            UnitCost *= CCC;
        }
    }
    else UnitCost = MarketInfo(cp, MODE_TICKVALUE); // Futures or Forex.
    double OnePoint = MarketInfo(cp, MODE_POINT);

    if (OnePoint != 0) return(UnitCost / OnePoint);
    return UnitCost; // Only in case of an error with MODE_POINT retrieval.
}

//+-----------------------------------------------------------------------------------+
//| Calculates necessary adjustments for cases when ProfitCurrency != AccountCurrency.|
//| ReferenceSymbol changes every time because each symbol has its own RS.            |
//+-----------------------------------------------------------------------------------+
#define FOREX_SYMBOLS_ONLY 0
#define NONFOREX_SYMBOLS_ONLY 1
double CalculateAdjustment(const string profit_currency, const mode_of_operation calc_mode)
{
    string ref_symbol = NULL, add_ref_symbol = NULL;
    bool ref_mode = false, add_ref_mode = false;
    double add_coefficient = 1; // Might be necessary for correction coefficient calculation if two pairs are used for profit currency to account currency conversion. This is handled differently in MT5 version.

    if (ref_symbol == NULL) // Either first run or non-current symbol.
    {
        ref_symbol = GetSymbolByCurrencies(profit_currency, AccCurrency, FOREX_SYMBOLS_ONLY);
        if (ref_symbol == NULL) ref_symbol = GetSymbolByCurrencies(profit_currency, AccCurrency, NONFOREX_SYMBOLS_ONLY);
        ref_mode = true;
        // Failed.
        if (ref_symbol == NULL)
        {
            // Reversing currencies.
            ref_symbol = GetSymbolByCurrencies(AccCurrency, profit_currency, FOREX_SYMBOLS_ONLY);
            if (ref_symbol == NULL) ref_symbol = GetSymbolByCurrencies(AccCurrency, profit_currency, NONFOREX_SYMBOLS_ONLY);
            ref_mode = false;
        }
        if (ref_symbol == NULL)
        {
            if ((!FindDoubleReferenceSymbol("USD", profit_currency, ref_symbol, ref_mode, add_ref_symbol, add_ref_mode))  // USD should work in 99.9% of cases.
             && (!FindDoubleReferenceSymbol("EUR", profit_currency, ref_symbol, ref_mode, add_ref_symbol, add_ref_mode))  // For very rare cases.
             && (!FindDoubleReferenceSymbol("GBP", profit_currency, ref_symbol, ref_mode, add_ref_symbol, add_ref_mode))  // For extremely rare cases.
             && (!FindDoubleReferenceSymbol("JPY", profit_currency, ref_symbol, ref_mode, add_ref_symbol, add_ref_mode))) // For extremely rare cases.
            {
                Print("Adjustment calculation critical failure. Failed both simple and two-pair conversion methods.");
                return 1;
            }
        }
    }
    if (add_ref_symbol != NULL) // If two reference pairs are used.
    {
        // Calculate just the additional symbol's coefficient and then use it in final return's multiplication.
        MqlTick tick;
        SymbolInfoTick(add_ref_symbol, tick);
        add_coefficient = GetCurrencyCorrectionCoefficient(tick, calc_mode, add_ref_mode);
    }
    MqlTick tick;
    SymbolInfoTick(ref_symbol, tick);
    return GetCurrencyCorrectionCoefficient(tick, calc_mode, ref_mode) * add_coefficient;
}

//+---------------------------------------------------------------------------+
//| Returns a currency pair with specified base currency and profit currency. |
//+---------------------------------------------------------------------------+
string GetSymbolByCurrencies(const string base_currency, const string profit_currency, const uint symbol_type)
{
    // Cycle through all symbols.
    for (int s = 0; s < SymbolsTotal(false); s++)
    {
        // Get symbol name by number.
        string symbolname = SymbolName(s, false);
        string b_cur;

        // Normal case - Forex pairs:
        if (MarketInfo(symbolname, MODE_PROFITCALCMODE) == 0)
        {
            if (symbol_type == NONFOREX_SYMBOLS_ONLY) continue; // Avoid checking symbols of a wrong type.
            // Get its base currency.
            b_cur = SymbolInfoString(symbolname, SYMBOL_CURRENCY_BASE);
        }
        else // Weird case for brokers that set conversion pairs as CFDs.
        {
            if (symbol_type == FOREX_SYMBOLS_ONLY) continue; // Avoid checking symbols of a wrong type.
            // Get its base currency as the initial three letters - prone to huge errors!
            b_cur = StringSubstr(symbolname, 0, 3);
        }

        // Get its profit currency.
        string p_cur = SymbolInfoString(symbolname, SYMBOL_CURRENCY_PROFIT);

        // If the currency pair matches both currencies, select it in Market Watch and return its name.
        if ((b_cur == base_currency) && (p_cur == profit_currency))
        {
            // Select if necessary.
            if (!(bool)SymbolInfoInteger(symbolname, SYMBOL_SELECT)) SymbolSelect(symbolname, true);

            return symbolname;
        }
    }
    return NULL;
}

//+----------------------------------------------------------------------------+
//| Finds reference symbols using 2-pair method.                               |
//| Results are returned via reference parameters.                             |
//| Returns true if found the pairs, false otherwise.                          |
//+----------------------------------------------------------------------------+
bool FindDoubleReferenceSymbol(const string cross_currency, const string profit_currency, string &ref_symbol, bool &ref_mode, string &add_ref_symbol, bool &add_ref_mode)
{
    // A hypothetical example for better understanding:
    // The trader buys CAD/CHF.
    // account_currency is known = SEK.
    // cross_currency = USD.
    // profit_currency = CHF.
    // I.e., we have to buy dollars with francs (using the Ask price) and then sell those for SEKs (using the Bid price).

    ref_symbol = GetSymbolByCurrencies(cross_currency, AccCurrency, FOREX_SYMBOLS_ONLY); 
    if (ref_symbol == NULL) ref_symbol = GetSymbolByCurrencies(cross_currency, AccCurrency, NONFOREX_SYMBOLS_ONLY);
    ref_mode = true; // If found, we've got USD/SEK.

    // Failed.
    if (ref_symbol == NULL)
    {
        // Reversing currencies.
        ref_symbol = GetSymbolByCurrencies(AccCurrency, cross_currency, FOREX_SYMBOLS_ONLY);
        if (ref_symbol == NULL) ref_symbol = GetSymbolByCurrencies(AccCurrency, cross_currency, NONFOREX_SYMBOLS_ONLY);
        ref_mode = false; // If found, we've got SEK/USD.
    }
    if (ref_symbol == NULL)
    {
        Print("Error. Couldn't detect proper currency pair for 2-pair adjustment calculation. Cross currency: ", cross_currency, ". Account currency: ", AccCurrency, ".");
        return false;
    }

    add_ref_symbol = GetSymbolByCurrencies(cross_currency, profit_currency, FOREX_SYMBOLS_ONLY); 
    if (add_ref_symbol == NULL) add_ref_symbol = GetSymbolByCurrencies(cross_currency, profit_currency, NONFOREX_SYMBOLS_ONLY);
    add_ref_mode = false; // If found, we've got USD/CHF. Notice that mode is swapped for cross/profit compared to cross/acc, because it is used in the opposite way.

    // Failed.
    if (add_ref_symbol == NULL)
    {
        // Reversing currencies.
        add_ref_symbol = GetSymbolByCurrencies(profit_currency, cross_currency, FOREX_SYMBOLS_ONLY);
        if (add_ref_symbol == NULL) add_ref_symbol = GetSymbolByCurrencies(profit_currency, cross_currency, NONFOREX_SYMBOLS_ONLY);
        add_ref_mode = true; // If found, we've got CHF/USD. Notice that mode is swapped for profit/cross compared to acc/cross, because it is used in the opposite way.
    }
    if (add_ref_symbol == NULL)
    {
        Print("Error. Couldn't detect proper currency pair for 2-pair adjustment calculation. Cross currency: ", cross_currency, ". Chart's pair currency: ", profit_currency, ".");
        return false;
    }

    return true;
}

//+------------------------------------------------------------------+
//| Get profit correction coefficient based on current prices.       |
//+------------------------------------------------------------------+
double GetCurrencyCorrectionCoefficient(MqlTick &tick, const mode_of_operation mode, const bool ReferenceSymbolMode)
{
    if ((tick.ask == 0) || (tick.bid == 0)) return -1; // Data is not yet ready.
    if (mode == Risk)
    {
        // Reverse quote.
        if (ReferenceSymbolMode)
        {
            // Using Buy price for reverse quote.
            return tick.ask;
        }
        // Direct quote.
        else
        {
            // Using Sell price for direct quote.
            return(1 / tick.bid);
        }
    }
    else if (mode == Reward)
    {
        // Reverse quote.
        if (ReferenceSymbolMode)
        {
            // Using Sell price for reverse quote.
            return tick.bid;
        }
        // Direct quote.
        else
        {
            // Using Buy price for direct quote.
            return(1 / tick.ask);
        }
    }
    return -1;
}

//+---------------------------------------------------------------------------+
//| Formats double with thousands separator for so many digits after the dot. |
//+---------------------------------------------------------------------------+
string FormatDouble(const string number, const int digits = 2)
{
    // Find "." position.
    int pos = StringFind(number, ".");
    string integer = number;
    string decimal = "";
    if (pos > -1)
    {
        integer = StringSubstr(number, 0, pos);
        decimal = StringSubstr(number, pos, digits + 1);
    }
    string formatted = "";
    string comma = "";

    while (StringLen(integer) > 3)
    {
        int length = StringLen(integer);
        string group = StringSubstr(integer, length - 3);
        formatted = group + comma + formatted;
        comma = ",";
        integer = StringSubstr(integer, 0, length - 3);
    }
    if (integer == "-") comma = "";
    if (integer != "") formatted = integer + comma + formatted;

    return(formatted + decimal);
}
//+------------------------------------------------------------------+