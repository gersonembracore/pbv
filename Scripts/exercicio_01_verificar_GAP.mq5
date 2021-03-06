//+------------------------------------------------------------------+
//|                                     exercicio_2019-10-09_001.mq5 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
//---
// Criar um vetor com os dados que precisamos
   MqlRates vetCandles[];

//ArraySetAsSeries(vetCandles, true);

   int totalCopiado = CopyRates(_Symbol, PERIOD_D1, 0, 10, vetCandles);
   
   if( totalCopiado <= 0 ) {
      Print("Erro ao copiar os dados dos candles. ");
      return;
      
   } else {
      
         for( int i=totalCopiado - 1; i > 0; i-- ) {
            MqlRates candleAtual = vetCandles[i];
            if( i >= 0 ) {
      
               MqlRates candleAnt = vetCandles[i - 1];
                     
               if( candleAtual.open > candleAnt.close ) {
                  Print("GAP de alta entre os dias ", candleAnt.time, " Close Anterior: ", candleAnt.close, " e ", candleAtual.time, " Open Atual: ", candleAtual.open  );
      
               } else {
                  Print("GAP de baixa entre os dias ", candleAnt.time, " Close Anterior: ", candleAnt.close,  " e ", candleAtual.time, " Open Atual: ", candleAtual.open  );
      
               }
            }
            //Print("Data: ", candle.time, " - Preço de fechamento: ", candle.close );
         }
    }
}
//+------------------------------------------------------------------+
