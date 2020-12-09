// ahtodo aggiornato a 20200926
// prendere il diff dopo quello e implementarlo (ci sono varie differenze)

// alla fine compara le differenze con ahtodo_old, soprattutto in OnInit e OnTick. Sarà difficile.

// PORTARE TUTTE LE VARIABILI IN ALTO (ANCHE IN PIVOT). usare enum quando necessari

// Definire funzione throwexception con messaggio e throwfatalexception

// eurjpy bug???: DrawPatternRectangle ha bisogno del nome del pattern

// bug nzdusd e audusd
// bug grafico grigio nuovi cross. era losslimiter!

// il download di data come altri symbol richiede CPU?



// Senza lo sleep si possono creare ordini contemporanei, fare che il bot controlla
// sempre ed elimina 1 ordine a caso (o il peggiore) se ne trova +1 correlati.
// Tra l'altro si può creare una funzione specifica che compara ordini per trovare
// il migliore, che poi viene usata in CompareTwinOrders forse.

// quando si mette startindexfororder controllare candele piu recenti con tolleranza minore


// dataype orderinfo (sl, tp, comment, lots,...). comment dev'essere una funzione separata.
// poi passare orderinfo al codice che metter ordine.
// moduli piu picocli an che per le rette per testare il piu possibile?

// funzioni mask per evitare funzioni interne tipo period e symbol?
// mock funzioni interne per test?

// modularizzare CheckOrderSetups e ottimizzare esecuzione. funzione separata per timewindows




/**

// 20201005: gbpchf bug molti ordini di pomeriggio, normalizzare i valori a 4 digits prima di fare le
// sottrazioni potrebbe aiutare, altrimenti si lascia 1 pip extra


15:35:17.126 ahtodo GBPCHF,M30: OldOrderLotsModulationFactor: 1
15:35:17.126 ahtodo GBPCHF,M30: NewOrderLotsModulationFactor: 1
15:35:17.126 ahtodo GBPCHF,M30: OldOrderStopLossPips: 23
15:35:17.126 ahtodo GBPCHF,M30: NewOrderStopLossPips: 22

*/

// doji troppo ciccione, dimagrire per eurusd h4 stoploss

// iniziare a processare news?

// https://www.mql5.com/en/articles/1502

// antipattern che funzioni su tutti i timeframe. Cioe su h1 comunque controllo anche m30 e h4

// h4 mettere orari piu umani tanto non ci sono breakout di notte

// PivotLabels SONO ANCORA MIGLIORABILI, passando solo pivotStyle e riarrangiando quella classe internamente si possono passare meno parametri qui
// e poi la funzione per le rette è abbastanza generica che magari si può estrarre? non per forza pero
// inoltre la funzione che fa il check della steep trendline non ha bisogno che la trendline sia creata, basta fare (x1-x2)/(t1-t2)
// e poi credo che una classe trendlinestyle sia necessaria. (e per le rette vedere se la pivotline appartiene a style o no

// per h4 usare solo doji magre (quindi creare fatDoji per i multipattern)

// loggare per informazione quando un trade che ha gia preso il breakeven va di nuovo sotto lo zero
// prendere i trade "#from 123891"

// poi per le funzioni che loopano gli ordini aperti fare che ottengono e ritornano la lista di trade aperti.

// ordini aperti: se in negativo dopo le 16, chiudere?

// unittest che salvano file report con data interna del bot? oppure li eseguo solo io?

// salvare dettagli ordine su un log separato, sia per dropbox che per dimezzare

// unittest messaggio obbligatorio? forse no per ogni assert ma solo opzionale, ad ogni modo i singoli test devono dare un resoconto se sono passati o no, non ci si puo affidare solo ai singoli failures


// si potrebbero avere anche dei runtime test, ad esempio uno che controlla ogni tanto la pendenza di tutte le rette? boh forse non ha senso


// potrebbe essere drawer a settare i colori del mercato, sia nel costruttore che a ogni tick a seconda della situazione di mercato

// controlla tutti gli usi di timelocal, timecurrent, timegmt. pericoloso usare quello sbagliato. A volte serve timecurrent (data ordine).
// per apertura mercato usa timeGMT piu lo shift

// chiudere la sofferenza e se un trade è negativo e senza breakeven dopo 1 ora (o 30 min) chiuderlo?
// Magari se non ha preso il be dopo mezzora chiuderlo in ogni caso (a meno che non sia positivo e allora mettere sl a 0)

// fare 1 trade al giorno per cross? Solo se il prcedente è TP o SL? o solo SL? in generale, tanto quando entra 1 l'altro viene tolto, quindi non si puo prendere il movimento inverso

// arrotondare size modulation ad 1 cifra (no 0.99)

// dopo che la pending hour è passata metti il grafico grigio se non ci sono ordini aperti

// mettere alert a losslimiter e altre cose in cui è utile

// sistemare breakeven per farli esattamente a zero? Commissione?

// mettere tutti gli spazi giusti tra if/for e mettere tutte le graffe. Non permettere operatori senza graffe!!

// alert in unittest (senza farli fallire) se TimeLocal != TimeItaly

// fare JDOCS?

// stampare tutti i log con stringa DEBUG invece che non stamparli? o non stamparli ma aggiungere comunque DEBUG

// check timezone of drawOpenMarketLines()

// const function arguments when they don't have to change

// Ora che le exception fanno alert, si possono mettere in ancora piu punti per verificare il codice

// posso fare molti piu print sulle trendline per gli ordini se sono 1 volta a candela!

// controllare in tutti i file se Constants.mqh è usato, altrimenti togliere l'import

// throwexception con argomenti multiple per non dover usare stringconcat?

// implementa take profit che guarda i livelli orizzontali precedenti
// implementa stoploss trailing sotto al minimo precedente

// aprire sessione alle 8?
