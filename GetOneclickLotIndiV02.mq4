//+------------------------------------------------------------------+
//|                                           GetOneclickLotIndi.mq4 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "2.00"
#property strict
#property indicator_chart_window

#define GA_ROOT       2

#define WM_GETTEXT 0x000D
#define WM_LBUTTONDOWN 513
#define WM_LBUTTONUP 514
#define WM_NEXTDLGCTL                   0x0028
#define WM_MDIACTIVATE                  0x0222
#define WM_COMMAND                  0x0111
#define  WM_ACTIVATE  0x6

#define SMTO_ABORTIFHUNG 0x0002

#define EM_SETSEL 0xB1
#define EM_LINESCROLL 0xB6
#define EM_TAKEFOCUS  0x1508

#define  BM_CLICK 0xF5

//EN_SETFOCUS  = $0100; // 入力フォーカスを得た。
//  EN_KILLFOCUS = $0200; // 入力フォーカスを失った。
//  EN_CHANGE    = $0300; // テキストが変更された｡
//  EN_UPDATE    = $0400; // テキストの内容が変更される。
//  EN_ERRSPACE  = $0500; // 文字列バッファのメモリ割り当てに失敗した。
//  EN_MAXTEXT   = $0501; // 文字数が上限を越えた。
//  EN_HSCROLL   = $0601; // 水平スクロールを行う｡
//  EN_VSCROLL   = $0602; // 垂直スクロールを行う｡
#define EN_SETFOCUS 0x100
#define EN_CHANGE 0x300
#define EN_UPDATE 0x400

#define GWL_STYLE -16
#define WS_TABSTOP 0x00010000

#define INPUT_MOUSE 0
#define MOUSEEVENTF_MOVE 1
#define MOUSEEVENTF_ABSOLUTE 0x8000

#define MOUSEEVENTF_LEFTDOWN 0x0002
#define MOUSEEVENTF_LEFTUP 0x0004

#define offset_lastlot 9
#define HANDLE int
#define DWORD int
#define PCTSTR string
#define PSECURITY_ATTRIBUTES int
#define BOOL bool

#import "user32.dll"
int FindWindowW(string className, string windowName);
int FindWindowExW(int hwndParent, int hwndChildAfter, string className, string windowName);
int GetWindowTextW(int hWnd, string &lpString, int nMaxCount);
int SetWindowTextW(int hWnd, string &lpString);
int GetParent(int hWnd);
int SendMessageW(int hWnd, unsigned int Msg, int wParam, string lParam);
int IsIconic(int hWnd);
int GetAncestor(int,int);
int SendMessageTimeoutW(int hWnd, int Msg, int wParam, string &lParam,
                        unsigned int fuFlags, unsigned int uTimeout, string &lpdwResult);
int SendMessageW(int hWnd, int Msg, int wParam, string lParam);
int SendMessageA(int hWnd, int Msg, int wParam, int lParam);
int PostMessageA(int hWnd, int Msg, int wParam, int lParam);
unsigned int GetDlgItemTextA(int hDlg, int nIDDlgItem, string &lpString, int cchMax);
unsigned int GetDlgItemTextW(int hDlg, int nIDDlgItem, string &lpString, int cchMax);
int SetFocus(int hWnd);
int SetActiveWindow(int hWnd);
int SetCapture(int hWnd);
long SetWindowLongW(int hWnd, int nIndex, long dwNewLong);
long SetWindowLongA(int hWnd, int nIndex, long dwNewLong);
long  GetWindowLongA(int hWnd, int  nIndex);
bool GetWindowRect(int hWnd, int& pos[4]);
int SendInput(int nInputs, int &pInputs[], int cbSize);
bool SetForegroundWindow(int hWnd);
bool BringWindowToTop(int hWnd);
int GetForegroundWindow();
#import "kernel32.dll"
void Sleep(int mili);
HANDLE CreateFileA(
  PCTSTR pszFileName,          // ファイル名
  DWORD  dwAccess,             // アクセス指定
  DWORD  dwShare,              // 共有方法
  PSECURITY_ATTRIBUTES psa,    // セキュリティ属性
  DWORD  dwCreateDisposition,  // 動作指定
  DWORD  dwFlagsAndAttributes, // フラグと属性
  HANDLE hTemplate             // テンプレートファイル
);
BOOL CloseHandle(
  HANDLE hObject    // オブジェクトのハンドル
);
DWORD GetLastError(void);
int CreateFileW( string Filename,int AccessMode,int ShareMode,int PassAsZero,int CreationMode,
                 int FlagsAndAttributes,int AlsoPassAsZero );
int GetFileSize( int FileHandle,int PassAsZero );
int SetFilePointer( int FileHandle,int Distance,int &PassAsZero[],int FromPosition );
int ReadFile( int FileHandle,unsigned char &BufferPtr[],int BufferLength,int &BytesRead[],int PassAsZero );
#import

int g_DesktopHandle = 0; //クライアントウィンドウハンドル保持用
int g_ClientHandle = 0; //クライアントウィンドウハンドル保持用
int g_ThisWinHandle = 0; //Thisウィンドウハンドル保持用
int g_ParentWinHandle = 0; //Parentウィンドウハンドル保持用
int g_wTopHandle = 0;

//long chartid_arr[99];
//bool lot_clicked_arr[99];

//long chartid_arr[99];
bool lot_clicked = false;

bool b_again = false;
string g_msg = "";
double initial_lot = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
//--- indicator buffers mapping

//---
  string str_data_dir =   TerminalInfoString(
                            TERMINAL_DATA_PATH      // プロパティID
                          );;
  Print(str_data_dir);
  string str_filename = "trade.ini";
  string str_fullpath = str_data_dir + "\\config\\" +str_filename;
  //string str_fullpath = str_data_dir + "\\MQL4\\Files\\" +str_filename;
  Print(str_fullpath);
  //str_fullpath = "C:\\Users\\takeshi_s\\AppData\\Roaming\\MetaQuotes\\Terminal\\FB57BB6FF47127471C05FDC176B3D389\\config\\trade.ini";
  Print(str_fullpath);
  //C:\Users\takeshi_s\AppData\Roaming\MetaQuotes\Terminal\FB57BB6FF47127471C05FDC176B3D389\config\trade.ini
  HANDLE file_handle = CreateFileW(
                         str_fullpath,          // ファイル名
                         (int)0x80000000,              // アクセス指定
                         7,              // 共有方法
                         0,    // セキュリティ属性
                         3,  // 動作指定
                         0x80, // フラグと属性
                         0             // テンプレートファイル
                       );

  Print(file_handle);
  Print(KERNEL32::GetLastError());

  int       movehigh[1] = {0};
  unsigned char    lot_buffer[4];        // データの生値
  int       read_byte[1] = {0};   // 読み取ったバイト数
  SetFilePointer(file_handle, 4, movehigh, 0);
  ReadFile( file_handle,lot_buffer,1,read_byte,NULL );
  if(lot_buffer[0] == 0){
    SetFilePointer(file_handle, 8, movehigh, 0);
  }else{
    SetFilePointer(file_handle, 12, movehigh, 0);
  }

  ReadFile( file_handle,lot_buffer,4,read_byte,NULL );
  printf("read_byte = %d",read_byte[0]);
  printf("%02X %02X %02X %02X",lot_buffer[0],lot_buffer[1],lot_buffer[2],lot_buffer[3]);
  initial_lot = ((double)(lot_buffer[0]+256*lot_buffer[1]+256*256*lot_buffer[2]+256*256*256*lot_buffer[3]))/100;
  Print(initial_lot);
  
  CloseHandle(file_handle);

  EventSetTimer(10);
  return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
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
//---

//--- return value of prev_calculated for next call
  return(rates_total);
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
//---
  static int chart_num = 0;
  Print("start");
  static long current_win_chartid = 0;
//  long current_win_chartid2 = 0;
//
//  if(current_win_chartid == 0) {
//    current_win_chartid = ChartFirst();
//    //Print("ChartFirst");
//    g_msg = "ChartFirst 0";
//    chart_num = 0;
//  } else if(!b_again){
//    current_win_chartid2 = ChartNext(current_win_chartid);
//    if(current_win_chartid2<0) {
//      current_win_chartid = ChartFirst();
//      //Print("ChartFirst");
//      g_msg = "ChartFirst 0";
//      chart_num = 0;
//    } else {
//      chart_num++;
//      g_msg = "Chart " + IntegerToString(chart_num);
//      current_win_chartid = current_win_chartid2;
//    }
//  }
  current_win_chartid = 0;
  g_ClientHandle = (int)ChartGetInteger(current_win_chartid,CHART_WINDOW_HANDLE);
  Print("ClientHandle0: "+IntegerToString(g_ClientHandle));
  printf("0x%X",g_ClientHandle);
  if(g_ClientHandle != 0)
    g_ThisWinHandle = GetParent(g_ClientHandle);
  Print("g_ThisWinHandle: "+IntegerToString(g_ThisWinHandle));
  printf("0x%X",g_ThisWinHandle);
  if(g_ThisWinHandle != 0)
    g_ParentWinHandle = GetParent(g_ThisWinHandle);
  Print("g_ParentWinHandle: "+IntegerToString(g_ParentWinHandle));
  printf("0x%X",g_ParentWinHandle);
  g_wTopHandle = GetAncestor((int)ChartGetInteger(0,CHART_WINDOW_HANDLE),GA_ROOT);
  Print("wTopHandle: "+IntegerToString(g_wTopHandle));
  printf("0x%X",g_wTopHandle);

//  int hwndMT4 = FindWindowW("MetaQuotes::MetaTrader::4.00", NULL);
//  if (hwndMT4 == 0) {
//    Print("-1");
//    return ;
//  }
//
//  int hwndMDIClient = FindWindowExW(hwndMT4, 0, "MDIClient", NULL);
//  if (hwndMDIClient == 0) {
//    Print("-2");
//    return ;
//  }
//
//  //int hwndAboveChart = FindWindowExW(hwndMDIClient, 0, "Afx:00610000:b:00010003:00000006:000715CD", NULL);
//  int hwndAboveChart = FindWindowExW(hwndMDIClient, 0, "Afx:00030000:b:00010003:00000006:00041355", NULL);
//  if (hwndAboveChart == 0) {
//    Print("-3");
//    return ;
//  }
//
  int hwndChart = FindWindowExW(g_ClientHandle, 0, "AfxFrameOrView140s", NULL);
  if (hwndChart == 0) {
    Print("-4");
  } else {
    Print("hwndChart: "+IntegerToString(hwndChart));
    printf("0x%X",hwndChart);
  }

  int hwndEdit = FindWindowExW(g_ClientHandle, 0, "Edit", NULL);
  if (hwndEdit == 0) {
    Print("-5");
  } else {
    Print("hwndEdit: "+IntegerToString(hwndEdit));
    printf("0x%X",hwndEdit);
  }

  string lpString = "123456789012345678901234567890123456789012345678901234567890";
  lpString = "123456789012345678901234567890123456789012345678901234567890";
  lpString = "0.0000000000000000000000000000000000000000000000000000000000";

  //string dwResult = "1234";
  //int iret = SendMessageTimeoutW(hwndEdit, WM_GETTEXT, 60, lpString,
  //                SMTO_ABORTIFHUNG, 100, dwResult);
  //Print(iret);
  //Print(lpString);
  //SendMessageA(hwndEdit, EM_SETSEL, 0, -1);
  //SendMessageA(hwndEdit, EM_SETSEL, 0, 2);
  //SendMessageA(hwndEdit, EM_LINESCROLL, 0, 0);
  //SendMessageA(hwndEdit, EM_TAKEFOCUS, 0, 0);
//
//  PostMessageA(hwndChart, WM_NEXTDLGCTL, hwndEdit, True);

  //SendMessageA(hwndEdit, WM_LBUTTONDOWN, 0, -1);
  //SendMessageA(hwndEdit, WM_LBUTTONUP, 0, -1);

  int i_return = 0;
  unsigned int ui_return = 0;

//  SetFocus(hwndChart);
//  SetActiveWindow(hwndChart)
  //i_return = SetFocus(hwndEdit);
//  Print("SetFocus i_return = ",i_return);
  //i_return = SetActiveWindow(hwndEdit);
//  Print("SetActiveWindow i_return = ",i_return);
  //i_return = SetCapture(hwndEdit);
//  Print("SetCapture i_return = ",i_return);
//
//  i_return = SetFocus(hwndEdit);
//  Print("SetFocus i_return = ",i_return);
//  i_return = SetActiveWindow(hwndEdit);
//  Print("SetActiveWindow i_return = ",i_return);
//  i_return = SetCapture(hwndEdit);
//  Print("SetCapture i_return = ",i_return);


  //long l_style = GetWindowLongA(hwndEdit, GWL_STYLE);
  //printf("l_style = 0%x",l_style);
  //SetWindowLongA(hwndEdit, GWL_STYLE, WS_TABSTOP | l_style);

  //SendMessageA(g_ParentWinHandle, WM_MDIACTIVATE, hwndEdit, 0);
  //SendMessageA(g_ThisWinHandle, WM_COMMAND, (EN_SETFOCUS << 16) |  1384, hwndEdit);
  //SendMessageA(g_ThisWinHandle, WM_COMMAND, (EN_CHANGE << 16) |  1384, hwndEdit);
  //SendMessageA(g_ThisWinHandle, WM_COMMAND, (EN_UPDATE << 16) |  1384, hwndEdit);

  //int hDC = GetWindowDC(hwndEdit);
  int rect[4];
  GetWindowRect(hwndEdit, rect);
  int wW = rect[2] - rect[0]; // ウィンドウの幅
  int wH = rect[3] - rect[1]; // ウィンドウの高さ
  //Print("rect[0] : ",rect[0]);
  //Print("rect[1] : ",rect[1]);
  //Print("rect[2] : ",rect[2]);
  //Print("rect[3] : ",rect[3]);
  //string str_watasu = "0.22";
  //SetWindowTextW(hwndEdit, str_watasu);
  //int pInputs[] = { INPUT_MOUSE, 0xFFFF, 0xFFFF, 0, 0x8001, 0, 0};


  int pInputs0[] = { INPUT_MOUSE, 0,
                     0, 0, MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE, 0, 0
                   };

  //absX = (x * 65535) / (Screen.PrimaryScreen.Bounds.Width - 1);
  //absY = (y * 65535) / (Screen.PrimaryScreen.Bounds.Height - 1);
  pInputs0[1] = ((rect[2] + rect[0])*65535)/2/(1280-1);
  pInputs0[2] = ((rect[3] + rect[1])*65535)/2/(1024-1);

  int pInputs1[] = { INPUT_MOUSE, 0,
                     0, 0, MOUSEEVENTF_LEFTDOWN | MOUSEEVENTF_ABSOLUTE, 0, 0
                   };
  //pInputs1[1] = (rect[2] + rect[0])/2;
  //pInputs1[2] = (rect[3] + rect[1])/2;
  pInputs1[1] = ((rect[2] + rect[0])*65535)/2/(1280-1);
  pInputs1[2] = ((rect[3] + rect[1])*65535)/2/(1024-1);

  //Print("pInputs[1] : ",pInputs[1], "    pInputs[2] : ",pInputs[2]);

  int pInputs2[] = { INPUT_MOUSE, 0,
                     0, 0, MOUSEEVENTF_LEFTUP | MOUSEEVENTF_ABSOLUTE, 0, 0
                   };
  //pInputs2[1] = (rect[2] + rect[0])/2;
  //pInputs2[2] = (rect[3] + rect[1])/2;
  pInputs2[1] = ((rect[2] + rect[0])*65535)/2/(1280-1);
  pInputs2[2] = ((rect[3] + rect[1])*65535)/2/(1024-1);

  //Print("pInputs2[1] : ",pInputs2[1], "    pInputs2[2] : ",pInputs2[2]);

  b_again = false;

  if(!bMinimizeOrBack(current_win_chartid, g_wTopHandle, g_ParentWinHandle)) {
    Print("current_win_chartid = ", current_win_chartid);
    //for(int index = 0; index < 99 ; index++) {
    //Print("chartid_arr[index] = ", chartid_arr[index]);
    Print("lot_clicked = ", lot_clicked);
    if(false && false == lot_clicked) {
      //SendInput(1, pInputs0, 28);
      //SendInput(1, pInputs1, 28);
      //SendInput(1, pInputs2, 28);
      lot_clicked = true;
      //b_again = true;
      //Kernel32::Sleep(5000);
    }

  }


//bool b_ret = SetForegroundWindow(hwndEdit);
//Print("SetForegroundWindow b_ret = ",b_ret);
//b_ret = BringWindowToTop(hwndEdit);
//Print("BringWindowToTop b_ret = ",b_ret);
//SendMessageA(hwndEdit, WM_ACTIVATE, 1, 0);
//SendMessageA(hwndEdit, BM_CLICK, 0, 0);

//SendMessageA(g_ThisWinHandle, WM_LBUTTONDOWN, MK_LBUTTON, hwndEdit);

  lpString = "0.0000000000000000000000000000000000000000000000000000000000";
  ui_return = GetWindowTextW(hwndEdit,  lpString, 60);
  if(0< ui_return) {
    Print(ui_return," : ",lpString);
  } else {
    Print("copy zero length.");
  }
//bad
//lpString = "0.0000000000000000000000000000000000000000000000000000000000";
//GetDlgItemTextA(hwndEdit, 1384, lpString, 60);
//Print(lpString);

//bad
//lpString = "0.0000000000000000000000000000000000000000000000000000000000";
//GetDlgItemTextA(g_ClientHandle, 1384, lpString, 60);
//Print(lpString);

  lpString = "0.0000000000000000000000000000000000000000000000000000000000";
  ui_return = GetDlgItemTextW(g_ClientHandle, 1384, lpString, 60);
  if(0<ui_return) {
    Print(ui_return," : ",lpString);
  } else {
    Print("copy zero length.");
  }
//GetWindowTextW(70376,  lpString, 1000);
//Print(lpString);
//GetWindowTextW(70368,  lpString, 1000);
//Print(lpString);
//GetWindowTextW(70392,  lpString, 1000);
//Print(lpString);
//GetWindowTextW(70400,  lpString, 1000);
//Print(lpString);
//GetWindowTextW(70408,  lpString, 1000);
//Print(lpString);
//GetWindowTextW(70424,  lpString, 1000);
//Print(lpString);
//GetWindowTextW(70440,  lpString, 1000);
//Print(lpString);
//GetWindowTextW(70432,  lpString, 1000);
//Print(lpString);

  if(StringToDouble(lpString) == 0){
    Print("initial lot = ", initial_lot);
  }


  Print(ChartSymbol(current_win_chartid)," ",ChartPeriod(current_win_chartid));
  //Print(g_msg);
  Print("OK");


}
//+------------------------------------------------------------------+
bool bMinimizeOrBack(long chartid,int local_hWndTop, int local_hWndParent)
{
  bool bRetCode = true;
  int hWnd_FG = GetForegroundWindow();
  if(ChartGetInteger(chartid,CHART_BRING_TO_TOP)
      && (!IsIconic(local_hWndParent))
      && (!IsIconic(local_hWndTop))
      && hWnd_FG == g_wTopHandle
    ) {
    bRetCode = false;
  }
  return bRetCode;
}
//+------------------------------------------------------------------+
