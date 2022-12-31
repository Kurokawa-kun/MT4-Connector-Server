//+------------------------------------------------------------------+
//|                                                     CallFunc.mqh |
//|                                         Copyright 2022, Kurokawa |
//|                                   https://twitter.com/ImKurokawa |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Kurokawa"
#property link      "https://twitter.com/ImKurokawa"
#property strict
#include <WinUser32.mqh>
#include <PipeServer.mqh>
#include <Message.mqh>
#include <FuncInfo.mqh>

//  クライアントからのリクエストに応じてMT4の関数を呼び出す。
//  ExternalConnector.mq4のソースコードが長くなるため別ファイルに分離している。

int ClientTimerInterval; //  クライアントのOnTimer呼び出しのインターバル（ミリ秒）。

//  この取引プラットフォームのバージョンを取得する。MT4かMT5かを判定するため（将来の機能拡張用）
int GetPlatformVersion()
{
#ifdef __MQL4__
   return 4;
#endif
#ifdef __MQL5__
   return 5;
#endif
}

//  6文字のランダムな文字列を取得する。同一シンボル同一時間足で複数の名前付きパイプを作成しても名前が被らないようにするために使う…
string GetRandomString()
{
   string RandomCodeStr = "";
   string Hash = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";   
   int len = StringLen(Hash);
   for (int c=0; c<6; c++)
   {
      int p = MathRand() % len;
      string st = StringSubstr(Hash, p, 1);
      RandomCodeStr = StringConcatenate(RandomCodeStr, st);
   }
   return RandomCodeStr;
}

//  デバッグメッセージの出力
void PrintDebugMessage(string message)
{
   if (GlobalVariableGet("DebugMessage") != 0) Print(message);
   return;
}

//  ストラテジーテスターを一時停止する
void PauseStrategyTester()
{
    int hwnd = WindowHandle(Symbol(), Period());
    PostMessageA(hwnd, WM_KEYDOWN, 19, 0);
    PostMessageA(hwnd, WM_KEYUP, 19, 0);
    return;
}

//  サマータイム期間中かを返す（米国式サマータイム）。
bool IsSummerTime(datetime t)
{
   datetime SummerTimeStart = StringToTime(StringConcatenate(
      IntegerToString(TimeYear(t)), ".",
      IntegerToString(3), ".",
      IntegerToString(8), " ", "2:00:00"));
   
   //  3月の第2日曜日AM2:00を探す
   while (TimeDayOfWeek(SummerTimeStart)!=0)
   {
      SummerTimeStart+=86400;
   }
   
   datetime WinterTimeStart = StringToTime(StringConcatenate(
      IntegerToString(TimeYear(t)), ".",
      IntegerToString(11), ".",
      IntegerToString(1), " ", "2:00"));
   
   //  11月の第1日曜日AM2:00を探す
   while (TimeDayOfWeek(WinterTimeStart)!=0)
   {
      WinterTimeStart+=86400;
   }
   
   if (SummerTimeStart<=t && t<WinterTimeStart)
   {
      return true;
   }
   else
   {
      return false;
   }
}

//  クライアントが指定したMT4のローカル関数を実行する
void CallFunc(FuncInfo &funcInfo)
{
   int z = 0;
   ResetLastError();
   PrintDebugMessage(StringFormat("指定されたローカル関数の呼び出しを行います'%s'。", funcInfo.FuncName));
   
   //  独自追加した関数
   if (funcInfo.FuncName == "GetPlatformVersion")
   {
      funcInfo.ReturnValue.SetData(
         GetPlatformVersion()
      );
   }
   else if (funcInfo.FuncName == "IsSummerTime")
   {
      IsSummerTime(funcInfo.Parameter[0].GetDataDateTime());
   }   
   //  MQL4/MQL5固有の関数
   else if (funcInfo.FuncName == "PlaySound")
   {
      PlaySound(funcInfo.Parameter[0].GetDataString());
   }   
   else if (funcInfo.FuncName == "CopyOpen")
   {
      double data[100];
      ArrayResize(data, MAX_NUMBER_OF_AUXILIARIES, 0);
      funcInfo.ReturnValue.SetData(
         CopyOpen(funcInfo.Parameter[0].GetDataString(), 
            funcInfo.Parameter[1].GetDataInt(), 
            funcInfo.Parameter[2].GetDataInt(), 
            funcInfo.Parameter[3].GetDataInt(), 
            data
         )
      );
      for (int i = 0; i < funcInfo.ReturnValue.GetDataInt(); i++)
      {
         funcInfo.Auxiliary[i].SetData(data[i]);
      }
      ArrayFree(data);
   }
   else if (funcInfo.FuncName == "CopyHigh")
   {
      double data[100];
      ArrayResize(data, MAX_NUMBER_OF_AUXILIARIES, 0);
      funcInfo.ReturnValue.SetData(
         CopyHigh(funcInfo.Parameter[0].GetDataString(), 
            funcInfo.Parameter[1].GetDataInt(), 
            funcInfo.Parameter[2].GetDataInt(), 
            funcInfo.Parameter[3].GetDataInt(), 
            data
         )
      );
      for (int i = 0; i < funcInfo.ReturnValue.GetDataInt(); i++)
      {
         funcInfo.Auxiliary[i].SetData(data[i]);
      }
      ArrayFree(data);
   }
   else if (funcInfo.FuncName == "CopyLow")
   {
      double data[100];
      ArrayResize(data, MAX_NUMBER_OF_AUXILIARIES, 0);
      funcInfo.ReturnValue.SetData(
         CopyLow(funcInfo.Parameter[0].GetDataString(), 
            funcInfo.Parameter[1].GetDataInt(), 
            funcInfo.Parameter[2].GetDataInt(), 
            funcInfo.Parameter[3].GetDataInt(), 
            data
         )
      );
      for (int i = 0; i < funcInfo.ReturnValue.GetDataInt(); i++)
      {
         funcInfo.Auxiliary[i].SetData(data[i]);
      }
      ArrayFree(data);
   }
   else if (funcInfo.FuncName == "CopyClose")
   {
      double data[100];
      ArrayResize(data, MAX_NUMBER_OF_AUXILIARIES, 0);
      funcInfo.ReturnValue.SetData(
         CopyClose(funcInfo.Parameter[0].GetDataString(), 
            funcInfo.Parameter[1].GetDataInt(), 
            funcInfo.Parameter[2].GetDataInt(), 
            funcInfo.Parameter[3].GetDataInt(), 
            data
         )
      );
      for (int i = 0; i < funcInfo.ReturnValue.GetDataInt(); i++)
      {
         funcInfo.Auxiliary[i].SetData(data[i]);
      }
      ArrayFree(data);
   }
   else if (funcInfo.FuncName == "CopyTickVolume")
   {
      long ldata[100];
      ArrayResize(ldata, MAX_NUMBER_OF_AUXILIARIES, 0);
      funcInfo.ReturnValue.SetData(
         CopyTickVolume(funcInfo.Parameter[0].GetDataString(), 
            funcInfo.Parameter[1].GetDataInt(), 
            funcInfo.Parameter[2].GetDataInt(), 
            funcInfo.Parameter[3].GetDataInt(), 
            ldata
         )
      );
      for (int i = 0; i < funcInfo.ReturnValue.GetDataInt(); i++)
      {
         funcInfo.Auxiliary[i].SetData(ldata[i]);
      }
      ArrayFree(ldata);
   }
   else if (funcInfo.FuncName == "CopyTime")
   {
      datetime tdata[100];
      ArrayResize(tdata, MAX_NUMBER_OF_AUXILIARIES, 0);
      funcInfo.ReturnValue.SetData(
         CopyTime(funcInfo.Parameter[0].GetDataString(), 
            funcInfo.Parameter[1].GetDataInt(), 
            funcInfo.Parameter[2].GetDataInt(), 
            funcInfo.Parameter[3].GetDataInt(), 
            tdata
         )
      );
      for (int i = 0; i < funcInfo.ReturnValue.GetDataInt(); i++)
      {
         funcInfo.Auxiliary[i].SetData(tdata[i]);
      }
      ArrayFree(tdata);
   }
   else if (funcInfo.FuncName == "iBars")
   {
      funcInfo.ReturnValue.SetData(
         iBars(funcInfo.Parameter[0].GetDataString(), funcInfo.Parameter[1].GetDataInt())
      );
   }
   else if (funcInfo.FuncName == "TimeCurrent")
   {
      funcInfo.ReturnValue.SetData(
         TimeCurrent()
      );
   }
   else if (funcInfo.FuncName == "TimeLocal")
   {
      funcInfo.ReturnValue.SetData(
         TimeLocal()
      );
   }
   
   else if (funcInfo.FuncName == "TimeGMT")
   {
      funcInfo.ReturnValue.SetData(
         TimeGMT()
      );
   }
   else if (funcInfo.FuncName == "TimeDaylightSavings")
   {
      funcInfo.ReturnValue.SetData(
         TimeDaylightSavings()
      );
   }
   else if (funcInfo.FuncName == "AccountInfoInteger")
   {
      funcInfo.ReturnValue.SetData(
         AccountInfoInteger(funcInfo.Parameter[0].GetDataInt())
      );
   }
   else if (funcInfo.FuncName == "AccountInfoDouble")
   {
      funcInfo.ReturnValue.SetData(
         AccountInfoDouble(funcInfo.Parameter[0].GetDataInt())
      );
   }
   else if (funcInfo.FuncName == "AccountInfoString")
   {
      funcInfo.ReturnValue.SetData(
         AccountInfoString(funcInfo.Parameter[0].GetDataInt())
      );
   }
   else if (funcInfo.FuncName == "AccountBalance")
   {
      funcInfo.ReturnValue.SetData(
         AccountBalance()
      );
   }
   else if (funcInfo.FuncName == "AccountCredit")
   {
      funcInfo.ReturnValue.SetData(
         AccountCredit()
      );
   }
   else if (funcInfo.FuncName == "AccountCompany")
   {
      funcInfo.ReturnValue.SetData(
         AccountCompany()
      );
   }
   else if (funcInfo.FuncName == "AccountCurrency")
   {
      funcInfo.ReturnValue.SetData(
         AccountCurrency()
      );
   }
   else if (funcInfo.FuncName == "AccountEquity")
   {
      funcInfo.ReturnValue.SetData(
         AccountEquity()
      );
   }
   else if (funcInfo.FuncName == "AccountFreeMargin")
   {
      funcInfo.ReturnValue.SetData(
         AccountFreeMargin()
      );
   }
   else if (funcInfo.FuncName == "AccountFreeMarginCheck")
   {
      funcInfo.ReturnValue.SetData(
         AccountFreeMarginCheck(
            funcInfo.Parameter[0].GetDataString(),
            funcInfo.Parameter[1].GetDataInt(),
            funcInfo.Parameter[2].GetDataDouble()         
         )
      );
   }
   else if (funcInfo.FuncName == "AccountFreeMarginMode")
   {
      funcInfo.ReturnValue.SetData(
         AccountFreeMarginMode()
      );
   }
   else if (funcInfo.FuncName == "AccountLeverage")
   {
      funcInfo.ReturnValue.SetData(
         AccountLeverage()
      );
   }
   else if (funcInfo.FuncName == "AccountMargin")
   {
      funcInfo.ReturnValue.SetData(
         AccountMargin()
      );
   }
   else if (funcInfo.FuncName == "AccountName")
   {
      funcInfo.ReturnValue.SetData(
         AccountName()
      );
   }
   else if (funcInfo.FuncName == "AccountNumber")
   {
      funcInfo.ReturnValue.SetData(
         AccountNumber()
      );
   }
   else if (funcInfo.FuncName == "AccountProfit")
   {
      funcInfo.ReturnValue.SetData(
         AccountProfit()
      );
   }
   else if (funcInfo.FuncName == "AccountServer")
   {
      funcInfo.ReturnValue.SetData(
         AccountServer()
      );
   }
   else if (funcInfo.FuncName == "AccountStopoutLevel")
   {
      funcInfo.ReturnValue.SetData(
         AccountStopoutLevel()
      );
   }
   else if (funcInfo.FuncName == "AccountStopoutMode")
   {
      funcInfo.ReturnValue.SetData(
         AccountStopoutMode()
      );
   }
   else if (funcInfo.FuncName == "IsStopped")
   {
      funcInfo.ReturnValue.SetData(
         IsStopped()
      );
   }
   else if (funcInfo.FuncName == "UninitializeReason")
   {
      funcInfo.ReturnValue.SetData(
         UninitializeReason()
      );
   }
   else if (funcInfo.FuncName == "TerminalInfoInteger")
   {
      funcInfo.ReturnValue.SetData(
         TerminalInfoInteger(funcInfo.Parameter[0].GetDataInt())
      );
   }
   else if (funcInfo.FuncName == "TerminalInfoDouble")
   {
      funcInfo.ReturnValue.SetData(
         TerminalInfoDouble(funcInfo.Parameter[0].GetDataInt())
      );
   }
   else if (funcInfo.FuncName == "TerminalInfoString")
   {
      funcInfo.ReturnValue.SetData(
         TerminalInfoString(funcInfo.Parameter[0].GetDataInt())
      );
   }
   else if (funcInfo.FuncName == "MQLInfoInteger")
   {
      funcInfo.ReturnValue.SetData(
         MQLInfoInteger(funcInfo.Parameter[0].GetDataInt())
      );
   }
   else if (funcInfo.FuncName == "MQLInfoString")
   {
      funcInfo.ReturnValue.SetData(
         MQLInfoString(funcInfo.Parameter[0].GetDataInt())
      );
   }
   else if (funcInfo.FuncName == "MQLSetInteger")
   {
      funcInfo.ReturnValue.SetData(
         MQLSetInteger(
            funcInfo.Parameter[0].GetDataInt(), 
            funcInfo.Parameter[1].GetDataInt())
      );
   }
   else if (funcInfo.FuncName == "OrderSend")
   {
      funcInfo.ReturnValue.SetData(
         OrderSend(funcInfo.Parameter[0].GetDataString(), funcInfo.Parameter[1].GetDataInt(), funcInfo.Parameter[2].GetDataDouble(), funcInfo.Parameter[3].GetDataDouble(), funcInfo.Parameter[4].GetDataInt(), funcInfo.Parameter[5].GetDataDouble(), funcInfo.Parameter[6].GetDataDouble(), 
            funcInfo.Parameter[7].IsEmpty() ? funcInfo.Parameter[7].GetDataString() : NULL, 
            funcInfo.Parameter[8].IsEmpty() ? (int)funcInfo.Parameter[8].GetDataInt() : 0, 
            funcInfo.Parameter[9].IsEmpty() ? (datetime)funcInfo.Parameter[9].GetDataDateTime() : (datetime)0, 
            funcInfo.Parameter[10].IsEmpty() ? funcInfo.Parameter[10].GetDataColor() : clrNONE)
      );
   }
   else if (funcInfo.FuncName == "OrderClose")
   {
      funcInfo.ReturnValue.SetData(
         OrderClose(funcInfo.Parameter[0].GetDataInt(), funcInfo.Parameter[1].GetDataDouble(), funcInfo.Parameter[2].GetDataDouble(), funcInfo.Parameter[3].GetDataInt(), funcInfo.Parameter[4].IsEmpty() ? funcInfo.Parameter[4].GetDataColor() : clrNONE)
      );
   }
   else if (funcInfo.FuncName == "OrderCloseBy")
   {
      funcInfo.ReturnValue.SetData(
         OrderCloseBy(funcInfo.Parameter[0].GetDataInt(), funcInfo.Parameter[1].GetDataInt(), funcInfo.Parameter[2].GetDataColor())
      );
   }   
   else if (funcInfo.FuncName == "OrderModify")
   {
      funcInfo.ReturnValue.SetData(
         OrderModify(funcInfo.Parameter[0].GetDataInt(), funcInfo.Parameter[1].GetDataDouble(), funcInfo.Parameter[2].GetDataDouble(), funcInfo.Parameter[3].GetDataDouble(), funcInfo.Parameter[4].GetDataDateTime(), funcInfo.Parameter[5].IsEmpty() ? funcInfo.Parameter[5].GetDataColor() : clrNONE)
      );
   }
   else if (funcInfo.FuncName == "OrderDelete")
   {
      funcInfo.ReturnValue.SetData(
         OrderDelete(funcInfo.Parameter[0].GetDataInt(), funcInfo.Parameter[1].IsEmpty() ? funcInfo.Parameter[1].GetDataColor() : clrNONE)
      );
   }
   else if (funcInfo.FuncName == "OrderPrint")
   {
      OrderPrint();
   }
   else if (funcInfo.FuncName == "OrderTicket")
   {
      funcInfo.ReturnValue.SetData(
         OrderTicket()
      );
   }
   else if (funcInfo.FuncName == "OrderOpenTime")
   {
      funcInfo.ReturnValue.SetData(
         OrderOpenTime()
      );
   }
   else if (funcInfo.FuncName == "OrderOpenPrice")
   {
      funcInfo.ReturnValue.SetData(
         OrderOpenPrice()
      );
   }
   else if (funcInfo.FuncName == "OrderType")
   {
      funcInfo.ReturnValue.SetData(
         OrderType()
      );
   }
   else if (funcInfo.FuncName == "OrderLots")
   {
      funcInfo.ReturnValue.SetData(
         OrderLots()
      );
   }
   else if (funcInfo.FuncName == "OrderSymbol")
   {
      funcInfo.ReturnValue.SetData(
         OrderSymbol()
      );
   }
   else if (funcInfo.FuncName == "OrderStopLoss")
   {
      funcInfo.ReturnValue.SetData(
         OrderStopLoss()
      );
   }
   else if (funcInfo.FuncName == "OrderTakeProfit")
   {
      funcInfo.ReturnValue.SetData(
         OrderTakeProfit()
      );
   }
   else if (funcInfo.FuncName == "OrderCloseTime")
   {
      funcInfo.ReturnValue.SetData(
         OrderCloseTime()
      );
   }   
   else if (funcInfo.FuncName == "OrderClosePrice")
   {
      funcInfo.ReturnValue.SetData(
         OrderClosePrice()
      );
   }
   else if (funcInfo.FuncName == "OrderCommission")
   {
      funcInfo.ReturnValue.SetData(
         OrderCommission()
      );
   }
   else if (funcInfo.FuncName == "OrderExpiration")
   {
      funcInfo.ReturnValue.SetData(
         OrderExpiration()
      );
   }
   else if (funcInfo.FuncName == "OrderSwap")
   {
      funcInfo.ReturnValue.SetData(
         OrderSwap()
      );
   }
   else if (funcInfo.FuncName == "OrderProfit")
   {
      funcInfo.ReturnValue.SetData(
         OrderProfit()
      );
   }
   else if (funcInfo.FuncName == "OrderComment")
   {
      funcInfo.ReturnValue.SetData(
         OrderComment()
      );
   }
   else if (funcInfo.FuncName == "OrderMagicNumber")
   {
      funcInfo.ReturnValue.SetData(
         OrderMagicNumber()
      );
   }
   else if (funcInfo.FuncName == "Symbol")
   {
      funcInfo.ReturnValue.SetData(
         Symbol()
      );
   }
   else if (funcInfo.FuncName == "Period")
   {
      funcInfo.ReturnValue.SetData(
         Period()
      );
   }
   else if (funcInfo.FuncName == "Digits")
   {
      funcInfo.ReturnValue.SetData(
         Digits()
      );
   }
   else if (funcInfo.FuncName == "Point")
   {
      funcInfo.ReturnValue.SetData(
         Point()
      );
   }
   else if (funcInfo.FuncName == "IsConnected")
   {
      funcInfo.ReturnValue.SetData(
         IsConnected()
      );
   }
   else if (funcInfo.FuncName == "IsDemo")
   {
      funcInfo.ReturnValue.SetData(
         IsDemo()
      );
   }
   
   else if (funcInfo.FuncName == "IsDllsAllowed")
   {
      funcInfo.ReturnValue.SetData(
         IsDllsAllowed()
      );
   }
   else if (funcInfo.FuncName == "IsExpertEnabled")
   {
      funcInfo.ReturnValue.SetData(
         IsExpertEnabled()
      );
   }
   else if (funcInfo.FuncName == "IsLibrariesAllowed")
   {
      funcInfo.ReturnValue.SetData(
         IsLibrariesAllowed()
      );
   }
   else if (funcInfo.FuncName == "IsOptimization")
   {
      funcInfo.ReturnValue.SetData(
         IsOptimization()
      );
   }
   else if (funcInfo.FuncName == "IsTesting")
   {
      funcInfo.ReturnValue.SetData(
         IsTesting()
      );
   }
   else if (funcInfo.FuncName == "IsTradeAllowed")
   {
      funcInfo.ReturnValue.SetData(
         IsTradeAllowed()
      );
   }
   else if (funcInfo.FuncName == "IsTradeContextBusy")
   {
      funcInfo.ReturnValue.SetData(
         IsTradeContextBusy()
      );
   }
   else if (funcInfo.FuncName == "IsVisualMode")
   {
      funcInfo.ReturnValue.SetData(
         IsVisualMode()
      );
   }
   else if (funcInfo.FuncName == "TerminalCompany")
   {
      funcInfo.ReturnValue.SetData(
         TerminalCompany()
      );
   }
   else if (funcInfo.FuncName == "TerminalName")
   {
      funcInfo.ReturnValue.SetData(
         TerminalName()
      );
   }
   else if (funcInfo.FuncName == "TerminalPath")
   {
      funcInfo.ReturnValue.SetData(
         TerminalPath()
      );
   }
   else if (funcInfo.FuncName == "MarketInfo")
   {
      funcInfo.ReturnValue.SetData(
         MarketInfo(funcInfo.Parameter[0].GetDataString(), funcInfo.Parameter[1].GetDataInt())
      );
   }
   else if (funcInfo.FuncName == "SymbolsTotal")
   {
      funcInfo.ReturnValue.SetData(
         SymbolsTotal(funcInfo.Parameter[0].GetDataBool())
      );
   }
   else if (funcInfo.FuncName == "SymbolName")
   {
      funcInfo.ReturnValue.SetData(
         SymbolName(funcInfo.Parameter[0].GetDataInt(), funcInfo.Parameter[1].GetDataBool())
      );
   }   
   else if (funcInfo.FuncName == "SymbolSelect")
   {
      funcInfo.ReturnValue.SetData(
         SymbolSelect(funcInfo.Parameter[0].GetDataString(), funcInfo.Parameter[1].GetDataBool())
      );
   }
   else if (funcInfo.FuncName == "SymbolInfoInteger")
   {
      funcInfo.ReturnValue.SetData(
         SymbolInfoInteger(funcInfo.Parameter[0].GetDataString(), funcInfo.Parameter[1].GetDataInt())
      );
   }
   else if (funcInfo.FuncName == "SymbolInfoDouble")
   {
      funcInfo.ReturnValue.SetData(
         SymbolInfoDouble(funcInfo.Parameter[0].GetDataString(), funcInfo.Parameter[1].GetDataInt())
      );
   }
   else if (funcInfo.FuncName == "SymbolInfoString")
   {
      funcInfo.ReturnValue.SetData(
         SymbolInfoString(funcInfo.Parameter[0].GetDataString(), funcInfo.Parameter[1].GetDataInt())
      );
   }
   else if (funcInfo.FuncName == "SymbolInfoTick")
   {
      MqlTick mqlTick;
      funcInfo.ReturnValue.SetData(
         SymbolInfoTick(funcInfo.Parameter[0].GetDataString(), mqlTick)
      );
      funcInfo.Auxiliary[0].SetData(mqlTick.ask);
      funcInfo.Auxiliary[1].SetData(mqlTick.bid);
      funcInfo.Auxiliary[2].SetData(mqlTick.flags);
      funcInfo.Auxiliary[3].SetData(mqlTick.last);
      funcInfo.Auxiliary[4].SetData(mqlTick.time);
      funcInfo.Auxiliary[5].SetData(mqlTick.time_msc);
      funcInfo.Auxiliary[6].SetData(mqlTick.volume);
//      funcInfo.Auxiliary[7].SetData(mqlTick.volume_real);
   }
   else if (funcInfo.FuncName == "SymbolInfoSessionQuote")
   {
      datetime DateFrom = funcInfo.Parameter[3].GetDataDateTime();
      datetime DateTo = funcInfo.Parameter[4].GetDataDateTime();      
      funcInfo.ReturnValue.SetData(
         SymbolInfoSessionQuote(
            funcInfo.Parameter[0].GetDataString(), 
            funcInfo.Parameter[1].GetDataInt(), 
            (uint)funcInfo.Parameter[2].GetDataInt(), 
            DateFrom,
            DateTo
         )
      );
   }
   else if (funcInfo.FuncName == "SymbolInfoSessionTrade")
   {
      datetime date_from = funcInfo.Parameter[3].GetDataDateTime();
      datetime date_to = funcInfo.Parameter[4].GetDataDateTime();
      funcInfo.ReturnValue.SetData(
         SymbolInfoSessionTrade(
            funcInfo.Parameter[0].GetDataString(), 
            funcInfo.Parameter[1].GetDataInt(), 
            (uint)funcInfo.Parameter[2].GetDataInt(), 
            date_from,
            date_to
         )
      );
   }   
   else if (funcInfo.FuncName == "SeriesInfoInteger")
   {
      funcInfo.ReturnValue.SetData(
         SeriesInfoInteger(
            funcInfo.Parameter[0].GetDataString(), 
            funcInfo.Parameter[1].GetDataInt(), 
            funcInfo.Parameter[2].GetDataInt()
         )
      );
   }
   else if (funcInfo.FuncName == "RefreshRates")
   {
      funcInfo.ReturnValue.SetData(
         RefreshRates()
      );
   }
   else if (funcInfo.FuncName == "ExpertRemove")
   {
      ExpertRemove();
   }   
   else if (funcInfo.FuncName == "EventSetTimer")
   {
      ClientTimerInterval = 1000 * funcInfo.Parameter[0].GetDataInt();
      funcInfo.ReturnValue.SetData(
         EventSetMillisecondTimer(500)
      );
   }   
   else if (funcInfo.FuncName == "EventSetMillisecondTimer")
   {
      ClientTimerInterval = funcInfo.Parameter[0].GetDataInt();
      funcInfo.ReturnValue.SetData(
         EventSetMillisecondTimer(500)
      );
   }
   else if (funcInfo.FuncName == "EventKillTimer")
   {
      EventKillTimer();
      ClientTimerInterval = -1;
      funcInfo.ReturnValue.SetData(
         EventSetMillisecondTimer(500)
      );
   }
   
   else if (funcInfo.FuncName == "ObjectCreate1")
   {
      funcInfo.ReturnValue.SetData(
         ObjectCreate(
            funcInfo.Parameter[0].GetDataLong(), 
            funcInfo.Parameter[1].GetDataString(), 
            funcInfo.Parameter[2].GetDataInt(), 
            funcInfo.Parameter[3].GetDataInt(), 
            funcInfo.Parameter[4].GetDataDateTime(),  
            funcInfo.Parameter[5].GetDataDouble()
         )
      );
   }
   else if (funcInfo.FuncName == "ObjectCreate2")
   {
      funcInfo.ReturnValue.SetData(
         ObjectCreate(
            funcInfo.Parameter[0].GetDataLong(), 
            funcInfo.Parameter[1].GetDataString(), 
            funcInfo.Parameter[2].GetDataInt(), 
            funcInfo.Parameter[3].GetDataInt(), 
            funcInfo.Parameter[4].GetDataDateTime(),  
            funcInfo.Parameter[5].GetDataDouble(),
            funcInfo.Parameter[6].GetDataDateTime(),  
            funcInfo.Parameter[7].GetDataDouble()  
         )
      );
   }
   else if (funcInfo.FuncName == "ObjectCreate3")
   {
      funcInfo.ReturnValue.SetData(
         ObjectCreate(
            funcInfo.Parameter[0].GetDataLong(), 
            funcInfo.Parameter[1].GetDataString(), 
            funcInfo.Parameter[2].GetDataInt(), 
            funcInfo.Parameter[3].GetDataInt(), 
            funcInfo.Parameter[4].GetDataDateTime(),  
            funcInfo.Parameter[5].GetDataDouble(),
            funcInfo.Parameter[6].GetDataDateTime(),  
            funcInfo.Parameter[7].GetDataDouble(),
            funcInfo.Parameter[8].GetDataDateTime(),  
            funcInfo.Parameter[9].GetDataDouble()
         )
      );
   }
   else if (funcInfo.FuncName == "ObjectName1")
   {
      funcInfo.ReturnValue.SetData(
         ObjectName(
            funcInfo.Parameter[0].GetDataLong(), 
            funcInfo.Parameter[1].GetDataInt(),
            funcInfo.Parameter[2].GetDataInt(),
            funcInfo.Parameter[3].GetDataInt()
         )
      );
   }   
   else if (funcInfo.FuncName == "ObjectName2")
   {
      funcInfo.ReturnValue.SetData(
         ObjectName(
            funcInfo.Parameter[0].GetDataInt()
         )
      );
   }

   else if (funcInfo.FuncName == "ObjectDelete1")
   {
      funcInfo.ReturnValue.SetData(
         ObjectDelete(
            funcInfo.Parameter[0].GetDataString()
         )
      );
   }
   else if (funcInfo.FuncName == "ObjectDelete2")
   {
      funcInfo.ReturnValue.SetData(
         ObjectDelete(
            funcInfo.Parameter[0].GetDataLong(), 
            funcInfo.Parameter[1].GetDataString()
         )
      );
   }
   else if (funcInfo.FuncName == "ObjectsDeleteAll1")
   {
      funcInfo.ReturnValue.SetData(
         ObjectsDeleteAll(
            funcInfo.Parameter[0].GetDataLong(), 
            funcInfo.Parameter[1].GetDataInt(),
            funcInfo.Parameter[2].GetDataInt()
         )
      );
   }
   else if (funcInfo.FuncName == "ObjectsDeleteAll2")
   {
      funcInfo.ReturnValue.SetData(
         ObjectsDeleteAll(
            funcInfo.Parameter[0].GetDataLong(), 
            funcInfo.Parameter[1].GetDataString(),
            funcInfo.Parameter[2].GetDataInt(),
            funcInfo.Parameter[3].GetDataInt()
         )
      );
   }
   else if (funcInfo.FuncName == "ObjectsDeleteAll3")
   {
      funcInfo.ReturnValue.SetData(
         ObjectsDeleteAll(
            funcInfo.Parameter[0].GetDataInt(), 
            funcInfo.Parameter[1].GetDataInt()
         )
      );
   }
   else if (funcInfo.FuncName == "ObjectFind1")
   {
      funcInfo.ReturnValue.SetData(
         ObjectFind(
            funcInfo.Parameter[0].GetDataLong(), 
            funcInfo.Parameter[1].GetDataString()
         )
      );
   }
   else if (funcInfo.FuncName == "ObjectFind2")
   {
      funcInfo.ReturnValue.SetData(
         ObjectFind(
            funcInfo.Parameter[0].GetDataString()
         )
      );
   }
   else if (funcInfo.FuncName == "ObjectGetTimeByValue")
   {
      funcInfo.ReturnValue.SetData(
         ObjectGetTimeByValue(
            funcInfo.Parameter[0].GetDataLong(), 
            funcInfo.Parameter[1].GetDataString(),
            funcInfo.Parameter[2].GetDataDouble(),
            funcInfo.Parameter[3].GetDataInt()
         )
      );
   }
   else if (funcInfo.FuncName == "ObjectGetValueByShift")
   {
      funcInfo.ReturnValue.SetData(
         ObjectGetValueByShift(
            funcInfo.Parameter[0].GetDataString(),
            funcInfo.Parameter[1].GetDataInt()
         )
      );
   }   
   else if (funcInfo.FuncName == "ObjectGetValueByTime")
   {
      funcInfo.ReturnValue.SetData(
         ObjectGetValueByTime(
            funcInfo.Parameter[0].GetDataLong(),
            funcInfo.Parameter[1].GetDataString(),
            funcInfo.Parameter[2].GetDataDateTime(),
            funcInfo.Parameter[3].GetDataInt()
         )
      );
   }   
   else if (funcInfo.FuncName == "ObjectMove1")
   {
      funcInfo.ReturnValue.SetData(
         ObjectMove(
            funcInfo.Parameter[0].GetDataLong(),
            funcInfo.Parameter[1].GetDataString(),
            funcInfo.Parameter[2].GetDataInt(),
            funcInfo.Parameter[3].GetDataDateTime(),
            funcInfo.Parameter[4].GetDataDouble()
         )
      );
   }
   else if (funcInfo.FuncName == "ObjectMove2")
   {
      funcInfo.ReturnValue.SetData(
         ObjectMove(
            funcInfo.Parameter[0].GetDataString(),
            funcInfo.Parameter[1].GetDataInt(),
            funcInfo.Parameter[2].GetDataDateTime(),
            funcInfo.Parameter[3].GetDataDouble()
         )
      );
   }
   
   else if (funcInfo.FuncName == "ObjectsTotal1")
   {
      funcInfo.ReturnValue.SetData(
         ObjectsTotal(
            funcInfo.Parameter[0].GetDataLong(),
            funcInfo.Parameter[1].GetDataInt(),
            funcInfo.Parameter[2].GetDataInt()
         )
      );
   }
   else if (funcInfo.FuncName == "ObjectsTotal2")
   {
      funcInfo.ReturnValue.SetData(
         ObjectsTotal(
            funcInfo.Parameter[0].GetDataInt()
         )
      );
   }
   //  ！ObjectGetInteger(long, string, int, int, &long)のほうは実装が面倒なので今のところ作らない
   else if (funcInfo.FuncName == "ObjectGetInteger1")
   {
      funcInfo.ReturnValue.SetData(
         ObjectGetInteger(
            funcInfo.Parameter[0].GetDataLong(), 
            funcInfo.Parameter[1].GetDataString(),
            funcInfo.Parameter[2].GetDataInt(), 
            funcInfo.Parameter[3].GetDataInt()
         )
      );
   }
   else if (funcInfo.FuncName == "ObjectGetDouble1")
   {
      funcInfo.ReturnValue.SetData(
         ObjectGetDouble(
            funcInfo.Parameter[0].GetDataLong(), 
            funcInfo.Parameter[1].GetDataString(),
            funcInfo.Parameter[2].GetDataInt(), 
            funcInfo.Parameter[3].GetDataInt()
         )
      );
   }
   else if (funcInfo.FuncName == "ObjectGetString1")
   {
      funcInfo.ReturnValue.SetData(
         ObjectGetString(
            funcInfo.Parameter[0].GetDataLong(), 
            funcInfo.Parameter[1].GetDataString(),
            funcInfo.Parameter[2].GetDataInt(), 
            funcInfo.Parameter[3].GetDataInt()
         )
      );
   }
   else if (funcInfo.FuncName == "ObjectSetInteger1")
   {
      funcInfo.ReturnValue.SetData(
         ObjectSetInteger(
            funcInfo.Parameter[0].GetDataLong(), 
            funcInfo.Parameter[1].GetDataString(),
            funcInfo.Parameter[2].GetDataInt(), 
            funcInfo.Parameter[3].GetDataLong()
         )
      );
   }
   else if (funcInfo.FuncName == "ObjectSetDouble1")
   {
      funcInfo.ReturnValue.SetData(
         ObjectSetDouble(
            funcInfo.Parameter[0].GetDataLong(), 
            funcInfo.Parameter[1].GetDataString(),
            funcInfo.Parameter[2].GetDataInt(), 
            funcInfo.Parameter[3].GetDataDouble()
         )
      );
   }
   else if (funcInfo.FuncName == "ObjectSetString1")
   {
      funcInfo.ReturnValue.SetData(
         ObjectSetString(
            funcInfo.Parameter[0].GetDataLong(), 
            funcInfo.Parameter[1].GetDataString(),
            funcInfo.Parameter[2].GetDataInt(), 
            funcInfo.Parameter[3].GetDataString()
         )
      );
   }
   else if (funcInfo.FuncName == "TextSetFont")
   {
      funcInfo.ReturnValue.SetData(
         TextSetFont(
            funcInfo.Parameter[0].GetDataString(), 
            funcInfo.Parameter[1].GetDataInt(),
            funcInfo.Parameter[2].GetDataUInt(), 
            funcInfo.Parameter[3].GetDataInt()
         )
      );
   }
   else if (funcInfo.FuncName == "GlobalVariableCheck")
   {
      funcInfo.ReturnValue.SetData(
         GlobalVariableCheck(
            funcInfo.Parameter[0].GetDataString()
         )
      );
   }
   else if (funcInfo.FuncName == "GlobalVariableTime")
   {
      funcInfo.ReturnValue.SetData(
         GlobalVariableTime(
            funcInfo.Parameter[0].GetDataString()
         )
      );
   }
   else if (funcInfo.FuncName == "GlobalVariableDel")
   {
      funcInfo.ReturnValue.SetData(
         GlobalVariableDel(
            funcInfo.Parameter[0].GetDataString()
         )
      );
   }
   else if (funcInfo.FuncName == "GlobalVariableGet")
   {
      funcInfo.ReturnValue.SetData(
         GlobalVariableGet(
            funcInfo.Parameter[0].GetDataString()
         )
      );
   }
   else if (funcInfo.FuncName == "GlobalVariableName")
   {
      funcInfo.ReturnValue.SetData(
         GlobalVariableName(
            funcInfo.Parameter[0].GetDataInt()
         )
      );
   }
   else if (funcInfo.FuncName == "GlobalVariableSet")
   {
      funcInfo.ReturnValue.SetData(
         GlobalVariableSet(
            funcInfo.Parameter[0].GetDataString(),
            funcInfo.Parameter[1].GetDataDouble()
         )
      );
   }
   else if (funcInfo.FuncName == "GlobalVariablesFlush")
   {
      GlobalVariablesFlush();
   }
   else if (funcInfo.FuncName == "GlobalVariableTemp")
   {
      funcInfo.ReturnValue.SetData(
         GlobalVariableTemp(
            funcInfo.Parameter[0].GetDataString()
         )
      );
   }
   else if (funcInfo.FuncName == "GlobalVariableSetOnCondition")
   {
      funcInfo.ReturnValue.SetData(
         GlobalVariableSetOnCondition(
            funcInfo.Parameter[0].GetDataString(),
            funcInfo.Parameter[1].GetDataDouble(),
            funcInfo.Parameter[2].GetDataDouble()
         )
      );
   }
   else if (funcInfo.FuncName == "GlobalVariablesDeleteAll1")
   {
      funcInfo.ReturnValue.SetData(
         GlobalVariablesDeleteAll()
      );
   }   
   else if (funcInfo.FuncName == "GlobalVariablesDeleteAll2")
   {
      funcInfo.ReturnValue.SetData(
         GlobalVariablesDeleteAll(
            funcInfo.Parameter[0].GetDataString()
         )
      );
   }
   else if (funcInfo.FuncName == "GlobalVariablesDeleteAll3")
   {
      funcInfo.ReturnValue.SetData(
         GlobalVariablesDeleteAll(
            funcInfo.Parameter[0].GetDataString(),
            funcInfo.Parameter[1].GetDataDateTime()
         )
      );
   }
   else if (funcInfo.FuncName == "GlobalVariablesTotal")
   {
      funcInfo.ReturnValue.SetData(
         GlobalVariablesTotal()
      );
   }
   else if (funcInfo.FuncName == "EventChartCustom")
   {
      funcInfo.ReturnValue.SetData(
         EventChartCustom(
            funcInfo.Parameter[0].GetDataLong(), 
            funcInfo.Parameter[1].GetDataUShort(), 
            funcInfo.Parameter[2].GetDataLong(), 
            funcInfo.Parameter[3].GetDataDouble(),
            funcInfo.Parameter[4].GetDataString()
         )
      );
   }
   //  テンプレート
   /*
   else if (funcInfo.FuncName == "****")
   {
      funcInfo.ReturnValue.SetData(
         ****(
            funcInfo.Parameter[0].GetData**(), 
            funcInfo.Parameter[1].GetData**(),
            funcInfo.Parameter[2].GetData**()
         )
      );
   }
   */  
   else
   {
      //  不明な関数が指定された場合
      PrintFormat("不明な関数が指定されました'%s'。", funcInfo.FuncName);
      ResetLastError();
   }
   
   funcInfo.ErrorCode = GetLastError();
   PrintDebugMessage("指定されたローカル関数の呼び出しを行いました。");
   return;
}
