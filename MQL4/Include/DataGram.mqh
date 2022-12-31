//+------------------------------------------------------------------+
//|                                                     DataGram.mqh |
//|                                         Copyright 2022, Kurokawa |
//|                                   https://twitter.com/ImKurokawa |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, Kurokawa"
#property link      "https://twitter.com/ImKurokawa"
#property strict
#define BUFFER_SIZE  256
#define CHAR_NULL           0x00
#define CHAR_INITIALIZED    0x1A

//  送受信するメッセージの最小単位
class DataGram
{
public:
   char Buffer[BUFFER_SIZE];   //  メッセージバッファ本文

public:
   //  コンストラクタ
   DataGram()
   {
      Clear();
      return;
   }
   
   //  データを16進数の文字列型で取得する
   string GetHexString(char v)
   {
      char buf[3];   //  バッファサイズ+1バイトとすること（MQL4のバグのため）
      ArrayInitialize(buf, CHAR_NULL);
      for (int s=0; s<=1; s++)
      {
         char t = (char)((v >> (4 * s)) & 0x0F);
         switch (t)
         {
            case 0x00:
            {
               buf[1-s] = '0';
               break;
            }
            case 0x01:
            {
               buf[1 - s] = '1';
               break;
            }
            case 0x02:
            {
               buf[1 - s] = '2';
               break;
            }
            case 0x03:
            {
               buf[1 - s] = '3';
               break;
            }
            case 0x04:
            {
               buf[1 - s] = '4';
               break;
            }
            case 0x05:
            {
               buf[1 - s] = '5';
               break;
            }
            case 0x06:
            {
               buf[1 - s] = '6';
               break;
            }
            case 0x07:
            {
               buf[1 - s] = '7';
               break;
            }
            case 0x08:
            {
               buf[1 - s] = '8';
               break;
            }
            case 0x09:
            {
               buf[1 - s] = '9';
               break;
            }
            case 0x0A:
            {
               buf[1 - s] = 'A';
               break;
            }
            case 0x0B:
            {
               buf[1 - s] = 'B';
               break;
            }
            case 0x0C:
            {
               buf[1 - s] = 'C';
               break;
            }
            case 0x0D:
            {
               buf[1 - s] = 'D';
               break;
            }
            case 0x0E:
            {
               buf[1 - s] = 'E';
               break;
            }
            case 0x0F:
            {
               buf[1 - s] = 'F';
               break;
            }
            default:
            {
               //  エラー
               buf[1 - s] = '*';
               break;
            }
         }
      }
      return CharArrayToString(buf);
   }   
   
   //  メッセージを画面に出力する（デバッグ目的）
   void DumpMessage()
   {
      for (int c=0; c<BUFFER_SIZE; c+=32)
      {
         PrintFormat("%s%s%s%s%s%s%s%s %s%s%s%s%s%s%s%s %s%s%s%s%s%s%s%s %s%s%s%s%s%s%s%s ", 
            GetHexString(Buffer[c + 0]), GetHexString(Buffer[c + 1]), GetHexString(Buffer[c + 2]), GetHexString(Buffer[c + 3]), 
            GetHexString(Buffer[c + 4]), GetHexString(Buffer[c + 5]), GetHexString(Buffer[c + 6]), GetHexString(Buffer[c + 7]), 
            GetHexString(Buffer[c + 8]), GetHexString(Buffer[c + 9]), GetHexString(Buffer[c + 10]), GetHexString(Buffer[c + 11]), 
            GetHexString(Buffer[c + 12]), GetHexString(Buffer[c + 13]), GetHexString(Buffer[c + 14]), GetHexString(Buffer[c + 15]), 
            GetHexString(Buffer[c + 16]), GetHexString(Buffer[c + 17]), GetHexString(Buffer[c + 18]), GetHexString(Buffer[c + 19]), 
            GetHexString(Buffer[c + 20]), GetHexString(Buffer[c + 21]), GetHexString(Buffer[c + 22]), GetHexString(Buffer[c + 23]), 
            GetHexString(Buffer[c + 24]), GetHexString(Buffer[c + 25]), GetHexString(Buffer[c + 26]), GetHexString(Buffer[c + 27]), 
            GetHexString(Buffer[c + 28]), GetHexString(Buffer[c + 29]), GetHexString(Buffer[c + 30]), GetHexString(Buffer[c + 31])
         );
      }
      return;
   }
   
   //  メッセージバッファのクリア
   void Clear()
   {
      ArrayInitialize(Buffer, CHAR_NULL);
      Buffer[BUFFER_SIZE - 1] = CHAR_INITIALIZED;
      return;
   }
   
   //  共用体（MQL4でデータ型の変換で使う）
   union UnionValue4Byte
   {
      float FloatValue;
      int IntValue;
   };   
   union UnionValue8Byte
   {
      double DoubleValue;
      long LongValue;
   };
   
   //  データの設定
   void SetData(char v)
   {
      Buffer[BUFFER_SIZE - 1] = CHAR_NULL;
      Buffer[0] = v;
      return;
   }
   void SetData(uchar v)
   {
      Buffer[BUFFER_SIZE - 1] = CHAR_NULL;
      //setData((char)v); //  MQL4のバグ。ucharからcharへのキャストができない
      Buffer[0] = (char)v;
      return;
   }
   void SetData(bool v)
   {
      Buffer[BUFFER_SIZE - 1] = CHAR_NULL;
      Buffer[0] = (char)v;
      return;
   }
   void SetData(short v)
   {
      Buffer[BUFFER_SIZE - 1] = CHAR_NULL;
      Buffer[0] = (char)((v >> 8) & 0xFF);
      Buffer[1] = (char)(v & 0xFF);
      return;
   }
   void SetData(ushort v)
   {
      Buffer[BUFFER_SIZE - 1] = CHAR_NULL;
      SetData((short)v);
      //Buffer[0] = (char)((v >> 8) & 0xFF);
      //Buffer[1] = (char)(v & 0xFF);
      return;
   }
   void SetData(int v)
   {
      Buffer[BUFFER_SIZE - 1] = CHAR_NULL;
      Buffer[0] = (char)((v >> 24) & 0xFF);
      Buffer[1] = (char)((v >> 16) & 0xFF);      
      Buffer[2] = (char)((v >> 8) & 0xFF);
      Buffer[3] = (char)(v & 0xFF);
      return;
   }
   void SetData(uint v)
   {
      Buffer[BUFFER_SIZE - 1] = CHAR_NULL;
      SetData((int)v);
      return;
   }   
   void SetData(float v)
   {
      Buffer[BUFFER_SIZE - 1] = CHAR_NULL;
      UnionValue4Byte u;
      u.FloatValue = v;
      SetData(u.IntValue);
      return;
   }
   void SetData(color v)
   {
      Buffer[BUFFER_SIZE - 1] = CHAR_NULL;
      SetData((int)v);
      return;
   }
   //void SetData(enum v)
   //{
   //   Buffer[0] = (char)((v >> 24) & 0xFF);
   //   Buffer[1] = (char)((v >> 16) & 0xFF);      
   //   Buffer[2] = (char)((v >> 8) & 0xFF);
   //   Buffer[3] = (char)(v & 0xFF);
   //   return;
   //}
   void SetData(long v)
   {
      Buffer[BUFFER_SIZE - 1] = CHAR_NULL;
      Buffer[0] = (char)((v >> 56) & 0xFF);
      Buffer[1] = (char)((v >> 48) & 0xFF);      
      Buffer[2] = (char)((v >> 40) & 0xFF);
      Buffer[3] = (char)((v >> 32) & 0xFF);
      Buffer[4] = (char)((v >> 24) & 0xFF);
      Buffer[5] = (char)((v >> 16) & 0xFF);      
      Buffer[6] = (char)((v >> 8) & 0xFF);
      Buffer[7] = (char)(v & 0xFF);
      return;
   }
   void SetData(ulong v)
   {
      Buffer[BUFFER_SIZE - 1] = CHAR_NULL;
      SetData((long)v);
      return;
   }
   void SetData(double v)
   {
      Buffer[BUFFER_SIZE - 1] = CHAR_NULL;
      UnionValue8Byte u;
      u.DoubleValue = v;
      SetData(u.LongValue);
      return;
   }
   void SetData(datetime v)
   {
      Buffer[BUFFER_SIZE - 1] = CHAR_NULL;
      SetData((long)v);
      return;
   }
   void SetData(string v)
   {
      char b[BUFFER_SIZE];
      ArrayInitialize(b, CHAR_NULL);
      StringToCharArray(v, b);
      for (int c=0; c<BUFFER_SIZE - 1; c++)
      {
         Buffer[c] = b[c];
      }
      Buffer[BUFFER_SIZE - 1] = CHAR_NULL;
      return;
   }   
   //  データの取得
   char GetDataChar()
   {
      return Buffer[0];
   }
   uchar GetDataUChar()
   {
      return (uchar)Buffer[0];
   }
   bool GetDataBool()
   {
      return (bool)Buffer[0];
   }
   short GetDataShort()
   {
      int v = 0;
      v |= ((Buffer[0] & 0xFF) << 8);
      v |= ((Buffer[1] & 0xFF) << 0);
      return (short)v;
   }
   ushort GetDataUShort()
   {
      return (ushort)GetDataShort();
   }
   int GetDataInt()
   {
      int i = 0;
      for (int v = 0; v < 4; v++)
      {
         i |= ((int)Buffer[v] & 0xFF) << (8 * (3 - v));
      }
      return i;
   }
   uint GetDataUInt()
   {
      return (uint)GetDataInt();
   }
   float GetDataFloat()
   {
      UnionValue4Byte uv;
      uv.IntValue = GetDataInt();
      return uv.FloatValue;
   }
   color GetDataColor()
   {
      return (color)GetDataInt();
   }
   long GetDataLong()
   {
      long l = 0;
      for (int v = 0; v < 8; v++)
      {
         l |= ((long)Buffer[v] & 0xFF) << (8 * (7 - v));
      }
      return l;        
      //long u = 0;
      ////  MQL4のバグ。ビット演算をすると型の範囲がintになるためこの手法を使う。
      //u |= ((Buffer[0] & 0xFF) << 56);
      //u |= ((Buffer[1] & 0xFF) << 48);
      //u |= ((Buffer[2] & 0xFF) << 40);
      //u |= ((Buffer[3] & 0xFF) << 32);
      //long v = 0;
      //v |= ((Buffer[4] & 0xFF) << 24);
      //v |= ((Buffer[5] & 0xFF) << 16);
      //v |= ((Buffer[6] & 0xFF) << 08);
      //v |= ((Buffer[7] & 0xFF) << 00);
      //return (u<<32) | v;
   }
   ulong GetDataULong()
   {
      return (ulong)GetDataLong();
   }
   double GetDataDouble()
   {
      UnionValue8Byte un;
      un.LongValue = GetDataLong();
      return un.DoubleValue;
   }
   datetime GetDataDateTime()
   {
      return (datetime)GetDataLong();
   }
   string GetDataString()
   {
      char buf[BUFFER_SIZE];      
      for (int c=0; c<BUFFER_SIZE; c++)
      {
         buf[c] = Buffer[c];
      }
      return CharArrayToString(buf);
   }
   //  終了通知を受信したか返却する
   bool IsQuitReceived()
   {
      return (Buffer[1] == 1);
   }
   bool IsEmpty()
   {
      for (int c=0; c<BUFFER_SIZE-1; c++)
      {
         if (Buffer[c]!=CHAR_NULL) return false;
      }
      if (Buffer[BUFFER_SIZE-1]!=CHAR_INITIALIZED) return false;
      return true;
   }
   void CopyDataGramTo(DataGram &to)
   {
      for (int c=0; c<BUFFER_SIZE; c++)
      {
         to.Buffer[c] = Buffer[c];
      }
      return;
   }
};
