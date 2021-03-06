//+------------------------------------------------------------------+
//|                                 teste_com_include_SymbolInfo.mq5 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+

#include <Trade\SymbolInfo.mqh>
CSymbolInfo infoAtivo;




//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnStart(void) {
   MqlRates valores[];
// Obtém a última barra/candle
   if(CopyRates(_Symbol,_Period, 0, 1, valores ) < 0) {
      Print("Erro ao copiar os dados do último candle: ", GetLastError(),"!");
      ResetLastError();
      return;
   }

   Print("Teste...: ", infoAtivo.Ask);

   Print("Preço atual: ", valores[0].close );
}


//+------------------------------------------------------------------+
