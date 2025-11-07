//+------------------------------------------------------------------+
//|                                                      Equity Line |
//|                                      Copyright © 2025, EarnForex |
//|                                        https://www.earnforex.com |
//+------------------------------------------------------------------+
#property copyright "www.EarnForex.com, 2025"
#property link      "https://www.earnforex.com/indicators/Equity-Line/"
#property version   "1.01"
#property indicator_chart_window
#property indicator_plots 0

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
        MqlTick tick;
        SymbolInfoTick(_Symbol, tick);
        double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
        ProjectionPrice = tick.bid + (InitialPriceOffset * point);
        ProjectionPrice = NormalizeDouble(ProjectionPrice, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
        CalculateProjectedEquity();
        DrawProjectionLine();
    }
    else
    {
        ProjectionPrice = NormalizeDouble(ObjectGetDouble(ChartID(), LineObjectName, OBJPROP_PRICE), (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
    }
    EventSetTimer(UpdateFrequency);
}

void OnDeinit(const int reason)
{
    if (reason != REASON_CHARTCHANGE) DeleteLineAndLabels();
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
            ProjectionPrice = NormalizeDouble(ProjectionPrice, (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS));
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
    double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    AccCurrency = AccountInfoString (ACCOUNT_CURRENCY);
    
    double point_value_risk = CalculatePointValue(Risk);
    if (point_value_risk == 0) return; // No symbol information yet.
    double point_value_reward = CalculatePointValue(Reward);
    if (point_value_reward == 0) return; // No symbol information yet.

    // Get current price.
    MqlTick tick;
    SymbolInfoTick(_Symbol, tick);
    
    // Calculate total P&L change for positions in current symbol.
    double totalPLChange = 0;
    
    double floatingProfit = 0;
    
    // Scan all positions.
    int totalPositions = PositionsTotal();
    for (int i = 0; i < totalPositions; i++)
    {
        string posSymbol = PositionGetSymbol(i);
        if (PositionSelectByTicket(PositionGetTicket(i)))
        {
            // Check if position is for current symbol.
            if (posSymbol == _Symbol)
            {
                ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                double posLots = PositionGetDouble(POSITION_VOLUME);
                
                // Calculate projected P&L at projection price.
                double projectedPL = 0;
                
                if (posType == POSITION_TYPE_BUY)
                {
                    double priceDiff = ProjectionPrice - tick.bid;
                    if (priceDiff > 0) projectedPL = priceDiff * point_value_reward * posLots;
                    else projectedPL = priceDiff * point_value_risk * posLots;
                }
                else if (posType == POSITION_TYPE_SELL)
                {
                    // Note: for sell positions, we need to account for spread.
                    double spread = tick.ask - tick.bid;
                    double projectedAsk = ProjectionPrice + spread;
                    double priceDiff = tick.ask - projectedAsk;
                    if (priceDiff < 0) projectedPL = priceDiff * point_value_reward * posLots;
                    else projectedPL = priceDiff * point_value_risk * posLots;
                }
                floatingProfit += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP) + CalculateCommission();
                totalPLChange += projectedPL;
            }
        }
    }
    
    // Calculate projected equity.
    ProjectedEquity = currentEquity + totalPLChange;

    // For output.
    totalFloatingProfit = totalPLChange + floatingProfit;

    // Update display.
    UpdateLabel();
}

double CalculateCommission()
{
    double commission_sum = 0;
    if (!HistorySelectByPosition(PositionGetInteger(POSITION_IDENTIFIER)))
    {
        Print("HistorySelectByPosition failed: ", GetLastError());
        return 0;
    }
    int deals_total = HistoryDealsTotal();
    for (int i = 0; i < deals_total; i++)
    {
        ulong deal_ticket = HistoryDealGetTicket(i);
        if (deal_ticket == 0)
        {
            Print("HistoryDealGetTicket failed: ", GetLastError());
            continue;
        }
        if ((HistoryDealGetInteger(deal_ticket, DEAL_TYPE) != DEAL_TYPE_BUY) && (HistoryDealGetInteger(deal_ticket, DEAL_TYPE) != DEAL_TYPE_SELL)) continue; // Wrong kinds of deals.
        if (HistoryDealGetInteger(deal_ticket, DEAL_ENTRY) != DEAL_ENTRY_IN) continue; // Only entry deals.
        commission_sum += HistoryDealGetDouble(deal_ticket, DEAL_COMMISSION);
    }
    return commission_sum;
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

    string equityText = "Equity: " + FormatDouble(DoubleToString(ProjectedEquity, (int)AccountInfoInteger(ACCOUNT_CURRENCY_DIGITS)), (int)AccountInfoInteger(ACCOUNT_CURRENCY_DIGITS)) + " " + AccCurrency + " (Floating profit: " + FormatDouble(DoubleToString(totalFloatingProfit, (int)AccountInfoInteger(ACCOUNT_CURRENCY_DIGITS)), (int)AccountInfoInteger(ACCOUNT_CURRENCY_DIGITS)) + " " + AccCurrency + ")";

    // Calculate color based on equity change.
    double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
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
double CalculatePointValue(mode_of_operation mode)
{
    string cp = Symbol();
    double UnitCost = CalculateUnitCost(cp, mode);
    double OnePoint = SymbolInfoDouble(cp, SYMBOL_POINT);
//Print(UnitCost, " - ", OnePoint);
    return(UnitCost / OnePoint);
}

//+----------------------------------------------------------------------+
//| Returns unit cost either for Risk or for Reward mode.                |
//+----------------------------------------------------------------------+
double CalculateUnitCost(const string cp, const mode_of_operation mode)
{
    ENUM_SYMBOL_CALC_MODE CalcMode = (ENUM_SYMBOL_CALC_MODE)SymbolInfoInteger(cp, SYMBOL_TRADE_CALC_MODE);

    // No-Forex.
    if ((CalcMode != SYMBOL_CALC_MODE_FOREX) && (CalcMode != SYMBOL_CALC_MODE_FOREX_NO_LEVERAGE) && (CalcMode != SYMBOL_CALC_MODE_FUTURES) && (CalcMode != SYMBOL_CALC_MODE_EXCH_FUTURES) && (CalcMode != SYMBOL_CALC_MODE_EXCH_FUTURES_FORTS))
    {
        double TickSize = SymbolInfoDouble(cp, SYMBOL_TRADE_TICK_SIZE);
        double UnitCost = TickSize * SymbolInfoDouble(cp, SYMBOL_TRADE_CONTRACT_SIZE);
        string ProfitCurrency = SymbolInfoString(cp, SYMBOL_CURRENCY_PROFIT);
        if (ProfitCurrency == "RUR") ProfitCurrency = "RUB";

        // If profit currency is different from account currency.
        if (ProfitCurrency != AccCurrency)
        {
            return(UnitCost * CalculateAdjustment(ProfitCurrency, mode));
        }
        return UnitCost;
    }
    // With Forex instruments, tick value already equals 1 unit cost.
    else
    {
        if (mode == Risk) return SymbolInfoDouble(cp, SYMBOL_TRADE_TICK_VALUE_LOSS);
        else return SymbolInfoDouble(cp, SYMBOL_TRADE_TICK_VALUE_PROFIT);
    }
}

//+-----------------------------------------------------------------------------------+
//| Calculates necessary adjustments for cases when GivenCurrency != AccountCurrency. |
//| Used in two cases: profit adjustment and margin adjustment.                       |
//+-----------------------------------------------------------------------------------+
double CalculateAdjustment(const string ProfitCurrency, const mode_of_operation mode)
{
    string ReferenceSymbol = GetSymbolByCurrencies(ProfitCurrency, AccCurrency);
    bool ReferenceSymbolMode = true;
    // Failed.
    if (ReferenceSymbol == NULL)
    {
        // Reversing currencies.
        ReferenceSymbol = GetSymbolByCurrencies(AccCurrency, ProfitCurrency);
        ReferenceSymbolMode = false;
    }
    // Everything failed.
    if (ReferenceSymbol == NULL)
    {
        Print("Error! Cannot detect proper currency pair for adjustment calculation: ", ProfitCurrency, ", ", AccCurrency, ".");
        ReferenceSymbol = Symbol();
        return 1;
    }
    MqlTick tick;
    SymbolInfoTick(ReferenceSymbol, tick);
    return GetCurrencyCorrectionCoefficient(tick, mode, ReferenceSymbolMode);
}

//+---------------------------------------------------------------------------+
//| Returns a currency pair with specified base currency and profit currency. |
//+---------------------------------------------------------------------------+
string GetSymbolByCurrencies(string base_currency, string profit_currency)
{
    // Cycle through all symbols.
    for (int s = 0; s < SymbolsTotal(false); s++)
    {
        // Get symbol name by number.
        string symbolname = SymbolName(s, false);

        // Skip non-Forex pairs.
        if ((SymbolInfoInteger(symbolname, SYMBOL_TRADE_CALC_MODE) != SYMBOL_CALC_MODE_FOREX) && (SymbolInfoInteger(symbolname, SYMBOL_TRADE_CALC_MODE) != SYMBOL_CALC_MODE_FOREX_NO_LEVERAGE)) continue;

        // Get its base currency.
        string b_cur = SymbolInfoString(symbolname, SYMBOL_CURRENCY_BASE);
        if (b_cur == "RUR") b_cur = "RUB";

        // Get its profit currency.
        string p_cur = SymbolInfoString(symbolname, SYMBOL_CURRENCY_PROFIT);
        if (p_cur == "RUR") p_cur = "RUB";
        
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

//+------------------------------------------------------------------+
//| Get profit correction coefficient based on profit currency,      |
//| calculation mode (profit or loss), reference pair mode (reverse  |
//| or direct), and current prices.                                  |
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