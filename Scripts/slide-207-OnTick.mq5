//+------------------------------------------------------------------+
//|                                             slide-207-OnTick.mq5 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"



int OnInit() {

   if( !MarketBookAdd( _Symbol ) ) {

      Print("Erro ao realizar a abertura do DOM: ", GetLastError(), " !" );
      return INIT_FAILED ;
   }
   return INIT_SUCCEEDED;
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit( const int reason) {
   MarketBookRelease( _Symbol );
}



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick(void) {
   MqlRates valores[];
// Obtém a última barra/candle
   if(CopyRates(_Symbol,_Period, 0, 1, valores ) < 0) {
      Print("Erro ao copiar os dados do último candle: ", GetLastError(),"!");
      ResetLastError();
      return;
   }
   Print("Preço atual: ", valores[0].close );

}
//+------------------------------------------------------------------+
