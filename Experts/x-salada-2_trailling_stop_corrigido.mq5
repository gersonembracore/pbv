//+------------------------------------------------------------------+
//|                                               PBV-Elliot-001.mq5 |
//|                                                   Gerson Pereira |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Gerson Pereira"
#property description "Robô, baseado nas ondas de Elliott e números de Fibonacci. Possui automação com telegram. \ngerson@embracore.com.br"
#property link      "https://www.mql5.com"
#property version   "2.13"
#resource "\\Indicators\\Examples\\ZigZag.ex5";
#resource "\\Indicators\\linear_regression.ex5";

#include <Trade\AccountInfo.mqh>
CAccountInfo infoConta;

#include <Trade\SymbolInfo.mqh>
CSymbolInfo ativoInfo;

#include <Trade\Trade.mqh>
CTrade trade;

int idRobo = 3974 ;

#include <Trade\OrderInfo.mqh>
COrderInfo ordPend;

#include <ChartObjects\ChartObjectsArrows.mqh>
CChartObjectArrow icone;

datetime tempoCandleBuffer[];

int      totalCopiarBuffer = 100;

// Variáveis das ondas maiores
long     volumeBuffer[];
double   zzTopoBuffer[];
double   zzFundoBuffer[];
datetime zzDataFundo[];
datetime zzDataTopo[];
int      zzHandle;
input int zzProfundidade = 3; // Profundidade



// Variáveis das ondas menores (ondas dentro das ondas maiores)
long     volumeBuffer2[];
double   zzTopoBuffer2[];
double   zzFundoBuffer2[];
datetime zzDataFundo2[];
datetime zzDataTopo2[];
int      zzHandle2;
input int zzProfundidade2 = 3 ; // Profundida das ondas menores
//int zzProfundidade2 = 3 ; // Profundida das ondas menores



// Região para entrada das operações
input double regiaoPrecoInicio = 0.786; // Região de preço de início
input double regiaoPrecoFim = 0.950; // Região de preço de fim


input double volumeOperacao = 5; // Volume a ser operado

MqlDateTime dt;

input int mercadoHoraInicio = "09" ; // Hora de início das operações
input int mercadoMinutoInicio = "30" ; // Minuto de início das operações

input int mercadoHoraFimOpen = "17" ; // Hora de fim das operações
input int mercadoMinutoFimOpen = "00" ; // Minuto de fim das operações

input int mercadoHoraFimClose = "17" ; // Hora de fim das operações
input int mercadoMinutoFimClose = "50" ; // Minuto de fim das operações

input double maxMinPercentual = 0.37 ; // Percentual LH

bool isPosicaoAberta = false;
ENUM_POSITION_TYPE tipoPosicaoAberta ;

double takeProfit = 0;
double stopLoss = 0;


// Pontos para definicção do stopLoss no trailling stop
double input takeProfitPontos = 50 ; //Pontos para o TakeProfit
double input stopLossPontos = 100 ; //Pontos para o StopLoss


double precoAtual ;

//input double deltaStopPercentual = 0.41; // Percentual do Delta Stop
//double deltaStop = 0 ;

// Topo da Onda Maior
double   Onda1PrecoTopoA;
double   Onda1PrecoTopoB;
double   Onda1PrecoTopoC;
datetime Onda1DataTopoA;
datetime Onda1DataTopoB;
datetime Onda1DataTopoC;

// Fundo Onda Maior
double   Onda1PrecoFundoA;
double   Onda1PrecoFundoB;
double   Onda1PrecoFundoC;
datetime Onda1DataFundoA;
datetime Onda1DataFundoB;
datetime Onda1DataFundoC;

//Topo da Onda Menor
double   Onda2PrecoTopoA;
double   Onda2PrecoTopoB;
datetime Onda2DataTopoA;
datetime Onda2DataTopoB;

// Fundo da Onda menor
double   Onda2PrecoFundoA;
double   Onda2PrecoFundoB;
datetime Onda2DataFundoA;
datetime Onda2DataFundoB;


string nomeIcone = "icone";


// TELEGRAM
#include <Telegram.mqh>

//--- input parameters
//input string InpChannelName = "EmbraSignalChannel"; //Channel Name
//input string InpToken = "1023249675:AAGxeQdFMpSdwvxjigLem61RNQeXN2n1odo"; //Token
string InpChannelName = "EmbraSignalChannel"; //Channel Name
string InpToken = "1001305677587:AAGxeQdFMpSdwvxjigLem61RNQeXN2n1odo"; //Token

//--- global variables
CCustomBot bot;
datetime time_signal = 0;
bool checked;



//--- Tratativa das notificações para o App Metatrader
int appNotificaTrava = 0 ;
int appNotificaMinuto = 0;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   zzHandle = iCustom(_Symbol, _Period, "::Indicators\\Examples\\ZigZag.ex5", zzProfundidade);
   if(zzHandle == INVALID_HANDLE)
     {
      Print("Falha ao criar o indicador ZigZag: ", GetLastError());
      return(INIT_FAILED);
     }


   zzHandle2 = iCustom(_Symbol, _Period, "::Indicators\\Examples\\ZigZag.ex5", zzProfundidade2);
   if(zzHandle2 == INVALID_HANDLE)
     {
      Print("Falha ao criar o indicador ZigZag menor: ", GetLastError());
      return(INIT_FAILED);
     }


// define para acessar como timeseries
   ArraySetAsSeries(zzTopoBuffer, true);
   ArraySetAsSeries(zzFundoBuffer, true);
   ArraySetAsSeries(zzDataFundo, true);
   ArraySetAsSeries(zzDataTopo, true);


   double   saldo = infoConta.Balance();
   double   lucro = infoConta.Profit();
   double   margemDisp = infoConta.FreeMargin();
   bool     isPermitidoTrade = infoConta.TradeAllowed();
   bool     isPermitidoRobo = infoConta.TradeExpert();    //Slide -> isPermitidoRoto
// ...
// Print("Saldo: ", saldo, " ", margemDisp);

   time_signal = 0;
   bot.Token(InpToken);

   return(INIT_SUCCEEDED);
  }




//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(zzHandle);
   fecharTodasOrdensPendentesRobo();
   fecharTodasPosicoesRobo();

   if(reason == REASON_PARAMETERS ||
      reason == REASON_RECOMPILE ||
      reason == REASON_ACCOUNT)
     {
      checked = false;
     }
  }



//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---



// Fechar todas as ordens e posições abertas fora do horário previamente configurado
   if(!TimeSession(mercadoHoraInicio, mercadoMinutoInicio, mercadoHoraFimClose, mercadoMinutoFimClose))
     {
      fecharTodasOrdensPendentesRobo();
      fecharTodasPosicoesRobo();
      return;
     }



// Se o ativo ainda não estiver sincronizado, retornar.
   if(!ativoInfo.IsSynchronized())
     {
      return ;
     }

   /*
      +------------------------------------------+
      | Tratamento dos buffers das ONDAS MAIORES |
      +------------------------------------------+
   */

// copia os topos das ondas maiores
   if(CopyBuffer(zzHandle, 1, 0, totalCopiarBuffer, zzTopoBuffer) < 0)
     {
      Print("Erro ao copiar dados dos topos das ondas maiores: ", GetLastError());
      return;
     }

// copia os fundos das ondas maiores
   if(CopyBuffer(zzHandle, 2, 0, totalCopiarBuffer, zzFundoBuffer) < 0)
     {
      Print("Erro ao copiar dados dos fundos das ondas maiores: ", GetLastError());
      return;
     }

// Copiar datas e horas dos topos das ondas maiores
   if(CopyTime(_Symbol, _Period, 0, totalCopiarBuffer, zzDataTopo) < 0)
     {
      Print("ERRO ao copiar datas topos das ondas maiores");
      return;
     }

// Copiar datas e horas dos fundos das ondas maiores
   if(CopyTime(_Symbol, _Period, 0, totalCopiarBuffer, zzDataFundo) < 0)
     {
      Print("ERRO ao copiar datas fundos das ondas maiores");
      return;
     }




   /*
      +------------------------------------------+
      | Tratamento dos buffers das ONDAS MENORES |
      +------------------------------------------+
   */

// copia os topos das ondas menores
   if(CopyBuffer(zzHandle2, 1, 0, totalCopiarBuffer, zzTopoBuffer2) < 0)
     {
      Print("Erro ao copiar dados dos topos das ondas menores: ", GetLastError());
      return;
     }

// copia os fundos das ondas menores
   if(CopyBuffer(zzHandle2, 2, 0, totalCopiarBuffer, zzFundoBuffer2) < 0)
     {
      Print("Erro ao copiar dados dos fundos das ondas menores: ", GetLastError());
      return;
     }

// Copiar datas e horas dos topos das ondas menores
   if(CopyTime(_Symbol, _Period, 0, totalCopiarBuffer, zzDataTopo2) < 0)
     {
      Print("ERRO ao copiar datas topos das ondas menores");
      return;
     }

// Copiar datas e horas dos fundos das ondas menores
   if(CopyTime(_Symbol, _Period, 0, totalCopiarBuffer, zzDataFundo2) < 0)
     {
      Print("ERRO ao copiar datas fundos das ondas menores");
      return;
     }


   int tamArrayTopo = ArraySize(zzTopoBuffer);
   int tamArrayFundo = ArraySize(zzFundoBuffer);


   int tamArrayTopo2 = ArraySize(zzTopoBuffer2);
   int tamArrayFundo2 = ArraySize(zzFundoBuffer2);




// Resetar os contadores para buscar os últimos topos e fundos depois que o
// ativo for sincronizado

   int nrTopoA = 0;
   int nrFundoA = 0 ;

   int nrTopoB = 0;
   int nrFundoB = 0 ;




// Atualizar informações do ativo
   ativoInfo.Refresh();
   ativoInfo.RefreshRates();



   /*
      +-----------------------------------------+
      | Buscar topos e fundos das ondas MAIORES |
      +-----------------------------------------+
   */
// Laço para buscar os topos das ondas maiores
   for(int i = 0 ; i < tamArrayTopo ; i++)
     {

      // processar topos das ondas maiores
      if(zzTopoBuffer[i] != 0)
        {
         if(nrTopoA == 0)
           {
            Onda1PrecoTopoA = zzTopoBuffer[i];
            Onda1DataTopoA = zzDataTopo[i];

           }
         else
            if(nrTopoA == 1)
              {
               Onda1PrecoTopoB = zzTopoBuffer[i];
               Onda1DataTopoB = zzDataTopo[i];

              }
            else
               if(nrTopoA == 2)
                 {
                  Onda1PrecoTopoC = zzTopoBuffer[i];
                  Onda1DataTopoC = zzDataTopo[i];
                  break;
                 } // Fim da condição para obter o topo anterior

         nrTopoA++; // Incrementar um número ao topo para que na próxima, pegue o topo anterior
        } // fim do processar topos
     } //Fim do laço para obter topos e topos



// Laço para buscar os fundos das ondas maiores
   for(int i = 0 ; i < tamArrayFundo ; i++)
     {
      // processar fundos
      if(zzFundoBuffer[i] != 0)
        {
         if(nrFundoA == 0)
           {
            Onda1PrecoFundoA = zzFundoBuffer[i];
            Onda1DataFundoA = zzDataFundo[i];

           }
         else
            if(nrFundoA == 1)
              {
               Onda1PrecoFundoB = zzFundoBuffer[i];
               Onda1DataFundoB = zzDataFundo[i];

              }
            else
               if(nrFundoA == 2)
                 {
                  Onda1PrecoFundoC = zzFundoBuffer[i];
                  Onda1DataFundoC = zzDataFundo[i];
                  break;
                 } // Fim da condição para obter o topo anterior
         nrFundoA++; // Incrementar um número ao fundo para que na próxima, pegue o fundo anterior
        } // fim do processar fundos
     } //Fim do laço para obter topos e fundos






   /*
      +-----------------------------------------+
      | Buscar topos e fundos das ondas MENORES |
      +-----------------------------------------+
   */
// Laço para buscar os topos das ondas menores
   for(int i = 0 ; i < tamArrayTopo2 ; i++)
     {

      // processar topos das ondas menores
      if(zzTopoBuffer2[i] != 0)
        {
         if(nrTopoB == 0)
           {
            Onda2PrecoTopoA = zzTopoBuffer2[i];
            Onda2DataTopoA = zzDataTopo2[i];

           }
         else
            if(nrTopoB == 1)
              {
               Onda2PrecoTopoB = zzTopoBuffer2[i];
               Onda2DataTopoB = zzDataTopo2[i];
               break;
              } // Fim da condição para obter o topo anterior

         nrTopoB++; // Incrementar um número ao topo para que na próxima, pegue o topo anterior
        } // fim do processar topos
     } //Fim do laço para obter topos e topos


// Laço para buscar os fundos das ondas menores
   for(int i = 0 ; i < tamArrayFundo2 ; i++)
     {
      // processar fundos
      if(zzFundoBuffer2[i] != 0)
        {
         if(nrFundoB == 0)
           {
            Onda2PrecoFundoA = zzFundoBuffer2[i];
            Onda2DataFundoA = zzDataFundo2[i];
           }
         else
            if(nrFundoB == 1)
              {
               Onda2PrecoFundoB = zzFundoBuffer2[i];
               Onda2DataFundoB = zzDataFundo2[i];
               break;
              } // Fim da condição para obter o topo anterior
         nrFundoB++; // Incrementar um número ao fundo para que na próxima, pegue o fundo anterior
        } // fim do processar fundos
     } //Fim do laço para obter topos e fundos






// Chamar o método para análise e execução de ordens no padrão Elliott-1
   Elliott_1() ;


// Chamar a função para realizar o trailling stop (stop móvel)
   TraillingStop(precoAtual);


  } //Fim do OnTick
//====================================================================================================






/*
   ============================================
   Função para operar com o padrão de Elliott-1
   ============================================
*/
void Elliott_1()
  {

   /*
      Verificar  através da data atual do topo e do fundo da onda atual se a possível operação
      é para compra ou para venda
   */

   if(Onda1DataFundoA > Onda1DataTopoA)
     {

      /*
         +--------------------+
         | Operação de COMPRA |
         +--------------------+
      */

      // Cálculos de volume para ser usado juntamente com as decisões nas regiões de entrada de operações
      double volumeAnterior = somarVolume(Onda1DataFundoB, Onda1DataTopoA);
      double volumeAtual = somarVolume(Onda1DataTopoA, Onda1DataFundoA);

      precoAtual = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);

      // Definições das regiões de entrada para operações de compra
      double precoCompraRegiao1 = NormalizeDouble((Onda1PrecoTopoA - ((Onda1PrecoTopoA - Onda1PrecoFundoB) * regiaoPrecoInicio)) * ativoInfo.Point(), ativoInfo.Digits()) ;
      double precoCompraRegiao2 = NormalizeDouble((Onda1PrecoTopoA - ((Onda1PrecoTopoA - Onda1PrecoFundoB) * regiaoPrecoFim))    * ativoInfo.Point(), ativoInfo.Digits()) ;

      //stopLoss   = NormalizeDouble(ativoInfo.Ask() - (stopLossPontos * ativoInfo.Point()),   ativoInfo.Digits());
      stopLoss   = NormalizeDouble(ativoInfo.Bid() - stopLossPontos   * ativoInfo.Point(), ativoInfo.Digits());
      takeProfit = NormalizeDouble(ativoInfo.Bid() + takeProfitPontos * ativoInfo.Point(), ativoInfo.Digits());

      double diffMaxMinDia = NormalizeDouble(ativoInfo.LastHigh() - ativoInfo.LastLow(), ativoInfo.Digits());

      double minimaDiaA    = NormalizeDouble(ativoInfo.LastLow(),                          ativoInfo.Digits());
      double minimaDiaB    = NormalizeDouble(ativoInfo.LastLow() + (diffMaxMinDia * maxMinPercentual),ativoInfo.Digits());

      if(precoAtual <= precoCompraRegiao1
         && precoAtual >= precoCompraRegiao2
         && volumeAnterior > volumeAtual
         && Onda1PrecoFundoA > Onda1PrecoFundoB
         && !(Onda1PrecoTopoB > Onda1PrecoTopoC
              && Onda1PrecoTopoB > Onda1PrecoTopoA)
         &&  precoAtual <= minimaDiaB)
        {

         if(buscarPosicaoAbertasByTipo(POSITION_TYPE_SELL) == false && buscarPosicaoAbertasByTipo(POSITION_TYPE_BUY) == false)
           {
            desenharIcone(nomeIcone, Onda1PrecoFundoA, Onda1DataFundoA, clrBlue, 221, 1);

            // Buscar o valor mínimo do lote do ativo e multplica pelo valor definido pelo usuário
            double volOrdem = ativoInfo.LotsMin() * volumeOperacao;

            // Abrir ordem, somente se o horário estiver dentro do ajustado
            if(TimeSession(mercadoHoraInicio, mercadoMinutoInicio, mercadoHoraFimOpen, mercadoMinutoFimOpen))
              {
               //Comment("\n\nR1: ", (Onda1PrecoTopoA - Onda1PrecoFundoB) * regiaoPrecoInicio, " R2: ", (Onda1PrecoTopoA - Onda1PrecoFundoB) * regiaoPrecoFim );
               abrirOrdem(ORDER_TYPE_BUY,  precoAtual, volOrdem, stopLoss, takeProfit, "compra - R1 " + DoubleToString(precoCompraRegiao1 * regiaoPrecoInicio, 1) + "%  R2: " +  DoubleToString(precoCompraRegiao2 * regiaoPrecoFim, 1) + "%");
              }


            // Enviar notificação pelo telegram
            string msg = StringFormat("Name: ELLIOT Signal\xF4E3\nSymbol: %s\nTimeframe: %s\nType: Buy\nPrice: %s\nTime: %s",
                                      _Symbol,
                                      StringSubstr(EnumToString((ENUM_TIMEFRAMES)_Period), 7),
                                      DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits),
                                      TimeToString(ativoInfo.Time()));
            Print(msg);

            int res = bot.SendMessage(InpChannelName, msg);
            if(res != 0)
               Print("Error: ", GetErrorDescription(res));

           }
        }

     }
   else
     {
      /*
         +--------------------+
         | Operação de VENDA  |
         +--------------------+
      */
      double volumeAnterior = somarVolume(Onda1DataTopoB, Onda1DataFundoA);
      double volumeAtual = somarVolume(Onda1DataFundoA, Onda1DataTopoA);

      precoAtual = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);


      double precoVendaRegiao1 =  NormalizeDouble((Onda1PrecoFundoA + ((Onda1PrecoTopoB - Onda1PrecoFundoA) * regiaoPrecoInicio)) * ativoInfo.Point(), ativoInfo.Digits()) ;
      double precoVendaRegiao2 =  NormalizeDouble((Onda1PrecoFundoA + ((Onda1PrecoTopoB - Onda1PrecoFundoA) * regiaoPrecoFim))    * ativoInfo.Point(), ativoInfo.Digits()) ;

      stopLoss   = NormalizeDouble(ativoInfo.Ask() + stopLossPontos   * ativoInfo.Point(), ativoInfo.Digits());
      takeProfit = NormalizeDouble(ativoInfo.Ask() - takeProfitPontos * ativoInfo.Point(), ativoInfo.Digits());


      double diffMaxMinDia = NormalizeDouble(ativoInfo.LastHigh() - ativoInfo.LastLow(), ativoInfo.Digits());
      double maximaDiaA = NormalizeDouble(ativoInfo.LastHigh(),                          ativoInfo.Digits());
      double maximaDiaB = NormalizeDouble(ativoInfo.LastHigh() - (diffMaxMinDia * maxMinPercentual),ativoInfo.Digits());

      if(precoAtual >= precoVendaRegiao1
         && precoAtual <= precoVendaRegiao2
         && volumeAnterior > volumeAtual
         && Onda1PrecoTopoA < Onda1PrecoTopoB
         && !(Onda1PrecoFundoB < Onda1PrecoFundoC
              && Onda1PrecoFundoB < Onda1PrecoFundoA)
         && precoAtual >= maximaDiaB)
        {

         if(buscarPosicaoAbertasByTipo(POSITION_TYPE_SELL) == false && buscarPosicaoAbertasByTipo(POSITION_TYPE_BUY) == false)
           {
            //desenharIcone(nomeIcone, Onda1PrecoFundoA, Onda1DataFundoA, clrRed, 222, 1);

            // Buscar o valor mínimo do lote do ativo e multplica pelo valor definido pelo usuário
            double volOrdem = ativoInfo.LotsMin() * volumeOperacao;

            // Abrir ordem, somente se o horário estiver dentro do ajustado
            if(TimeSession(mercadoHoraInicio, mercadoMinutoInicio, mercadoHoraFimOpen, mercadoMinutoFimOpen))
              {
               // Comment("\n\nR1: ", (Onda1PrecoTopoB - Onda1PrecoFundoA) * regiaoPrecoInicio, " R2: ",  (Onda1PrecoTopoB - Onda1PrecoFundoA) * regiaoPrecoFim  );
               abrirOrdem(ORDER_TYPE_SELL, precoAtual, volOrdem, stopLoss, takeProfit, "venda - R1 " + DoubleToString(precoVendaRegiao1 * regiaoPrecoInicio, 1) + "%  R2: " +  DoubleToString(precoVendaRegiao2 * regiaoPrecoFim, 1) + "%");
              }


            string msg = StringFormat("Name: MACD Signal\xF4E3\nSymbol: %s\nTimeframe: %s\nType: Sell\nPrice: %s\nTime: %s",
                                      _Symbol,
                                      StringSubstr(EnumToString((ENUM_TIMEFRAMES)_Period), 7),
                                      DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits),
                                      TimeToString(ativoInfo.Time()));

            int res = bot.SendMessage(InpChannelName, msg);
            if(res != 0)
               Print("Error: ", GetErrorDescription(res));

           } // Fim da verificação para saber se existem ordens abertas
        } // Fim da condição para analisar, se é o momento de abrir a ordem de VENDA ou não
     } // Fim da condição "else", que caracteriza uma ordem de VENDA

  } // Fim da função Elliott-1






/*
   ============================
   Função para mover o stopLoss
   ============================
*/

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TraillingStop(double newPrecoAtual)
  {



   if(buscarPosicaoAbertasByTipo(POSITION_TYPE_BUY) == true)
     {
      double SL = NormalizeDouble(newPrecoAtual - stopLossPontos * _Point, _Digits);

      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         string symbol = PositionGetSymbol(i);
         if(_Symbol == symbol)
           {
            ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
            double CurrentStopLoss = PositionGetDouble(POSITION_SL);
            double CurrentTakeProfit = PositionGetDouble(POSITION_TP);
            if(CurrentStopLoss < SL)
              {
               trade.PositionModify(PositionTicket, SL, CurrentTakeProfit);
              }
           }
        }
     }


   if(buscarPosicaoAbertasByTipo(POSITION_TYPE_SELL) == true)
     {
      double SL = NormalizeDouble(newPrecoAtual + stopLossPontos * _Point, _Digits);

      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         string symbol = PositionGetSymbol(i);
         if(_Symbol == symbol)
           {
            ulong PositionTicket = PositionGetInteger(POSITION_TICKET);
            double CurrentStopLoss = PositionGetDouble(POSITION_SL);
            double CurrentTakeProfit = PositionGetDouble(POSITION_TP);
            if(CurrentStopLoss > SL)
              {
               trade.PositionModify(PositionTicket, SL, CurrentTakeProfit);
              }
           }
        }
     }

  }





//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double somarVolume(datetime dataInicial, datetime dataFinal)
  {
   int totalCopiado = CopyRealVolume(_Symbol, _Period, dataInicial, dataFinal, volumeBuffer);
   if(totalCopiado < 0)
     {
      return -1;
     }

   double somaVolume = 0;
   for(int i = 0; i < totalCopiado; i++)
     {
      somaVolume += volumeBuffer[i];
     }

   return somaVolume;
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void abrirOrdem(ENUM_ORDER_TYPE tipoOrdem, double preco, double volume, double sl, double tp, string coment = "")
  {


//+-------------------------------------------------------+
   bool result  ; // variável não inicializada no slide
//+-------------------------------------------------------+

   preco = NormalizeDouble(preco, _Digits);
   sl = NormalizeDouble(sl, _Digits);
   tp = NormalizeDouble(tp, _Digits);
   trade.SetExpertMagicNumber(idRobo);
   trade.SetTypeFillingBySymbol(_Symbol);


   if(tipoOrdem == ORDER_TYPE_BUY)
     {
      result = trade.Buy(volume, _Symbol, preco, sl, tp, coment);
     }
   else
      if(tipoOrdem == ORDER_TYPE_SELL)
        {
         result = trade.Sell(volume, _Symbol, preco, sl, tp, coment);
        }
      else
         if(tipoOrdem == ORDER_TYPE_BUY_LIMIT)
           {
            result = trade.BuyLimit(volume, preco, _Symbol, sl, tp, ORDER_TIME_GTC, 0, coment);
           }
         else
            if(tipoOrdem == ORDER_TYPE_SELL_LIMIT)
              {
               result = trade.SellLimit(volume, preco, _Symbol, sl, tp, ORDER_TIME_GTC, 0, coment);
              }
   if(!result)
     {
      Print("Erro ao abrir a ordem ", tipoOrdem, ". Código: ", trade.ResultRetcode());
     }

   obterHistoricoNegociacaoRobo();

  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void fecharTodasPosicoesRobo()
  {
   double saldo = 0;
   int totalPosicoes = PositionsTotal();
   for(int i = 0; i < totalPosicoes; i++)
     {
      string simbolo = PositionGetSymbol(i);
      ulong magic = PositionGetInteger(POSITION_MAGIC);
      if(simbolo == _Symbol && magic == idRobo)
        {
         saldo = PositionGetDouble(POSITION_PROFIT);
         if(!trade.PositionClose(PositionGetTicket(i)))
           {
            Print("Erro ao fechar a negociação. Código: ", trade.ResultRetcode());
           }
         else
           {
            Print("Saldo: ", saldo);
           }
        }
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void obterHistoricoNegociacaoRobo()
  {

//Funções de Negociação
   HistorySelect(0, TimeCurrent());
   uint total = HistoryDealsTotal();
   ulong ticket = 0;
   double price, profit;
   datetime time;
   string symbol;
   long type, entry;
   for(uint i = 0; i < total; i++)
     {
      if((ticket = HistoryDealGetTicket(i)) > 0)
        {
         price = HistoryDealGetDouble(ticket, DEAL_PRICE);
         time = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
         symbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
         type = HistoryDealGetInteger(ticket, DEAL_TYPE);
         entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
         profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
         if(entry == DEAL_ENTRY_OUT)
           {
            string msg = "Ativo:" +  symbol + " - Preço:" +  price + " - Lucro:" + profit ;
            //Print("========================================================>>", msg);


            // Enviar somente uma notificação por minuto para o App do Metatrader
            TimeCurrent(dt);
            int minutoAtual = dt.min;
            if(minutoAtual != appNotificaMinuto)
              {
               appNotificaMinuto = minutoAtual;
               SendNotification(msg);
               //Print("==>> APP - Notificação enviada...");
              }
           }
        }
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void fecharTodasOrdensPendentesRobo()
  {
   for(int i = OrdersTotal() - 1 ; i >= 0; i--)
     {

      // seleciona a ordem pendente por seu índice
      if(ordPend.SelectByIndex(i))
        {

         // se a ordem pendente for do ativo monitorado e aberta pelo robô
         if(ordPend.Symbol() == _Symbol && ordPend.Magic() == idRobo)
           {
            if(!trade.OrderDelete(ordPend.Ticket()))
              {
               Print("Erro ao excluir a ordem pendente ", ordPend.Ticket());
              }
           }
        }
     }
  }



// ---------------------------------------------------------------------
// Método responsável por remover o icone de todo do gráfico pelo nome
// ---------------------------------------------------------------------
void removerIcone(string nome)
  {

// remove
   ObjectDelete(0, nome);

// Print("REMOVER: ", nome);
   ChartRedraw();

  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void desenharIcone(string nome, double preco, datetime data, color cor, int codigoIcone, int tamIcone)
  {

   icone.Create(0, nome, 0, data, preco, codigoIcone) ;
   icone.Color(cor);
   icone.Width(tamIcone);

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool TimeSession(int aStartHour, int aStartMinute, int aStopHour, int aStopMinute)
  {
//--- session start time
   int StartTime = 3600 * aStartHour + 60 * aStartMinute;
//--- session end time
   int StopTime = 3600 * aStopHour + 60 * aStopMinute;
//--- current time in seconds since the day start
//  aTimeCur = aTimeCur % 86400;

   TimeCurrent(dt);
   int horaAtual = (dt.hour * 3600);
   int minutoAtual = (dt.min * 60);
   int segundoAtual = (dt.sec);
   int tempoAtual = horaAtual + minutoAtual + segundoAtual ;

   if(tempoAtual >= StartTime && tempoAtual < StopTime)
     {
      return(true);
     }
   else
     {
      return(false);
     }
  }



//----------------------------------------------------------------------+
// Função responsável por verificar se há posições abertas por tipo.    |
//----------------------------------------------------------------------+
bool buscarPosicaoAbertasByTipo(ENUM_POSITION_TYPE tipoPosicaoBusca)
  {

   isPosicaoAberta = false;

   int totalPosicoes = PositionsTotal();
//Print("POSICOES ABERTAS: " + totalPosicoes + " - Tipo posicao busca: " + EnumToString(tipoPosicaoBusca) );
   double lucroPosicao;

   for(int i = 0; i < totalPosicoes; i++)
     {

      // obtém o nome do símbolo a qual a posição foi aberta
      string simbolo = PositionGetSymbol(i);

      if(simbolo != "")
        {

         // id do robô
         ulong  magic = PositionGetInteger(POSITION_MAGIC);
         lucroPosicao = PositionGetDouble(POSITION_PROFIT);
         ENUM_POSITION_TYPE tipoPosicaoAberta = (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);
         // obtém o simbolo da posição
         string simboloPosicao = PositionGetString(POSITION_SYMBOL);

         // se é o robô e ativo em questão
         if(simboloPosicao == _Symbol && magic == idRobo)
           {

            // caso operação
            if(tipoPosicaoBusca == tipoPosicaoAberta)
              {

               isPosicaoAberta = true;
               tipoPosicaoAberta = tipoPosicaoBusca;

               //Print("RETORNO POSICAO ABERTA: " + EnumToString(tipoPosicaoAberta) + " - ROBO: " + magic);
               //Print("TEM VENDA");
               return true;
              }
           } // fim magic

        }
      else
        {
         PrintFormat("Erro quando recebeu a posição do cache com o indice %d." + " Error code: %d", i, GetLastError());
         ResetLastError();
        }

     } // fim for

   return false;

  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
