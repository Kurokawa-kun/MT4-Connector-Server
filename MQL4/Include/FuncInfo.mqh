//+------------------------------------------------------------------+
//|                                                     FuncInfo.mqh |
//|                                         Copyright 2023, Kurokawa |
//|                                   https://twitter.com/ImKurokawa |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Kurokawa"
#property link      "https://twitter.com/ImKurokawa"
#property strict
#include <PipeServer.mqh>
#include <Message.mqh>

//  リクエストの送受信で使われる関数の情報
//  含まれる情報：
//  関数名
//  関数に渡すパラメタ
//  関数の復帰値
//  関数のエラーコード
//  補助情報（配列を取る復帰値、呼び出し先で変更されたパラメタの値などを格納する）
class FuncInfo
{
#define MAX_NUMBER_OF_PARAMETERS    30
#define MAX_NUMBER_OF_AUXILIARIES   5000
public:
   string FuncName;
   DataGram Parameter[MAX_NUMBER_OF_PARAMETERS];
   DataGram ReturnValue;
   int ErrorCode;
   DataGram Auxiliary[MAX_NUMBER_OF_AUXILIARIES];

   //  コンストラクタ
   FuncInfo()
   {
      Clear();
      return;
   }
   //  フィールドをクリアする
   void Clear()
   {
      FuncName = NULL;
      for (int c=0; c<MAX_NUMBER_OF_PARAMETERS; c++)
      {
         Parameter[c].Clear();
      }
      ReturnValue.Clear();
      ErrorCode = 0;
      for (int c=0; c<MAX_NUMBER_OF_AUXILIARIES; c++)
      {
         Auxiliary[c].Clear();
      }
      return;
   }
   //  パラメタの数を取得する
   int GetNumberOfParameters()
   {
      int c;
      for (c=0; c<MAX_NUMBER_OF_PARAMETERS; c++)
      {
         if (Parameter[c].IsEmpty()) break;
      }
      return c;
   }
   //  補助情報の数を取得する
   int GetNumberOfAuxiliaries()
   {
      int c;
      for (c=0; c<MAX_NUMBER_OF_AUXILIARIES; c++)
      {
         if (Auxiliary[c].IsEmpty()) break;
      }
      return c;
   }
};
