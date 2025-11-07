// -------------------------------------------------------------------------------
//   Displays projected equity at a draggable price line.
//   Takes into account P&L of open trades in the current symbol.
//   You can hide/show the line by pressing Shift+E.
//   
//   Version 1.01
//   Copyright 2025, EarnForex.com
//   https://www.earnforex.com/indicators/Entry-Line/
// -------------------------------------------------------------------------------

using System;
using System.Linq;
using cAlgo.API;
using cAlgo.API.Internals;

namespace cAlgo
{
    [Indicator(IsOverlay = true, TimeZone = TimeZones.UTC, AccessRights = AccessRights.None)]
    public class EquityProjectionLine : Indicator
    {
        [Parameter("Update Frequency (seconds)", DefaultValue = 1, MinValue = 1)]
        public int UpdateFrequency { get; set; }

        [Parameter("Projection Line Color", DefaultValue = "DodgerBlue")]
        public Color LineColor { get; set; }

        [Parameter("Projection Line Width", DefaultValue = 2, MinValue = 1)]
        public int LineWidth { get; set; }

        [Parameter("Projection Line Style", DefaultValue = LineStyle.Solid)]
        public LineStyle LineStyleParam { get; set; }

        [Parameter("Show Equity Label", DefaultValue = true)]
        public bool ShowLabel { get; set; }

        [Parameter("Label PositiveChange Color", DefaultValue = "Green")]
        public Color LabelPositiveChangeColor { get; set; }

        [Parameter("Label Negative Change Color", DefaultValue = "Red")]
        public Color LabelNegativeChangeColor { get; set; }

        [Parameter("Initial Price Offset (pips)", DefaultValue = 50)]
        public double InitialPriceOffset { get; set; }

        // Global variables:
        private const string LineObjectName = "EquityProjectionLine";
        private const string EquityLabelObjectName = "EquityProjectionLabel";
        private ChartHorizontalLine projectionLine;
        private ChartText equityLabel;
        private double projectionPrice = 0;
        private double projectedEquity = 0;
        private double totalFloatingProfit = 0;
        private bool isVisible = true;

        protected override void Initialize()
        {
            // Check if the line already exists.
            projectionLine = Chart.FindObject(LineObjectName) as ChartHorizontalLine;
            
            if (projectionLine == null) // If the line doesn't exist yet.
            {
                // Initialize projection price near current price.
                projectionPrice = Symbol.Bid + (InitialPriceOffset * Symbol.PipSize);
                projectionPrice = Math.Round(projectionPrice, Symbol.Digits);
                
                DrawProjectionLine();
            }
            else
            {
                projectionPrice = projectionLine.Y;
            }

            CalculateProjectedEquity();

            // Set up timer for updates.
            Timer.Start(TimeSpan.FromSeconds(UpdateFrequency));

            // Subscribe to chart events.
            Chart.ObjectsUpdated += OnChartObjectsUpdated;
            Chart.KeyDown += OnChartKeyDown;
            Chart.ScrollChanged += OnChartScrollChanged;
            Chart.ZoomChanged += OnChartZoomChanged;
        }

        public override void Calculate(int index)
        {
            CalculateProjectedEquity();
        }

        protected override void OnTimer()
        {
            CalculateProjectedEquity();
        }

        private void OnChartObjectsUpdated(ChartObjectsUpdatedEventArgs obj)
        {
            if (obj.Chart.FindObject(LineObjectName) is ChartHorizontalLine line)
            {
                if (Math.Abs(line.Y - projectionPrice) > Symbol.TickSize)
                {
                    projectionPrice = Math.Round(line.Y, Symbol.Digits);
                    CalculateProjectedEquity();
                    UpdateLabel();
                }
            }
        }

        private void OnChartKeyDown(ChartKeyboardEventArgs obj)
        {
            // Toggle visibility with Shift+E.
            if (obj.Key == Key.E && (obj.ShiftKey))
            {
                isVisible = !isVisible;
                ToggleVisibility();
            }
        }

        private void OnChartScrollChanged(ChartScrollEventArgs obj)
        {
            UpdateLabel();
        }

        private void OnChartZoomChanged(ChartZoomEventArgs obj)
        {
            UpdateLabel();
        }

        private void CalculateProjectedEquity()
        {
            // Get current account information.
            double currentEquity = Account.Equity;
            
            // Calculate total P&L change for positions in current symbol.
            double totalPLChange = 0;
            
            double floatingProfit = 0;

            // Get all positions for current symbol.
            var symbolPositions = Positions.Where(p => p.SymbolName == Symbol.Name);

            foreach (var position in symbolPositions)
            {
                double posLots = position.VolumeInUnits;
                floatingProfit += position.NetProfit;
                // Calculate point value for this position.
                double pointValue = Symbol.PipValue * position.VolumeInUnits;
                
                // Calculate projected P&L at projection price.
                double projectedPL = 0;

                if (position.TradeType == TradeType.Buy)
                {
                    double priceDiff = projectionPrice - Symbol.Bid;
                    // Convert price difference to pips and calculate P&L.
                    projectedPL = (priceDiff / Symbol.PipSize) * pointValue;
                }
                else // Sell position.
                {
                    // For sell positions, we need to account for spread.
                    double spread = Symbol.Ask - Symbol.Bid;
                    double projectedAsk = projectionPrice + spread;
                    double priceDiff = Symbol.Ask - projectedAsk;
                    // Convert price difference to pips and calculate P&L.
                    projectedPL = (priceDiff / Symbol.PipSize) * pointValue;
                }
               
                totalPLChange += projectedPL;
            }

            // For output.
            totalFloatingProfit = totalPLChange + floatingProfit;

            // Calculate projected equity.
            projectedEquity = currentEquity + totalPLChange;

            // Update display.
            UpdateLabel();
        }

        private void DrawProjectionLine()
        {
            if (projectionPrice <= 0) return;

            // Remove existing line if it exists.
            if (projectionLine != null)
            {
                Chart.RemoveObject(LineObjectName);
            }

            // Create new horizontal line.
            projectionLine = Chart.DrawHorizontalLine(
                LineObjectName,
                projectionPrice,
                LineColor,
                LineWidth,
                LineStyleParam
            );
            
            projectionLine.IsInteractive = true;
            projectionLine.Comment = "Drag to change projection price";

            // Add or update label.
            UpdateLabel();
        }

        private void UpdateLabel()
        {
            if (projectionPrice <= 0 || !ShowLabel) return;

            // Ensure line exists.
            if (projectionLine == null || Chart.FindObject(LineObjectName) == null)
            {
                DrawProjectionLine();
            }

            // Remove existing label.
            if (equityLabel != null)
            {
                Chart.RemoveObject(EquityLabelObjectName);
            }

            // Format equity text with proper decimal places.
            string equityText = $"Equity: {projectedEquity:N2} {Account.Asset.Name} (Floating profit: {totalFloatingProfit:N2} {Account.Asset.Name})";

            // Calculate color based on equity change.
            double currentEquity = Account.Equity;
            Color equityColor = LineColor;
            if (projectedEquity > currentEquity)
                equityColor = LabelPositiveChangeColor;
            else if (projectedEquity < currentEquity)
                equityColor = LabelNegativeChangeColor;

            // Get the leftmost visible bar index.
            int firstVisibleBar = Chart.FirstVisibleBarIndex;
            
            // Create label at the left side of the chart.
            equityLabel = Chart.DrawText(
                EquityLabelObjectName,
                equityText,
                firstVisibleBar,
                projectionPrice,
                equityColor
            );

            equityLabel.FontSize = 12;
            equityLabel.HorizontalAlignment = HorizontalAlignment.Right;
            equityLabel.VerticalAlignment = VerticalAlignment.Top;
            equityLabel.IsInteractive = false;
        }

        private void ToggleVisibility()
        {
            if (isVisible)
            {
                // Hide objects.
                if (projectionLine != null)
                {
                    projectionLine.IsHidden = true;
                }
                if (equityLabel != null)
                {
                    equityLabel.IsHidden = true;
                }
            }
            else
            {
                // Show objects.
                if (projectionLine != null)
                {
                    projectionLine.IsHidden = false;
                }
                if (equityLabel != null)
                {
                    equityLabel.IsHidden = false;
                }
            }
        }
    }
}
//+------------------------------------------------------------------+