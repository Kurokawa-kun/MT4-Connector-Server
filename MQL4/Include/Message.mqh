//+------------------------------------------------------------------+
//|                                                      Message.mqh |
//|                                         Copyright 2022, Kurokawa |
//|                                   https://twitter.com/ImKurokawa |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Kurokawa"
#property link      "https://twitter.com/ImKurokawa"
#property strict
#include <DataGram.mqh>

//  名前付きパイプで送受信するメッセージの本体
class Message
{
   #define MSG_NULL                    0x00
   #define MSG_NOP                     0x0A
   #define MSG_REQUEST_CALL_FUNCTION   0x23
   #define MSG_REQUEST_PARAMETER       0x24
   #define MSG_PARAMETER               0x25
   #define MSG_PARAMETER_END           0x26
   #define MSG_RETURN_VALUE            0x27
   #define MSG_REQUEST_ERROR_CODE      0x28
   #define MSG_ERROR_CODE              0x29
   #define MSG_REQUEST_AUXILIARY       0x2A
   #define MSG_AUXILIARY               0x2B
   #define MSG_AUXILIARY_END           0x2C   
   #define NUMBER_OF_DATAGRAMS            2
   
public:
   DataGram Data[NUMBER_OF_DATAGRAMS];
   
public:
   //  コンストラクタ
   Message()
   {
      Clear();
      SetSequenceNumber(0);
      return;
   }
   void Clear()
   {
      for (int i = 0; i < NUMBER_OF_DATAGRAMS; i++)
      {
         Data[i].Clear();
      }
      return;
   }
   void DumpAll()
   {
      for (int i = 0; i < NUMBER_OF_DATAGRAMS; i++)
      {
         Data[i].DumpMessage();
      }
      return;
   }   
   void SetMessageType(char mt)
   {
      Data[0].Buffer[BUFFER_SIZE - 1] = '\0';
      Data[0].Buffer[0] = mt;
      return;
   }
   void SetEmergencyStop(char flg)
   {
      Data[0].Buffer[BUFFER_SIZE - 1] = '\0';
      Data[0].Buffer[1] = flg;
      return;
   }
   void SetSequenceNumber(char num)
   {
      Data[0].Buffer[BUFFER_SIZE - 1] = '\0';
      Data[0].Buffer[2] = num;
      return;
   }
   int GetMessageType()
   {
      return (int)Data[0].Buffer[0];
   }
   bool GetEmergencyStop()
   {
      return Data[0].Buffer[1]==(char)1;
   }
   char GetSequenceNumber()
   {
      return Data[0].Buffer[2];
   }
};
