//+------------------------------------------------------------------+
//|                                            AEGIS_Pro_Manager.mq4 |
//|                    Copyright 2026, MetaQuotes Ltd.MR & Partner   |
//|    + VALLHALA Web API Authentication System (Opt Ver)            |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, MetaQuotes Ltd.MR & Coding Partner"
#property version   "4.00" // UI追加・残高%決済・起動チェック・ロットスケーリング統合版
#property strict

// ==========================================================================
// 【★開発者用セキュリティ設定 (コンパイル前に設定)】
// ==========================================================================
#define  LICENSE_ACC_ID     0             
#define  BROKER_KEYWORD     ""            
#define  USE_EXPIRY         false         
#define  EXPIRY_DATE        D'2030.12.31' 
// ==========================================================================

enum ENUM_TRAIL_MODE { MODE_SIMPLE = 0, MODE_MA = 1 };

enum ENUM_CORNER_ANCHOR {
   ANCHOR_TL = 0, // 左上 (Top-Left)
   ANCHOR_TR = 1, // 右上 (Top-Right)
   ANCHOR_BL = 2, // 左下 (Bottom-Left)
   ANCHOR_BR = 3  // 右下 (Bottom-Right)
};

// ==========================================================================
// パラメータ設定 (MT4のプロパティ画面に表示される項目名)
// ==========================================================================
input string          _s0 = "=== 基本設定 ==="; // 【基本設定】
input int             MagicNumber    = 0;          // マジックナンバー (0=手動ポジションも対象)
input int             Slippage       = 3;          // 許容スリッページ (pips)
input double          MaxSpread      = 5.0;        // 許容最大スプレッド (pips / 0で無効)

input string          _s1 = "=== トレーリング設定 (単体保有時) ==="; // 【単体ポジションのトレーリング設定】
input bool            UseTrailing    = true;       // トレーリング機能を使用する
input ENUM_TRAIL_MODE TrailMode      = MODE_MA;    // トレーリングの追従モード
input int             TrailMAPeriod  = 20;         // 移動平均線(MA)の期間 (MAモード用)
input double          TrailStart     = 15.0;       // トレーリングを開始する利益 (pips)
input double          TrailStep      = 5.0;        // ストップロスの更新幅・バッファ (pips)

input string          _s2 = "=== 救済ナンピン設定 (複数保有時) ==="; // 【救済ナンピン設定】
input bool            UseNanpin      = true;       // ナンピン機能を使用する
input int             MaxOrders      = 10;         // 最大ポジション数 (ナンピン回数上限)
input double          LotMultiplier  = 1.5;        // ナンピン時のロット倍率 (マーチンゲール)
input int             BaseGridPips   = 20;         // 初回ナンピン間隔 (pips)
input double          GridCoef       = 1.2;        // ナンピン間隔の拡大係数 (1.0で固定幅)

input string          _s3 = "=== 集合体決済 (バスケット: 口座残高%) ==="; // 【複数ポジションのバスケット決済設定】
input double          BasketTarget_Pct = 1.0;      // 基準の目標合計利益 (% / 例:1.0で残高の1%)
input double          BasketTrail_Pct  = 0.3;      // 基準の下落許容幅 (% / 例:0.3で残高の0.3%)
input bool            UseLotScaling    = true;     // ロット増加に合わせて目標額を拡大する

input string          _sNews = "=== 経済指標フィルター ==="; // 【経済指標フィルター設定】
input bool            UseNewsFilter  = true;       // 経済指標フィルターを使用する
input string          NewsTime       = "21:30";    // 指標発表時間 (パソコンの時計基準 HH:MM)
input int             NewsWaitBefore = 10;         // 発表前のナンピン停止・決済時間 (分前)
input int             NewsWaitAfter  = 30;         // 発表後のナンピン再開までの待機時間 (分後)
input double          MaxLossForNews = -500;       // 指標前決済を許容する最大含み損 (固定金額)

input string          _sNotify = "=== 通知・連携設定 ==="; // 【通知・連携設定】
input bool            UsePushNotify  = true;       // スマホ版MT4へのプッシュ通知を使用する
input bool            UseDiscord     = true;       // Discordへの画像付き通知を使用する
input string          DiscordWebhook = "ここにWebhook URLを入力"; // Discord Webhook URL

input string          _s4 = "=== リスク管理 (緊急停止) ==="; // 【リスク管理 (緊急停止)】
input double          MaxDD_Percent  = 20.0;       // このEAの許容最大ドローダウン (% / 0で無効)

input string          _sUI_Gen = "=== UIボタン設定 (共通) ==="; // 【UIボタン共通設定】
input ENUM_CORNER_ANCHOR UI_Corner   = ANCHOR_BR;  // 配置の基準となる角 (コーナー)
input int             UI_BtnWidth    = 130;        // ボタンの幅
input int             UI_BtnHeight   = 30;         // ボタンの高さ
input string          UI_Font        = "MS UI Gothic"; // ボタンのフォント (文字化け対策)

input string          _sUI_B1  = "--- [BUY 全決済] ボタン ---"; // 【BUY全決済ボタン】
input int             UI_B1_X        = 10;         // X座標 (基準角からの横距離)
input int             UI_B1_Y        = 60;         // Y座標 (基準角からの縦距離)

input string          _sUI_S1  = "--- [SELL 全決済] ボタン ---"; // 【SELL全決済ボタン】
input int             UI_S1_X        = 150;        // X座標 (基準角からの横距離)
input int             UI_S1_Y        = 60;         // Y座標 (基準角からの縦距離)

input string          _sUI_B2  = "--- [BUY 初期ポジ] ボタン ---"; // 【BUY初期ポジボタン】
input int             UI_B2_X        = 10;         // X座標 (基準角からの横距離)
input int             UI_B2_Y        = 20;         // Y座標 (基準角からの縦距離)

input string          _sUI_S2  = "--- [SELL 初期ポジ] ボタン ---"; // 【SELL初期ポジボタン】
input int             UI_S2_X        = 150;        // X座標 (基準角からの横距離)
input int             UI_S2_Y        = 20;         // Y座標 (基準角からの縦距離)

// --- グローバル変数
double G_Point;
int    G_Digits;
bool   IsAuthenticated = false;
bool   IsNewsPaused = false;

// トレーリング・通知用メモリ
double HighWaterMark_Buy = -99999999;
double HighWaterMark_Sell = -99999999;
bool   IsTrailing_Buy = false;
bool   IsTrailing_Sell = false;

// ブローカー決済検知用の配列とフラグ
int    G_ActiveTickets[];
bool   IsEACloseExecuting = false;

//+------------------------------------------------------------------+
//| 【VALLHALA Web API 認証システム用 変数と設定】                   |
//+------------------------------------------------------------------+
int     AuthRetryCount = 0;       // 現在のリトライ回数
const int MaxAuthRetries = 3;     // 最大リトライ回数
datetime LastAuthDate = 0;        // 最後に認証を行った「日」を記録

// URLの難読化 (公開用にDeployment IDをマスク処理済み)
string GetAuthUrl() {
    string part1 = "https://script.";
    string part2 = "google.com/macros/";
    string part3 = "s/YOUR_GAS_DEPLOYMENT_ID_HERE/"; // ポートフォリオ公開用プレースホルダー
    string part4 = "exec";
    return part1 + part2 + part3 + part4;
}

// 認証処理を実行する関数 (バックテスト軽量化＆HTTP400回避版)
bool CheckWebAuthentication() {
    if(IsTesting()) {
        IsAuthenticated = true;
        LastAuthDate = TimeCurrent(); 
        return true;
    }

    long accountNumber = AccountInfoInteger(ACCOUNT_LOGIN);
    string url = GetAuthUrl() + "?account=" + IntegerToString(accountNumber);
    
    char data[], result[];
    string resHeaders;
    
    int res = WebRequest("GET", url, "", 5000, data, result, resHeaders);
    
    if(res == 200 || res == 204) {
        string responseStr = CharArrayToString(result);
        if(StringFind(responseStr, "\"auth\":true") >= 0 || StringFind(responseStr, "\"auth\": true") >= 0) {
            IsAuthenticated = true;
            AuthRetryCount = 0; 
            LastAuthDate = TimeCurrent() - (TimeCurrent() % 86400); 
            Print("VALLHALA AEGIS: 口座認証に成功しました。");
            return true;
        } else {
            IsAuthenticated = false;
            Print("VALLHALA AEGIS: 未認証の口座です。サポートへご連絡ください。");
            return false;
        }
    } else {
        Print("VALLHALA AEGIS: 認証通信エラー [HTTP: ", res, " / 内部エラー: ", GetLastError(), "]");
        AuthRetryCount++;
        
        if(AuthRetryCount >= MaxAuthRetries) {
            Print("VALLHALA AEGIS: 通信エラーが規定回数に達したため、稼働を停止します。");
            IsAuthenticated = false;
            return false;
        }
        return true; 
    }
}

//+------------------------------------------------------------------+
//| Initialization                                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   if(Digits == 3 || Digits == 5) { G_Point = Point * 10; G_Digits = Digits - 1; } 
   else { G_Point = Point; G_Digits = Digits; }

   // 1. 既存のローカルライセンスチェック
   if (!CheckLicense()) return(INIT_FAILED);
   
   // 2. VALLHALA Web API 認証
   if(!CheckWebAuthentication()) {
       Alert("VALLHALA AEGIS: 未認証の口座です。EAを終了します。");
       return(INIT_FAILED);
   }

   // --- 起動チェックとテスト通知 ---
   Print("=== AEGIS Pro Manager 起動シーケンス開始 ===");
   bool isSetupOK = true;

   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) {
      Print("【エラー】MT4の「自動売買」が許可されていません！");
      isSetupOK = false;
   }
   if(UseDiscord && !IsDllsAllowed()) {
      Print("【警告】「DLLの使用を許可する」にチェックが入っていないためDiscord通知が送れません！");
   }

   if(isSetupOK) {
      Print("システムチェック完了: 正常に稼働を開始します。 [Magic: " + IntegerToString(MagicNumber) + "]");
      if(UsePushNotify || UseDiscord) {
         SendAppNotification("【起動テスト】AEGIS EAが正常にセットされ、監視を開始しました。");
      }
   } else {
       Print("【注意】システムチェックに問題があります。設定を見直してください。");
   }

   CreateUIButtons();

   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) 
{ 
   Comment(""); 
   ObjectsDeleteAll(0, "AEGIS_Btn_"); 
}

//+------------------------------------------------------------------+
//| Main Logic                                                       |
//+------------------------------------------------------------------+
void OnTick()
{
   // --- 日替わり時（1日1回）の定期再認証チェック ---
   datetime currentDate = TimeCurrent() - (TimeCurrent() % 86400); 
   if(currentDate > LastAuthDate) {
       if(!CheckWebAuthentication()) {
           Alert("VALLHALA AEGIS: 口座の認証が確認できません。機能を停止します。");
           ObjectsDeleteAll(0, "AEGIS_Btn_");
           Comment("");
           ExpertRemove(); 
           return;
       }
   }
   
   if (!IsAuthenticated) return;

   CheckEmergencyStop();
   UpdateNewsStatus();

   ManageLogic(OP_BUY);
   ManageLogic(OP_SELL);
   
   CheckBrokerClosures();
   UpdateDashboard();
}

//+------------------------------------------------------------------+
//| UI操作イベント (ボタンクリックの検知)                            |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == "AEGIS_Btn_BuyAll") {
         IsEACloseExecuting = true;
         if(CloseAll(OP_BUY)) SendAppNotification("【手動決済】BUYポジションを全決済しました。");
         CheckBrokerClosures(); IsEACloseExecuting = false;
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      }
      else if(sparam == "AEGIS_Btn_SellAll") {
         IsEACloseExecuting = true;
         if(CloseAll(OP_SELL)) SendAppNotification("【手動決済】SELLポジションを全決済しました。");
         CheckBrokerClosures(); IsEACloseExecuting = false;
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      }
      else if(sparam == "AEGIS_Btn_BuyPart") {
         IsEACloseExecuting = true;
         if(CloseOldest(OP_BUY)) SendAppNotification("【手動部分決済】BUYの初期ポジションを決済しました。");
         CheckBrokerClosures(); IsEACloseExecuting = false;
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      }
      else if(sparam == "AEGIS_Btn_SellPart") {
         IsEACloseExecuting = true;
         if(CloseOldest(OP_SELL)) SendAppNotification("【手動部分決済】SELLの初期ポジションを決済しました。");
         CheckBrokerClosures(); IsEACloseExecuting = false;
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
      }
   }
}

//+------------------------------------------------------------------+
//| サーバー(ブローカー)側の決済検知＆通知ロジック                   |
//+------------------------------------------------------------------+
void CheckBrokerClosures()
{
   int currentTickets[];
   int currentCount = 0;
   int i, j;

   for(i=0; i<OrdersTotal(); i++) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if(OrderSymbol() == Symbol() && (MagicNumber == 0 || OrderMagicNumber() == MagicNumber)) {
            ArrayResize(currentTickets, currentCount + 1);
            currentTickets[currentCount] = OrderTicket();
            currentCount++;
         }
      }
   }

   for(i=0; i<ArraySize(G_ActiveTickets); i++) {
      int oldTicket = G_ActiveTickets[i];
      bool stillOpen = false;
      for(j=0; j<currentCount; j++) {
         if(oldTicket == currentTickets[j]) { stillOpen = true; break; }
      }

      if(!stillOpen) {
         if(!IsEACloseExecuting) {
            if(OrderSelect(oldTicket, SELECT_BY_TICKET)) {
               if(OrderCloseTime() > 0) { 
                  double profit = OrderProfit() + OrderSwap() + OrderCommission();
                  string dir = (OrderType() == OP_BUY) ? "BUY" : "SELL";
                  string resultMsg = (profit >= 0) ? "【利確】" : "【損切】";
                  string msg = resultMsg + " 単体ポジション決済 (" + dir + ") 損益: " + DoubleToString(profit, 0) + "円";
                  SendAppNotification(msg);
               }
            } else {
               SendAppNotification("【決済通知】 ポジションが決済されました (チケット: " + IntegerToString(oldTicket) + ")");
            }
         }
      }
   }

   ArrayResize(G_ActiveTickets, currentCount);
   if(currentCount > 0) ArrayCopy(G_ActiveTickets, currentTickets);
}

//+------------------------------------------------------------------+
//| 管理ロジック (Buy/Sell独立)                                      |
//+------------------------------------------------------------------+
void ManageLogic(int type)
{
   int cnt = 0;
   double totalProfit = 0;
   double totalLot = 0;
   double maxLot = 0;
   double lastOpenPrice = 0;
   int lastTicket = -1;
   
   double initialLot = 0;
   datetime oldestTime = TimeCurrent() + 1000000;
   int i;
   
   for(i=OrdersTotal()-1; i>=0; i--) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if(OrderSymbol() == Symbol() && (MagicNumber == 0 || OrderMagicNumber() == MagicNumber) && OrderType() == type) {
            cnt++;
            totalProfit += OrderProfit() + OrderSwap() + OrderCommission();
            totalLot += OrderLots();
            
            if(OrderLots() > maxLot) maxLot = OrderLots();
            
            if(OrderOpenTime() < oldestTime) {
               oldestTime = OrderOpenTime();
               initialLot = OrderLots();
            }
            
            if(lastOpenPrice == 0) { 
               lastOpenPrice = OrderOpenPrice(); 
               lastTicket = OrderTicket(); 
            } else {
               if(type == OP_BUY && OrderOpenPrice() < lastOpenPrice) { lastOpenPrice = OrderOpenPrice(); lastTicket = OrderTicket(); }
               if(type == OP_SELL && OrderOpenPrice() > lastOpenPrice) { lastOpenPrice = OrderOpenPrice(); lastTicket = OrderTicket(); }
            }
         }
      }
   }
   
   if(cnt == 0) {
      if(type == OP_BUY)  { HighWaterMark_Buy = -99999999; IsTrailing_Buy = false; }
      if(type == OP_SELL) { HighWaterMark_Sell = -99999999; IsTrailing_Sell = false; }
      return;
   }

   // --- 指標前の自動逃避ロジック ---
   if(IsNewsPaused && totalProfit >= MaxLossForNews) {
      IsEACloseExecuting = true; 
      double expectedProfit = totalProfit;
      bool success = CloseAll(type);
      
      if(success) {
         string dir = (type == OP_BUY) ? "BUY" : "SELL";
         SendAppNotification("【指標回避】 " + dir + "側を自動決済しました。 損益: " + DoubleToString(expectedProfit, 0) + "円");
      }
      CheckBrokerClosures(); 
      IsEACloseExecuting = false;
      return;
   }

   // --- バスケット・トレーリング (残高%とロットスケーリングによる計算) ---
   double currentBalance = AccountBalance();
   double baseTargetAmount = currentBalance * (BasketTarget_Pct / 100.0);
   double baseTrailAmount  = currentBalance * (BasketTrail_Pct / 100.0);
   
   double lotMultiplier = 1.0;
   if(UseLotScaling && initialLot > 0 && totalLot > 0) {
       lotMultiplier = totalLot / initialLot;
   }
   
   double targetAmount = baseTargetAmount * lotMultiplier;
   double trailAmount  = baseTrailAmount * lotMultiplier;

   bool isBasketClosing = false;
   if(type == OP_BUY) {
      if(totalProfit > targetAmount) IsTrailing_Buy = true;
      if(IsTrailing_Buy) {
         if(totalProfit > HighWaterMark_Buy) HighWaterMark_Buy = totalProfit;
         if(trailAmount == 0 || totalProfit < HighWaterMark_Buy - trailAmount) isBasketClosing = true;
      }
   } else { 
      if(totalProfit > targetAmount) IsTrailing_Sell = true;
      if(IsTrailing_Sell) {
         if(totalProfit > HighWaterMark_Sell) HighWaterMark_Sell = totalProfit;
         if(trailAmount == 0 || totalProfit < HighWaterMark_Sell - trailAmount) isBasketClosing = true;
      }
   }
   
   if(isBasketClosing) {
      IsEACloseExecuting = true; 
      double expectedProfit = totalProfit; 
      
      bool success = CloseAll(type); 
      
      if(success) {
         string dir = (type == OP_BUY) ? "BUY" : "SELL";
         SendAppNotification("【利確報告】 " + dir + "のバスケット決済完了！ 利益: +" + DoubleToString(expectedProfit, 0) + "円");
      }
      CheckBrokerClosures(); 
      IsEACloseExecuting = false;
      return; 
   }

   // --- 単体トレーリング ---
   if(cnt == 1 && UseTrailing) {
      RunSingleTrail(type, lastTicket);
   }

   // --- 変則ナンピン ---
   double currentSpreadPips = MarketInfo(Symbol(), MODE_SPREAD) * Point / G_Point;
   bool spreadCheck = (MaxSpread <= 0) || (currentSpreadPips <= MaxSpread);

   if(UseNanpin && cnt < MaxOrders && spreadCheck && !IsNewsPaused) {
      double gridPips = BaseGridPips * MathPow(GridCoef, cnt - 1);
      double gridPriceDist = gridPips * G_Point;
      int ticket = -1;
      
      if(type == OP_BUY && Ask <= lastOpenPrice - gridPriceDist) {
         ticket = OrderSend(Symbol(), OP_BUY, NormalizeDouble(maxLot * LotMultiplier, 2), Ask, Slippage, 0, 0, "AEGIS_Grid", MagicNumber, 0, clrDodgerBlue);
         if(ticket < 0) Print("OrderSend Error (Buy): ", GetLastError());
      } 
      else if(type == OP_SELL && Bid >= lastOpenPrice + gridPriceDist) {
         ticket = OrderSend(Symbol(), OP_SELL, NormalizeDouble(maxLot * LotMultiplier, 2), Bid, Slippage, 0, 0, "AEGIS_Grid", MagicNumber, 0, clrDeepPink);
         if(ticket < 0) Print("OrderSend Error (Sell): ", GetLastError());
      }
   }
}

//+------------------------------------------------------------------+
//| UIボタンの作成 (完全フリー配置版)                                |
//+------------------------------------------------------------------+
void CreateButton(string name, string text, int x, int y, color bg_color) {
   if(ObjectFind(0, name) < 0) ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, UI_BtnWidth);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, UI_BtnHeight);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg_color);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_CORNER, UI_Corner);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
   ObjectSetString(0, name, OBJPROP_FONT, UI_Font); 
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_STATE, false);
}

void CreateUIButtons() {
   CreateButton("AEGIS_Btn_BuyAll",  "BUY 全決済", UI_B1_X, UI_B1_Y, clrFireBrick);
   CreateButton("AEGIS_Btn_SellAll", "SELL 全決済", UI_S1_X, UI_S1_Y, clrFireBrick);
   CreateButton("AEGIS_Btn_BuyPart", "BUY 初期ポジ決済", UI_B2_X, UI_B2_Y, clrChocolate);
   CreateButton("AEGIS_Btn_SellPart","SELL 初期ポジ決済", UI_S2_X, UI_S2_Y, clrChocolate);
}

//+------------------------------------------------------------------+
//| 単体トレーリング実行                                             |
//+------------------------------------------------------------------+
void RunSingleTrail(int type, int ticket)
{
   if(!OrderSelect(ticket, SELECT_BY_TICKET)) return;
   
   double currentPrice = (type == OP_BUY) ? Bid : Ask;
   double openPrice = OrderOpenPrice();
   double currentSL = OrderStopLoss();
   double newSL = 0;
   
   double profitPips = MathAbs(currentPrice - openPrice) / G_Point;
   if(profitPips < TrailStart) return;

   if(TrailMode == MODE_SIMPLE) {
      if(type == OP_BUY) {
         newSL = Bid - (TrailStep * G_Point);
         if(newSL < openPrice) newSL = openPrice + (Point * 10); 
      } else {
         newSL = Ask + (TrailStep * G_Point);
         if(newSL > openPrice) newSL = openPrice - (Point * 10);
      }
   } 
   else if(TrailMode == MODE_MA) {
      double ma = iMA(NULL, 0, TrailMAPeriod, 0, MODE_SMA, PRICE_CLOSE, 1);
      if(type == OP_BUY) {
         if(ma > openPrice && Bid > ma) newSL = ma - (TrailStep * G_Point);
         else return;
      } else {
         if(ma < openPrice && Ask < ma) newSL = ma + (TrailStep * G_Point);
         else return;
      }
   }

   double stopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;
   bool modify = false;

   if(type == OP_BUY) {
      if(newSL > currentSL + (Point*5) && newSL < Bid - stopLevel) modify = true;
   } else {
      if((currentSL == 0 || newSL < currentSL - (Point*5)) && newSL > Ask + stopLevel) modify = true;
   }

   if(modify) {
      if(!OrderModify(ticket, openPrice, newSL, OrderTakeProfit(), 0, clrGreen)) {
         Print("Trail Modify Error: ", GetLastError());
      }
   }
}

//+------------------------------------------------------------------+
//| 全決済関数                                                       |
//+------------------------------------------------------------------+
bool CloseAll(int type)
{
   bool allClosed = true;
   int retryCount = 3;
   int i, k;
   
   for(i=OrdersTotal()-1; i>=0; i--) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if(OrderSymbol() == Symbol() && (MagicNumber == 0 || OrderMagicNumber() == MagicNumber) && OrderType() == type) {
            
            bool res = false;
            for(k=0; k<retryCount; k++) {
               RefreshRates();
               double closePrice = (type == OP_BUY) ? MarketInfo(Symbol(), MODE_BID) : MarketInfo(Symbol(), MODE_ASK);
               res = OrderClose(OrderTicket(), OrderLots(), closePrice, Slippage, clrGray);
               if(res) break; 
               else Sleep(500); 
            }
            if(!res) allClosed = false;
         }
      }
   }
   
   if(allClosed) {
      if(type == OP_BUY) { IsTrailing_Buy = false; HighWaterMark_Buy = -99999999; }
      if(type == OP_SELL){ IsTrailing_Sell = false; HighWaterMark_Sell = -99999999; }
   }
   
   return allClosed;
}

//+------------------------------------------------------------------+
//| 最も古いポジション(初期ポジ)を1つだけ部分決済する関数            |
//+------------------------------------------------------------------+
bool CloseOldest(int type)
{
   int oldestTicket = -1;
   datetime oldestTime = TimeCurrent() + 1000000;
   int i;
   
   for(i=OrdersTotal()-1; i>=0; i--) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if(OrderSymbol() == Symbol() && (MagicNumber == 0 || OrderMagicNumber() == MagicNumber) && OrderType() == type) {
            if(OrderOpenTime() < oldestTime) {
               oldestTime = OrderOpenTime();
               oldestTicket = OrderTicket();
            }
         }
      }
   }
   
   if(oldestTicket != -1) {
      if(OrderSelect(oldestTicket, SELECT_BY_TICKET)) {
         RefreshRates();
         double closePrice = (type == OP_BUY) ? MarketInfo(Symbol(), MODE_BID) : MarketInfo(Symbol(), MODE_ASK);
         return OrderClose(OrderTicket(), OrderLots(), closePrice, Slippage, clrGray);
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| 緊急停止                                                         |
//+------------------------------------------------------------------+
void CheckEmergencyStop()
{
   if(MaxDD_Percent <= 0) return;
   double eaTotalProfit = 0;
   int i;
   
   for(i=0; i<OrdersTotal(); i++) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if(OrderSymbol() == Symbol() && (MagicNumber == 0 || OrderMagicNumber() == MagicNumber)) {
            eaTotalProfit += OrderProfit() + OrderSwap() + OrderCommission();
         }
      }
   }
   
   double balance = AccountBalance();
   if(eaTotalProfit < 0 && balance > 0) {
      double ddPercent = (MathAbs(eaTotalProfit) / balance) * 100.0;
      if(ddPercent >= MaxDD_Percent) {
         IsEACloseExecuting = true;
         bool s1 = CloseAll(OP_BUY);
         bool s2 = CloseAll(OP_SELL);
         if(s1 && s2) {
            SendAppNotification("【緊急停止】 許容ドローダウンを超過したため全決済しました。");
         }
         CheckBrokerClosures();
         IsEACloseExecuting = false;
      }
   }
}

//+------------------------------------------------------------------+
//| 経済指標フィルター                                               |
//+------------------------------------------------------------------+
void UpdateNewsStatus()
{
   if(!UseNewsFilter) { IsNewsPaused = false; return; }
   
   MqlDateTime dt; TimeToStruct(TimeCurrent(), dt);
   string parts[]; StringSplit(NewsTime, ':', parts);
   if(ArraySize(parts) != 2) return;
   
   dt.hour = (int)StringToInteger(parts[0]);
   dt.min  = (int)StringToInteger(parts[1]);
   dt.sec  = 0;
   datetime nTime = StructToTime(dt);
   
   datetime startWait = nTime - NewsWaitBefore * 60;
   datetime endWait   = nTime + NewsWaitAfter * 60;
   
   if(TimeCurrent() >= startWait && TimeCurrent() <= endWait) IsNewsPaused = true;
   else IsNewsPaused = false;
}

//+------------------------------------------------------------------+
//| 通知送信統合関数                                                 |
//+------------------------------------------------------------------+
void SendAppNotification(string msg)
{
   string fullMsg = "[AEGIS Pro] " + Symbol() + " " + msg;
   Print("通知送信試行: " + fullMsg); 
   
   if(UsePushNotify) SendNotification(fullMsg);
   
   if(UseDiscord && StringFind(DiscordWebhook, "http") == 0) {
      string cleanUrl = DiscordWebhook;
      StringTrimLeft(cleanUrl); StringTrimRight(cleanUrl); 

      string fileName = "AEGIS_" + Symbol() + "_" + IntegerToString((int)TimeCurrent()) + ".gif";
      ChartRedraw(0);
      WindowScreenShot(fileName, 1280, 960, -1, -1, -1);
      
      Sleep(1000); 
      
      if(!SendDiscordImage(cleanUrl, fullMsg, fileName)) {
         Print("Discord画像送信失敗。テキストのみで送信します。");
         SendDiscordText(cleanUrl, fullMsg);
      }
   }
}

//+------------------------------------------------------------------+
//| Discord送信系 (画像)                                             |
//+------------------------------------------------------------------+
bool SendDiscordImage(string webhookUrl, string message, string filename) {
   char data[], fileData[];
   string boundary = "----AEGISBoundary" + IntegerToString(GetTickCount());
   
   int handle = FileOpen(filename, FILE_READ|FILE_BIN);
   if(handle == INVALID_HANDLE) { Print("画像ファイルが開けません: ", GetLastError()); return false; }
   int size = (int)FileSize(handle);
   FileReadArray(handle, fileData, 0, size);
   FileClose(handle);
   
   string header = "--" + boundary + "\r\n";
   header += "Content-Disposition: form-data; name=\"content\"\r\n\r\n" + message + "\r\n";
   header += "--" + boundary + "\r\n";
   header += "Content-Disposition: form-data; name=\"file\"; filename=\"" + filename + "\"\r\nContent-Type: image/gif\r\n\r\n";
   
   string footer = "\r\n--" + boundary + "--\r\n";
   
   int headerLen = StringToCharArray(header, data, 0, WHOLE_ARRAY, CP_UTF8) - 1; 
   char footerData[]; 
   int footerLen = StringToCharArray(footer, footerData, 0, WHOLE_ARRAY, CP_UTF8) - 1;

   ArrayResize(data, headerLen + size + footerLen);
   ArrayCopy(data, fileData, headerLen, 0, size);
   ArrayCopy(data, footerData, headerLen + size, 0, footerLen);

   char result[];
   string resHeaders; 
   string reqHeaders = "Content-Type: multipart/form-data; boundary=" + boundary + "\r\n";
   int res = WebRequest("POST", webhookUrl, reqHeaders, 10000, data, result, resHeaders);
   
   if(res != 200 && res != 204) {
      string errBody = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
      Print("Discord Image WebRequest Error: ", res, " Details: ", errBody); 
   }
   return (res == 200 || res == 204);
}

//+------------------------------------------------------------------+
//| Discord送信系 (テキスト)                                         |
//+------------------------------------------------------------------+
bool SendDiscordText(string webhookUrl, string message) {
   char data[], result[];
   string resHeaders;
   string json = "{\"content\": \"" + message + "\"}";
   
   int len = StringToCharArray(json, data, 0, WHOLE_ARRAY, CP_UTF8);
   ArrayResize(data, len - 1); 
   
   string reqHeaders = "Content-Type: application/json\r\n";
   int res = WebRequest("POST", webhookUrl, reqHeaders, 10000, data, result, resHeaders);
   if(res != 200 && res != 204) {
      string errBody = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
      Print("Discord Text WebRequest Error: ", res, " Details: ", errBody);
   }
   return (res == 200 || res == 204);
}

//+------------------------------------------------------------------+
//| 本日の合計確定利益                                               |
//+------------------------------------------------------------------+
double CalculateTodayProfit()
{
   double todayProfit = 0;
   int currentDay = TimeDay(TimeCurrent());
   int currentMonth = TimeMonth(TimeCurrent());
   int i;
   
   for(i = OrdersHistoryTotal() - 1; i >= 0; i--) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) {
         if(OrderSymbol() == Symbol() && (MagicNumber == 0 || OrderMagicNumber() == MagicNumber)) {
            if(TimeDay(OrderCloseTime()) == currentDay && TimeMonth(OrderCloseTime()) == currentMonth) {
               todayProfit += OrderProfit() + OrderSwap() + OrderCommission();
            }
         }
      }
   }
   return todayProfit;
}

//+------------------------------------------------------------------+
//| ライセンス                                                       |
//+------------------------------------------------------------------+
bool CheckLicense() {
   string msg = "";
   if (LICENSE_ACC_ID != 0 && AccountNumber() != LICENSE_ACC_ID) { msg = "認証エラー"; Alert(msg); return false; }
   if (StringLen(BROKER_KEYWORD) > 0 && StringFind(AccountCompany(), BROKER_KEYWORD) < 0) { msg = "認証エラー"; Alert(msg); return false; }
   if (USE_EXPIRY && TimeCurrent() >= EXPIRY_DATE) { msg = "試用期間終了"; Alert(msg); return false; }
   return true;
}

//+------------------------------------------------------------------+
//| ダッシュボード表示                                               |
//+------------------------------------------------------------------+
void UpdateDashboard()
{
   string text = "================================\n";
   text += "  AEGIS Pro Manager  |  " + Symbol() + "\n";
   text += "================================\n";
   
   double totalProfit = 0;
   int buyCnt = 0, sellCnt = 0;
   
   double initialLot_Buy = 0, totalLot_Buy = 0;
   double initialLot_Sell = 0, totalLot_Sell = 0;
   datetime oldestTime_Buy = TimeCurrent() + 1000000;
   datetime oldestTime_Sell = TimeCurrent() + 1000000;
   int i;
   
   for(i=0; i<OrdersTotal(); i++) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if(OrderSymbol() == Symbol() && (MagicNumber == 0 || OrderMagicNumber() == MagicNumber)) {
            totalProfit += OrderProfit() + OrderSwap() + OrderCommission();
            
            if(OrderType() == OP_BUY) {
               buyCnt++;
               totalLot_Buy += OrderLots();
               if(OrderOpenTime() < oldestTime_Buy) { oldestTime_Buy = OrderOpenTime(); initialLot_Buy = OrderLots(); }
            }
            if(OrderType() == OP_SELL) {
               sellCnt++;
               totalLot_Sell += OrderLots();
               if(OrderOpenTime() < oldestTime_Sell) { oldestTime_Sell = OrderOpenTime(); initialLot_Sell = OrderLots(); }
            }
         }
      }
   }
   
   double todayRealized = CalculateTodayProfit();
   double currentBalance = AccountBalance();
   double baseTarget  = currentBalance * (BasketTarget_Pct / 100.0);
   
   double target_Buy = 0, target_Sell = 0;
   if(buyCnt > 0)  target_Buy  = baseTarget * (UseLotScaling && initialLot_Buy > 0 ? (totalLot_Buy / initialLot_Buy) : 1.0);
   if(sellCnt > 0) target_Sell = baseTarget * (UseLotScaling && initialLot_Sell > 0 ? (totalLot_Sell / initialLot_Sell) : 1.0);
   
   string targetStr = "";
   if(buyCnt == 0 && sellCnt == 0) targetStr = DoubleToString(baseTarget, 0) + " " + AccountCurrency() + " (基準)";
   else {
      if(buyCnt > 0) targetStr += "[BUY] " + DoubleToString(target_Buy, 0) + "  ";
      if(sellCnt > 0) targetStr += "[SELL] " + DoubleToString(target_Sell, 0) + "  ";
   }

   text += "【本日の確定利益】: +" + DoubleToString(todayRealized, 0) + " " + AccountCurrency() + "\n";
   text += "【現在設定の目標値】: " + targetStr + "\n";
   text += "--------------------------------\n";
   text += "現在含み損益: " + DoubleToString(totalProfit, 0) + "\n";
   text += "買ポジション: " + IntegerToString(buyCnt) + "  |  売ポジション: " + IntegerToString(sellCnt) + "\n";
   text += "--------------------------------\n";
   
   if(IsNewsPaused) text += "[!] 経済指標待機中 (ナンピン一時停止)\n";
   if(IsTrailing_Buy) text += "[BUY] 回収モード (最高益: " + DoubleToString(HighWaterMark_Buy, 0) + ")\n";
   if(IsTrailing_Sell)text += "[SELL] 回収モード (最高益: " + DoubleToString(HighWaterMark_Sell, 0) + ")\n";
   
   Comment(text);
}
//+------------------------------------------------------------------+
