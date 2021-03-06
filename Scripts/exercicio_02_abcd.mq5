//+------------------------------------------------------------------+
//|                                            exercicio_02_abcd.mq5 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+

#include <Trade\SymbolInfo.mqh>
CSymbolInfo infoAtivo;


// Exemplo de utilização
int OnInit() {

   infoAtivo.Name(_Symbol);

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


void OnTick() {

}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnBookEvent(const string &symbol) {
//---

   // Variáveis para ofertas de venda (ASK)
   double vendaMelhorOfertaPreco = 0 ;
   double vendaMelhorOfertaVolume = 0 ;
   double vendaMaiorVolume = 0 ;
   double vendaMaiorVolumePreco = 0 ;

   // Variáveis para ofertas de compra (BID)
   double compraMelhorOfertaPreco = 0 ;
   double compraMelhorOfertaVolume = 0 ;
   double compraMaiorVolume = 0;
   double compraMaiorVolumePreco = 0 ;

   // Lotes de venda e compra acumulados
   double loteVendaAcumulado = 0 ;
   double loteCompraAcumulado = 0 ;


   MqlBookInfo bookOfertas[];
   bool buscarBookOfertas = MarketBookGet( _Symbol, bookOfertas);

   if( buscarBookOfertas ) {

      int tamanhoBookOfertas = ArraySize(bookOfertas);
      Print("Book de Ofertas do ativo ", _Symbol );
      Print("Atividade 2");
      if ( tamanhoBookOfertas ) {

         for(int i = 0; i < tamanhoBookOfertas; i++) {

            // atribui a variável 'oferta' o conjunto de dados que está na posição 'i'
            MqlBookInfo oferta = bookOfertas[i];

            // tipo da oferta "1", é uma oferta de venda (ASK)
            //if ( oferta.type == BOOK_TYPE_SELL || oferta.type == BOOK_TYPE_SELL_MARKET ) {
            if ( oferta.type == 1 ) {
               Print("Ordem de venda (ASK) -> preco: ", oferta.price, " - Volume: ", oferta.volume );
               loteVendaAcumulado += oferta.volume ;

               // Pegar a melhor oferta de venda (menor preço) (ASK) e seu volume
               if ( oferta.price <= vendaMelhorOfertaPreco ) {
                  vendaMelhorOfertaPreco = oferta.price ;
                  vendaMelhorOfertaVolume = oferta.volume ;

               }

               // Determinar o nível de preço de venda com o maior volume
               if( oferta.volume >= vendaMaiorVolume) {
                  vendaMaiorVolume = oferta.volume ;
                  vendaMaiorVolumePreco = oferta.price ;
               }
            }

            // tipo de oferta "2", é uma oferta de compra (BID)
            //if ( oferta.type == BOOK_TYPE_BUY || oferta.type == BOOK_TYPE_BUY_MARKET ) {
            if ( oferta.type == 2 ) {
               Print("Ordem de compra (BID) -> preco: ", oferta.price, " -> Volume: ", oferta.volume );
               loteCompraAcumulado += oferta.volume;

               // Pegar a melhor oferta de compra (maior preço) (BID) e seu volume
               if ( oferta.price >= compraMelhorOfertaPreco ) {
                  compraMelhorOfertaPreco = oferta.price;
                  compraMelhorOfertaVolume = oferta.volume;
               }

               // Determinar o nível de preço de compra com o maior volume
               if( oferta.volume > compraMaiorVolume ) {
                  compraMaiorVolume = oferta.volume ;
                  compraMaiorVolumePreco = oferta.price ;
               }
            }

         }
         
         infoAtivo.Refresh();
         
         Print("<- 2.A -> ");
         Print("<- Preços de ASK e BID ->");
         Print("Melhor Oferta de Venda....: ", vendaMelhorOfertaPreco, " / ", infoAtivo.Ask(),  " Volume...: ", vendaMelhorOfertaVolume);
         Print("Melhor Oferta de compra...: ", compraMelhorOfertaPreco, " / ", infoAtivo.Bid(), " Volume...: ", compraMelhorOfertaVolume );

         Print(" ");
         Print("<- 2.B ->");
         Print("<- Total de lotes de venda e compra ->" );
         Print("Volume total de venda.....: ", loteVendaAcumulado  );
         Print("Volume total de compra....: ", loteCompraAcumulado );

         Print(" ");
         Print("<- 2.C ->");
         Print("<- Compra ->");
         Print("Maior volume de compra..:", compraMaiorVolume, " Preço..: ", compraMaiorVolumePreco);

         Print(" ");
         Print("<- 2.D ->");
         Print("<- Compra ->");
         Print("Maior volume de venda...:", vendaMaiorVolume,  " Preço..: ", vendaMaiorVolumePreco);

      } else {

         Print("tamanhoBookOfertas : ", tamanhoBookOfertas, " - ", _Symbol );
         Print("buscarBookOfertas  : ", buscarBookOfertas, " - ", _Symbol );
      }

   }

}
//+------------------------------------------------------------------+


//   Print(" Fora de horario. Não há book de ofertas: ", _Symbol );
//+------------------------------------------------------------------+
