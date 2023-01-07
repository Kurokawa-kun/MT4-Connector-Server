//+------------------------------------------------------------------+
//|                                                       myApp1.mq4 |
//|                                         Copyright 2023, Kurokawa |
//|                                   https://twitter.com/ImKurokawa |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Kurokawa"
#property link      "https://twitter.com/ImKurokawa"
#property strict

int digits;             //  このシンボルの小数点以下の桁数
string format = NULL;   //  このシンボルを表示するためのフォーマット

int OnInit()
{
   Print("5秒間スリープして成行注文を1回発行するだけのプログラムです。");
   digits = (int)MarketInfo(Symbol(), MODE_DIGITS);
   format = StringFormat("%%.%df", digits);
   EventSetTimer(5);
   return INIT_SUCCEEDED;
}

void OnTick()
{
   //  現在価格を表示する
   PrintFormat("%-10s: Bid:%-9s Ask:%-9s", Symbol(), StringFormat(format, Bid), StringFormat(format, Ask));
   return;
}

void OnTimer()
{
   EventKillTimer();   
   int t = OrderSend(Symbol(), OP_BUY, 1.00, Ask, 0, Ask - 100 * Point(), Ask + 250 * Point()); //  成行注文
   if (t == -1)
   {
      PrintFormat("OrderSendが失敗しました。エラーコードは'%d'。", GetLastError());
      return;
   }
   PrintFormat("チケット番号は'%d'。", t);
   ExpertRemove();   //  プログラムの終了
   return;
}

void OnDeinit(const int reason)
{
   //  特に何もしない
   return;
}
