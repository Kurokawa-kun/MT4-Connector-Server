//+------------------------------------------------------------------+
//|                                                   PipeServer.mqh |
//|                                         Copyright 2023, Kurokawa |
//|                                   https://twitter.com/ImKurokawa |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Kurokawa"
#property link      "https://twitter.com/ImKurokawa"
#property strict
#include <Message.mqh>

//  サーバー側の名前付きパイプ

#import "kernel32.dll"
   int CreateNamedPipeW(string PipeName,int dwOpenMode,int dwPipeMode,int nMaxInstances,int nOutBUFFER_SIZE,int nInBUFFER_SIZE,int nDefaultTimeOut,int lpSecurityAttributes);
   int ConnectNamedPipe(int hPipe, int lpOverlapped);
   int ReadFile(int hPipe, char& inBuffer[],int NumberOfBytesToRead, int bytesRead, int lpOverlapped);
   int WriteFile(int hPipe, char& sBuffer[], int NumberOfBytesToWrite, int bytesWritten, int lpOverlapped);
//   int ReadFile(int hPipe, char& inBuffer[],int NumberOfBytesToRead, int& bytesRead[], int lpOverlapped);
//   int WriteFile(int hPipe, char& sBuffer[], int NumberOfBytesToWrite, int &bytesWritten[], int lpOverlapped);
   int FlushFileBuffers(int hPipe);
   int DisconnectNamedPipe(int hPipe);
   int CloseHandle(int hPipe);
#import

//  動作モード
#define PIPE_ACCESS_INBOUND            0x00000001
#define PIPE_ACCESS_OUTBOUND           0x00000002
#define PIPE_ACCESS_DUPLEX             0x00000003
#define FILE_FLAG_FIRST_PIPE_INSTANCE  0x00080000
#define FILE_FLAG_WRITE_THROUGH        0x80000000
#define FILE_FLAG_OVERLAPPED           0x40000000
#define WRITE_DAC                      0x00040000
#define WRITE_OWNER                    0x00080000
#define ACCESS_SYSTEM_SECURITY         0x01000000

//  パイプの種別
#define PIPE_TYPE_BYTE                 0x00000000
#define PIPE_TYPE_MESSAGE              0x00000004
#define PIPE_READMODE_BYTE             0x00000000
#define PIPE_READMODE_MESSAGE          0x00000002
#define PIPE_WAIT                      0x00000000
#define PIPE_NOWAIT                    0x00000001
#define PIPE_ACCEPT_REMOTE_CLIENTS     0x00000000
#define PIPE_REJECT_REMOTE_CLIENTS     0x00000008

#define INVALID_HANDLE_VALUE  -1  //  エラー
#define WINDOWS_NAMED_PIPE_PATH "\\\\.\\pipe\\" //  名前付きパイプのプリフィックス

class PipeServer
{
protected:
   int PipeHandle;
   
private:
   int NullPtr[1];
   
public:
   PipeServer()
   {
      return;
   }
   //  パイプの作成
   int Create(string pPipeName)
   {
      PipeHandle = CreateNamedPipeW(StringConcatenate(WINDOWS_NAMED_PIPE_PATH, pPipeName), PIPE_ACCESS_DUPLEX, PIPE_TYPE_BYTE | PIPE_WAIT, 1, NUMBER_OF_DATAGRAMS * BUFFER_SIZE, NUMBER_OF_DATAGRAMS * BUFFER_SIZE, 0, NULL);
      return PipeHandle;
   }
   //  クライアントからの接続を待つ
   void WaitForClient()
   {
      ConnectNamedPipe(PipeHandle, NULL);
      return;
   }
   //  バイトデータの書き込み
   int Write(char& data[])
   {
      return WriteFile(PipeHandle, data, NUMBER_OF_DATAGRAMS * BUFFER_SIZE, NULL, NULL);
   }
   //  バイトデータの読み込み
   int Read(char& data[])
   {
      return ReadFile(PipeHandle, data, NUMBER_OF_DATAGRAMS * BUFFER_SIZE, NULL, NULL);
   }
   //  パイプを閉じる
   void Close()
   {
      DisconnectNamedPipe(PipeHandle);
      CloseHandle(PipeHandle);
      return;
   }   
   //  メッセージの送信
   bool SendMessage(Message &msg)
   {
      char ByteData[];
      
      if (msg.GetMessageType() == MSG_NOP) return true;
      
      ArrayResize(ByteData, NUMBER_OF_DATAGRAMS * BUFFER_SIZE, NUMBER_OF_DATAGRAMS * BUFFER_SIZE);
      ArrayInitialize(ByteData, '\0');
      
      int p = 0;
      for (int d = 0; d < NUMBER_OF_DATAGRAMS; d++)
      {
         for (int b = 0; b < BUFFER_SIZE; b++)
         {
            ByteData[p] = msg.Data[d].Buffer[b];
            p++;
         }
      }
      if (Write(ByteData) < 0)
      {
         PrintFormat("%s, %s, %d", __FILE__, __FUNCTION__, __LINE__);
         ArrayFree(ByteData);
         return false;
      }
      
      ArrayFree(ByteData);
      return true;
   }
   
   //  メッセージの受信
   bool ReceiveMessage(Message &msg)
   {
      char ByteData[];
      ArrayResize(ByteData, NUMBER_OF_DATAGRAMS * BUFFER_SIZE, NUMBER_OF_DATAGRAMS * BUFFER_SIZE);
      ArrayInitialize(ByteData, '\0');
      
      if (Read(ByteData) < 0)
      {
         PrintFormat("%s, %s, %d", __FILE__, __FUNCTION__, __LINE__);
         ArrayFree(ByteData);
         return false;
      }
      
      int p = 0;
      for (int d = 0; d < NUMBER_OF_DATAGRAMS; d++)
      {
         for (int b = 0; b < BUFFER_SIZE; b++)
         {
            msg.Data[d].Buffer[b] = ByteData[p];
            p++;
         }
      }

      ArrayFree(ByteData);
      return true;
   }
};
