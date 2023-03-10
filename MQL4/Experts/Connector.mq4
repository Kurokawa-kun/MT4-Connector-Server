//+------------------------------------------------------------------+
//|                                                    Connector.mq4 |
//|                                         Copyright 2023, Kurokawa |
//|                                   https://twitter.com/ImKurokawa |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Kurokawa"
#property link      "https://twitter.com/ImKurokawa"
#property version   "1.00"
#property description   "外部プログラムからMT4を制御するための基盤機能を提供します。"
#property strict
#include <PipeServer.mqh>
#include <Message.mqh>
#include <FuncInfo.mqh>
#include <CallFunc.mqh>
#import "shell32.dll"
   int ShellExecuteW(int hWnd, string lpVerb, string lpFile, string lpParameters, string lpDirectory, int nCmdShow);    
#import

//  MT4コネクタ（サーバー側）

//  呼び出しモード
enum ExecutionMode
{
   CallExternalProgram,    //  MT4から外部プログラムを呼び出す
   WaitForConnection       //  外部プログラムからの接続を待つ
};

input ExecutionMode EXECUTION_MODE = CallExternalProgram;  //  呼び出しモード
input string INTERPRETER_NAME = "java.exe";  //  呼び出し先プログラムのインタプリタ（不要な場合は空欄）
//input string INTERPRETER_NAME = "python.exe";
input string WORKING_DIRECTORY = "C:\\Users\\MyName\\AppData\\Local\\Temp"; //  作業ディレクトリ
input string INTERPRETER_OPTIONS = ""; //  インタプリタに指定するオプション（不要な場合は空欄）
input string PROGRAM_NAME = "MyApp1";  //  インタプリタが呼び出すプログラム（インタプリタ不要の場合はここにプログラム名を指定する）
//input string PROGRAM_NAME = "MyApp1.py";
input string PROGRAM_OPTIONS = "-SampleParameter 150";   //  プログラムに渡すオプション（不要な場合は空欄）
input string SERVER_TIMEZONE = "Asia/Famagusta";   //  MT4サーバのタイムゾーン
input string LOCAL_TIMEZONE = "Asia/Tokyo";  //  ローカルコンピュータのタイムゾーン
input bool PAUSE_ON_STOP = true; //  プログラム終了時にコマンドプロンプトを一時停止させるか
input int INITIAL_SLEEP_TIME = 3;   //  クライアントの接続待ちを開始するまでのスリープ時間。単位は秒（不要な場合は0）

#define DIRECTORY_SEPARATOR "\\"
#define BASE_TIMER_INTERVAL   500 //  タイマーのインターバル（ミリ秒）。これがタイマー処理の最小インターバル時間になる。
PipeServer *Pipe; //  名前付きパイプの実体
string PipeName = "NamedPipe";
bool FlagEmergencyStop = false;

//  一度だけExpertRemoveを呼び出す
void CallExpertRemove()
{
   static bool ExpertRemoveCalled = false;
   if (ExpertRemoveCalled) return;  //  ExpertRemoveを何度呼び出しても問題はないが、MT4のエキスパートタブが見辛くなるためここで回数制限を行う
   ExpertRemoveCalled = true;
   ExpertRemove();
   return;
}

//  文字列の比較
bool MT4StringCompare(string a, string b)
{
   return StringCompare(a, b, true) == 0;
}

//  リクエスト情報の送受信
bool SendReceiveRequest(FuncInfo &funcInfo)
{
   PrintDebugMessage(StringFormat("リクエスト情報の送受信を行います。クライアントにリクエストする関数名は'%s'。", funcInfo.FuncName));
   int PosParameter = 0;
   int PosAuxiliary = 0;
   Message *s = new Message();
   Message *r = new Message();
   FuncInfo *funcInfoReceived = new FuncInfo();
   
   if (funcInfo.FuncName != NULL)
   {
      //  呼び出す関数が決まっている
      //  サーバー側の初期ルートはこちら
      s.SetMessageType(MSG_REQUEST_CALL_FUNCTION);
      s.Data[1].SetData(funcInfo.FuncName);
   }
   else
   {
      //  呼び出す関数が決まっていない（最初だけ何も要求を送らない）
      //  クライアント側の初期ルートはこちら
      s.SetMessageType(MSG_NOP);
   }
   
   //  MSG_END_AUXILIARY（補助情報終了）を送信するか、MSG_END_AUXILIARYを受信するまで無限ループ
   //  MSG_END_AUXILIARY=補助情報終了
   do
   {
      PrintDebugMessage("リクエスト情報を送受信するためのループ");
      if (!Pipe.SendMessage(s))
      {
         PrintFormat("メッセージの送信に失敗しました。");
         ExpertRemove();
         delete s;
         delete r;
         delete funcInfoReceived;
         return false;
      }
      PrintDebugMessage(StringFormat("メッセージを送信しました。メッセージタイプは%X", s.GetMessageType()));
      
      if (funcInfoReceived.FuncName != NULL && 
         MT4StringCompare(funcInfoReceived.FuncName, "OnDeinit") && 
         s.GetMessageType() == MSG_AUXILIARY_END)
      {
         //  OnDeinitの呼び出し依頼、かつ補助情報の送信が終わった場合
         break;   //  この関数の無限ループを抜ける
      }
      
      //  ----  ここまでで関数呼び出し依頼は完了している  ----
      
      r.Clear();
      if (!Pipe.ReceiveMessage(r))
      {
         ExpertRemove();
         PrintFormat("メッセージの受信に失敗しました。");
      }
      PrintDebugMessage(StringFormat("メッセージを受信しました。メッセージタイプは%X", r.GetMessageType()));
      
      if (r.GetMessageType()==MSG_NULL)
      {
         PrintFormat("空のメッセージを受信しました。緊急停止します。");
         ExpertRemove();
         delete s;
         delete r;
         delete funcInfoReceived;
         return false;
      }
      
      //  緊急停止フラグの確認
      if(r.GetEmergencyStop()!=0)
      {
         CallExpertRemove();
      }
      
      //  先方からのメッセージを処理する
      switch (r.GetMessageType())
      {
         case MSG_REQUEST_PARAMETER:
         {
            PrintDebugMessage("MSG_REQUEST_PARAMETERを受信しました");
            s.Clear();
            s.SetMessageType(MSG_PARAMETER);
            funcInfo.Parameter[PosParameter].CopyDataGramTo(s.Data[1]);
            if (PosParameter >= funcInfo.GetNumberOfParameters())
            {
               s.SetMessageType(MSG_PARAMETER_END);
            }
            PosParameter++;
            break;
         }
         case MSG_RETURN_VALUE:
         {
            PrintDebugMessage("MSG_RETURN_VALUEを受信しました");
            r.Data[1].CopyDataGramTo(funcInfo.ReturnValue);
            s.Clear();
            s.SetMessageType(MSG_REQUEST_ERROR_CODE);
            break;            
         }
         case MSG_ERROR_CODE:
         {
            PrintDebugMessage("MSG_ERROR_CODEを受信しました");
            funcInfo.ErrorCode = r.Data[1].GetDataInt();            
            PosAuxiliary = 0;
            s.Clear();
            s.SetMessageType(MSG_REQUEST_AUXILIARY);
            break;            
         }
         case MSG_AUXILIARY:
         case MSG_AUXILIARY_END:
         {
            PrintDebugMessage("MSG_START_AUXILIARYまたはMSG_END_AUXILIARYを受信しました");
            r.Data[1].CopyDataGramTo(funcInfo.Auxiliary[PosAuxiliary]);
            PosAuxiliary++;
            s.Clear();
            s.SetMessageType(MSG_REQUEST_AUXILIARY);
            break;            
         }
         //  関数呼び出し依頼を受信した場合
         case MSG_REQUEST_CALL_FUNCTION:
         {
            PrintDebugMessage("MSG_REQUEST_CALL_FUNCTIONを受信しました");
            funcInfoReceived.Clear();
            funcInfoReceived.FuncName = r.Data[1].GetDataString();
            PosParameter = 0;
            s.Clear();
            s.SetMessageType(MSG_REQUEST_PARAMETER);
            break;
         }
         case MSG_PARAMETER:
         {
            PrintDebugMessage("MSG_PARAMETERを受信しました");
            r.Data[1].CopyDataGramTo(funcInfoReceived.Parameter[PosParameter]);
            PosParameter++;
            s.Clear();
            s.SetMessageType(MSG_REQUEST_PARAMETER);
            break;
         }
         case MSG_PARAMETER_END:
         {
            PrintDebugMessage("MSG_PARAMETER_ENDを受信しました");
            r.Data[1].CopyDataGramTo(funcInfoReceived.Parameter[PosParameter]);
            PosParameter++;
            //  関数実行
            CallFunc(funcInfoReceived);            
            //  関数呼び出し後
            s.Clear();
            s.SetMessageType(MSG_RETURN_VALUE);
            funcInfoReceived.ReturnValue.CopyDataGramTo(s.Data[1]);
            break;
         }
         case MSG_REQUEST_ERROR_CODE:
         {
            PrintDebugMessage("MSG_REQUEST_ERROR_CODEを受信しました");
            s.Clear();
            s.SetMessageType(MSG_ERROR_CODE);
            s.Data[1].SetData(funcInfoReceived.ErrorCode);
            PosAuxiliary = 0;
            break;
         }
         case MSG_REQUEST_AUXILIARY:
         {
            PrintDebugMessage("MSG_REQUEST_AUXILIARYを受信しました");
            s.Clear();
            s.SetMessageType(MSG_AUXILIARY);
            funcInfoReceived.Auxiliary[PosAuxiliary].CopyDataGramTo(s.Data[1]);
            if (PosAuxiliary >= funcInfoReceived.GetNumberOfAuxiliaries())
            {
               s.SetMessageType(MSG_AUXILIARY_END);
            }
            PosAuxiliary++;
            break;
         }
      }
   }
   while (r.GetMessageType()!=MSG_AUXILIARY_END);
   
   delete s;
   delete r;
   delete funcInfoReceived;
   PrintDebugMessage("リクエスト情報の送受信を行いました。");
   return true;
}

//  初期化処理
int OnInit()
{
   if (!IsDllsAllowed())
   {
      Print("'DLLの使用を許可する'にチェックを入れてください。");
      return INIT_FAILED;
   }
   if (INITIAL_SLEEP_TIME > 0)
   {
      //  起動直後にスリープ時間を設ける理由：
      //  何らかの理由でクライアントを止めたい場合、クライアントのプログラムを削除（移動）してからMT4を再起動すると
      //  このEAが起動して接続待ち（ロック状態）になってしまうため。
      //  ※ なお、その場合でもMT4のチャートを閉じて25秒待つことで復帰は可能。
      PrintFormat("%d秒間スリープします。", INITIAL_SLEEP_TIME);
      Sleep(1000 * INITIAL_SLEEP_TIME);
   }
   
   //  作業ディレクトリの設定
   string WorkingDir;
   if (WORKING_DIRECTORY == "")
   {
      WorkingDir = StringConcatenate(TerminalInfoString( TERMINAL_DATA_PATH), DIRECTORY_SEPARATOR, "Experts");
   }
   else
   {
      WorkingDir = WORKING_DIRECTORY;
   }
   
   string pipename = StringConcatenate(PipeName, "_", GetRandomString());
   string pause = PAUSE_ON_STOP ? "&pause" : "";
   string ParameterStr = StringFormat("/C %s %s %s -PipeName %s -ServerTime %s -LocalTime %s %s %s", INTERPRETER_NAME, INTERPRETER_OPTIONS, PROGRAM_NAME, pipename, SERVER_TIMEZONE, LOCAL_TIMEZONE, PROGRAM_OPTIONS, pause);
   Print(ParameterStr);
   if (EXECUTION_MODE == CallExternalProgram)
   {
      //  外部コマンドを実行
      ShellExecuteW(0, "open", "cmd.exe", ParameterStr, WorkingDir, 1);
   }
   
   Pipe = new PipeServer();
   if (Pipe.Create(pipename) == INVALID_HANDLE_VALUE)
   {
      PrintFormat("名前付きパイプ'%s'の作成が失敗しました。", pipename);
      return INIT_FAILED;
   }
   
   if (EXECUTION_MODE == WaitForConnection)
   {
      PrintFormat("クライアントからの接続を待っています。接続先は:'%s'", pipename);
   }
   
   //  接続待ち
   PrintFormat("接続に失敗してMT4がロック状態になってしまった場合はチャート画面の閉じるボタンを押して25秒待つとEAを停止できます。");
   Pipe.WaitForClient();
   
   //  タイマーの設定
   EventSetMillisecondTimer(BASE_TIMER_INTERVAL);
   ClientTimerInterval = -1;

   //  関数の実行依頼
   PrintDebugMessage("グローバル関数OnPreInitを呼び出します。");   
   FuncInfo *fc = new FuncInfo();
   fc.FuncName = "OnPreInit";
   fc.Parameter[0].SetData(GlobalVariableGet("DebugMessage")!=0 ? True : False);   
   if (!SendReceiveRequest(fc))
   {
      PrintFormat("%s: %s, %s, %d", "リクエストの送受信が失敗しました", __FILE__, __FUNCTION__, __LINE__);
      FlagEmergencyStop = true;
      delete fc;
      PrintDebugMessage("グローバル関数OnPreInitを抜けます。復帰値はINIT_FAILED");
      return INIT_FAILED;
   }
   delete fc;
   PrintDebugMessage("グローバル関数OnPreInitを抜けます。");
   
   //  関数の実行依頼
   PrintDebugMessage("グローバル関数OnInitを呼び出します。");
   fc = new FuncInfo();
   fc.FuncName = "OnInit";
   fc.Parameter[0].SetData(Ask);
   fc.Parameter[1].SetData(Bid);
   fc.Parameter[2].SetData(Open[0]);
   fc.Parameter[3].SetData(High[0]);
   fc.Parameter[4].SetData(Close[0]);
   fc.Parameter[5].SetData(Low[0]);
   fc.Parameter[6].SetData(Time[0]);
   fc.Parameter[7].SetData(Volume[0]);
   fc.Parameter[8].SetData(Bars);
   fc.Parameter[9].SetData(Digits);
   fc.Parameter[10].SetData(Point);   
   if (!SendReceiveRequest(fc))
   {
      PrintFormat("%s: %s, %s, %d", "リクエストの送受信が失敗しました", __FILE__, __FUNCTION__, __LINE__);
      FlagEmergencyStop = true;
      delete fc;
      PrintDebugMessage("グローバル関数OnInitを抜けます。復帰値はINIT_FAILED");
      return INIT_FAILED;
   }
   int rv = fc.ReturnValue.GetDataInt();   
   delete fc;
   PrintDebugMessage(StringFormat("グローバル関数OnInitを抜けます。復帰値は%d", rv));   
   return rv;
}

void OnTick()
{
   if (FlagEmergencyStop) return;
   
   //  関数の実行依頼
   PrintDebugMessage("グローバル関数を呼び出します。OnTick");
   FuncInfo *fc = new FuncInfo();
   fc.FuncName = "OnTick";
   fc.Parameter[0].SetData(Ask);
   fc.Parameter[1].SetData(Bid);
   fc.Parameter[2].SetData(Open[0]);
   fc.Parameter[3].SetData(High[0]);
   fc.Parameter[4].SetData(Close[0]);
   fc.Parameter[5].SetData(Low[0]);
   fc.Parameter[6].SetData(Time[0]);
   fc.Parameter[7].SetData(Volume[0]);
   fc.Parameter[8].SetData(Bars);
   fc.Parameter[9].SetData(Digits);
   fc.Parameter[10].SetData(Point);
   
   if (!SendReceiveRequest(fc))
   {
      PrintFormat("%s: %s, %s, %d", "リクエストの送受信が失敗しました", __FILE__, __FUNCTION__, __LINE__);
      FlagEmergencyStop = true;
      delete fc;
      return;
   }
   delete fc;
   PrintDebugMessage("グローバル関数を抜けます。OnTick");
   return;
}

void OnTimer()
{
   static long TimerCount = 0;   //  現在の積算のスリープ時間
   if (FlagEmergencyStop) return;
      
   if (ClientTimerInterval >= 0 && TimerCount >= ClientTimerInterval)
   {
      //  クライアントにOnTimer呼び出し依頼を行う
      PrintDebugMessage("グローバル関数OnTimerを呼び出します。");
      TimerCount -= ClientTimerInterval;
      FuncInfo *fc = new FuncInfo();
      fc.FuncName = "OnTimer";
      fc.Parameter[0].SetData(Ask);
      fc.Parameter[1].SetData(Bid);
      fc.Parameter[2].SetData(Open[0]);
      fc.Parameter[3].SetData(High[0]);
      fc.Parameter[4].SetData(Close[0]);
      fc.Parameter[5].SetData(Low[0]);
      fc.Parameter[6].SetData(Time[0]);
      fc.Parameter[7].SetData(Volume[0]);
      fc.Parameter[8].SetData(Bars);
      fc.Parameter[9].SetData(Digits);
      fc.Parameter[10].SetData(Point);
      if (!SendReceiveRequest(fc))
      {
         TimerCount += BASE_TIMER_INTERVAL;
         FlagEmergencyStop = true;
         delete fc;
         PrintDebugMessage("グローバル関数OnTimerを抜けます。");
         return;
      }
      delete fc;
      PrintDebugMessage("グローバル関数OnTimerを抜けます。");
   }
   
   //  クライアントにOnTimerInterval呼び出し依頼を行う
   PrintDebugMessage("グローバル関数OnTimerInternalを呼び出します。");
   TimerCount += ClientTimerInterval >=0 ? BASE_TIMER_INTERVAL : 0;
   FuncInfo *fc = new FuncInfo();
   fc.FuncName = "OnTimerInternal";
   if (!SendReceiveRequest(fc))
   {
      PrintFormat("%s: %s, %s, %d", "リクエストの送受信が失敗しました", __FILE__, __FUNCTION__, __LINE__);
      FlagEmergencyStop = true;
      delete fc;
      TimerCount = 0;
      PrintDebugMessage("グローバル関数OnTimerInternalを抜けます。");
      return;
   }
   delete fc;
   PrintDebugMessage("グローバル関数OnTimerInternalを抜けます。");
   
   return;
}

void OnDeinit(const int reason)
{
   if (FlagEmergencyStop)
   {
      Pipe.Close();
      delete Pipe;
      return;
   }
   
   //  関数の実行依頼   
   PrintDebugMessage("グローバル関数OnDeinitを呼び出します。");
   FuncInfo *fc = new FuncInfo();
   fc.FuncName = "OnDeinit";
   fc.Parameter[0].SetData(Ask);
   fc.Parameter[1].SetData(Bid);
   fc.Parameter[2].SetData(Open[0]);
   fc.Parameter[3].SetData(High[0]);
   fc.Parameter[4].SetData(Close[0]);
   fc.Parameter[5].SetData(Low[0]);
   fc.Parameter[6].SetData(Time[0]);
   fc.Parameter[7].SetData(Volume[0]);
   fc.Parameter[8].SetData(Bars);
   fc.Parameter[9].SetData(Digits);
   fc.Parameter[10].SetData(Point);
   if (!SendReceiveRequest(fc))
   {
      //  メッセージの表示以外、何もしなくていい
      PrintFormat("%s: %s, %s, %d", "リクエストの送受信が失敗しました", __FILE__, __FUNCTION__, __LINE__);
   }
   delete fc;
   PrintDebugMessage("グローバル関数OnDeinitを抜けます。");
   EventKillTimer();
   
   //  終了処理
   Pipe.Close();
   delete Pipe;
   return;
}
