typedef NetPlace { chan d = [255] of {byte, byte, byte, bit}}


/*###############################################*/


inline consNetTok(c, p) {
  do:: c ?? [eval(p),_,_,0] -> c ?? eval(p),_,_,0
    :: else -> break
  od; skip }


inline rmConf(l, pc){
  if :: pc ?? [eval(_pid),l,_,_] -> pc ?? eval(_pid),l,_,_
     :: else fi
}


/*###############################################*/


inline transpNetTok(ch, och, p){
  byte v0,v1,v2,v3;
  do:: ch ?? [eval(p),_,_,_] ->
       ch ?? eval(p),v1,v2,v3;
       och ! p,v1,v2,v3;
    :: else -> break
  od; skip }




inline invertMsg(nt, lbl, ch){
    byte v1;


    if:: ch ?? [nt, lbl, v1, 0] ->
    ch ?? nt, lbl, v1, 0;
    ch ! nt, lbl, v1, 1;
    :: else fi
    }


/*###############################################*/


inline recMsg(ch,f0,f1) {             /* ch - ordered "channel, f0 - output variable, f1 - constant value */
ch ! 0,f1;
do :: ch ?? f0,f1;
       if :: f0>0 ->   ch !  f0,f1;
                       cha ! len(cha)+1,f0;
          :: else -> break
       fi
od;


 /* select ( j : 1 .. size_cha); */


    size_cha= len(cha);
   j = 1;
   do
   :: j < size_cha -> j++
   :: break
   od


cha ?? <eval(j),f0>;


 /* restoring the ordering of the input channel */

do :: len(cha)>0 ->
   cha?_,nt1;
   ch ?? eval(nt1),eval(f1);
   ch !! nt1,f1;
   :: else -> break
od;


ch ?? eval(f0),f1;   /* message selected by the receive */


}


inline dT(l) {
if :: gbchan ?? [eval(_pid),_,l,0] ->
gbchan ?? eval(_pid),_,l,0
:: else fi }


/*###############################################*/


#define sP(a,b)    set_priority(a,b)


/*###############################################*/


chan gbchan = [255] of {byte, byte, byte, bit};


/*###############################################*/


/*#####TRANSITION VERTICAL LABELS#######*/

#define TAKE_ORDER 1
#define DELIVER 2
#define BERECHARGED 3
#define BACK 4
#define R_BACK 5


/*#####TRANSITION HORIZONTAL LABELS#######*/

#define RECHARGE 254


/*#########SHARED PLACES##############*/
ltl s{ <> ((ORDERS==0))}
byte ORDERS =  5
NetPlace ENTRANCE;
NetPlace SENT;
NetPlace MAINTENANCE;
NetPlace WAITING;
byte READY = 0;
init {

byte nt;
   atomic{
       printf("SN setting initial marking\n\n");
       nt = run D(ENTRANCE.d);
       ENTRANCE.d ! nt,255,0,0;
       nt = run D(ENTRANCE.d);
       ENTRANCE.d ! nt,255,0,0;
       nt = run A(ENTRANCE.d);
       ENTRANCE.d ! nt,255,0,0;
       nt = run R(WAITING.d);
       WAITING.d ! nt,255,0,0;
       byte it;
   }

   do
   :: atomic{
       nempty(ENTRANCE.d) && READY > 0 && gbchan ?? [_,TAKE_ORDER,_,0]  ->
       sP(_pid, 3);
       READY = READY - 1;
       rmConf(BERECHARGED, gbchan)
       invertMsg(nt, TAKE_ORDER, gbchan);
       sP(nt, 10);
       transpNetTok(ENTRANCE.d, SENT.d, nt);
       printf("Firing transition T1");
       sP(_pid, 1);
   }
   :: atomic{
       nempty(SENT.d) && gbchan ?? [_,DELIVER,_,0]  ->
       sP(_pid, 3);
       invertMsg(nt, DELIVER, gbchan);
       sP(nt, 10);
       transpNetTok(SENT.d, ENTRANCE.d, nt);
       printf("Firing transition T2");
       sP(_pid, 1);
   }
   :: atomic{
       nempty(ENTRANCE.d) && nempty(WAITING.d) && gbchan ?? [_,BERECHARGED,_,0] && gbchan ?? [_,BERECHARGED,_,0]  ->
       sP(_pid, 3);
       rmConf(TAKE_ORDER, gbchan)
       invertMsg(nt, BERECHARGED, gbchan);
       sP(nt, 2);
       transpNetTok(ENTRANCE.d, MAINTENANCE.d, nt);
       transpNetTok(WAITING.d, MAINTENANCE.d, nt);
       printf("Firing transition T3");
       sP(_pid, 1);
   }
   :: atomic{
       nempty(MAINTENANCE.d) && gbchan ?? [_,BACK,_,0]  ->
       sP(_pid, 2);
       invertMsg(nt, BACK, gbchan);
       sP(nt, 3);
       transpNetTok(MAINTENANCE.d, ENTRANCE.d, nt);
       printf("Firing transition T4");
       sP(_pid, 1);
   }
   :: atomic{
       nempty(MAINTENANCE.d) && gbchan ?? [_,R_BACK,_,0]  ->
       sP(_pid, 3);
       invertMsg(nt, R_BACK, gbchan);
       sP(nt, 3);
       transpNetTok(MAINTENANCE.d, WAITING.d, nt);
       printf("Firing transition T5");
       sP(_pid, 1);
   }
   :: atomic{
       ORDERS > 0  ->
       sP(_pid, 3);
       ORDERS = ORDERS - 1;
       READY = READY + 1;
       printf("Firing transition T0");
       sP(_pid, 1);
   }
   od}
proctype D (chan pc){
   byte nt;
   byte v0;
   byte TRAVELING = 0;
   byte WASTE = 0;
   byte RETURNING = 0;
   byte RESTING = 3;
   byte BROKE = 0;
   byte D_READY = 0;
   byte it;
   atomic{
       printf("D setting initial marking\n\n");
   }
   do::{
    do
       :: d_step{
           RESTING >= 1 && ! gbchan ?? [eval(_pid),TAKE_ORDER,_,0]  ->
           gbchan ! _pid,TAKE_ORDER,1,0
           printf("Firing transition TD0");
       }
       :: d_step{
           TRAVELING >= 1 && ! gbchan ?? [eval(_pid),DELIVER,_,0]  ->
           gbchan ! _pid,DELIVER,2,0
           printf("Firing transition TD1");
       }
       :: d_step{
           RETURNING >= 1  ->
           sP(_pid, 3);
           RETURNING = RETURNING - 1;
           WASTE = WASTE + 1;
           printf("Firing transition TD2");
       }
       :: d_step{
           WASTE >= 3 && ! gbchan ?? [eval(_pid),BERECHARGED,_,0]  ->
           gbchan ! _pid,BERECHARGED,4,0
           printf("Firing transition TD3");
       }
       :: d_step{
           BROKE >= 1 && ! gbchan??[eval(_pid),RECHARGE,_,0] && gbchan??[_,RECHARGE,_,0]  ->
           sP(_pid, 3);
           invertMsg(nt, RECHARGE, gbchan);
           sP(nt, 3);
           gbchan ! _pid,RECHARGE,5,0;
           gbchan ! _pid,RECHARGE,5,1;
           printf("Firing transition TD4");
       }
       :: d_step{
           BROKE >= 1 && ! gbchan??[_,RECHARGE,_,0]  ->
           sP(_pid, 3);
            gbchan!_pid,RECHARGE,5,0;
           printf("Firing transition TD4");
       }
       :: d_step{
           D_READY >= 1 && ! gbchan ?? [eval(_pid),BACK,_,0]  ->
           gbchan ! _pid,BACK,6,0
           printf("Firing transition TD5");
       }
       od}
       unless atomic{
       gbchan ?? eval(_pid),v0,it,1 ->
       if
       :: it == 0 && v0 == 255 -> break;
  :: it == 1 ->
           RESTING = RESTING - 1;
           TRAVELING = TRAVELING + 1;
           printf("Firing outer loop transition TD0");
  :: it == 2 ->
           TRAVELING = TRAVELING - 1;
           RETURNING = RETURNING + 1;
           printf("Firing outer loop transition TD1");
  :: it == 4 ->
           WASTE = WASTE - 3;
           BROKE = BROKE + 1;
           printf("Firing outer loop transition TD3");
  :: it == 5 ->
           BROKE = BROKE - 1;
           D_READY = D_READY + 1;
           dT(it);
           printf("Firing outer loop transition TD4");
  :: it == 6 ->
           D_READY = D_READY - 1;
           RESTING = RESTING + 3;
           printf("Firing outer loop transition TD5");
         fi; sP(_pid, 1);   }
   od; sP(_pid, 1);  }

proctype R (chan pc){
   byte nt;
   byte v0;
   byte R_WAITING = 1;
   byte WORKING = 0;
   byte it;
   atomic{
       printf("R setting initial marking\n\n");
   }
   do::{
    do
       :: d_step{
           R_WAITING >= 1 && ! gbchan??[eval(_pid),RECHARGE,_,0] && gbchan??[_,RECHARGE,_,0]  ->
           sP(_pid, 3);
           invertMsg(nt, RECHARGE, gbchan);
           sP(nt, 3);
           gbchan ! _pid,RECHARGE,1,0;
           gbchan ! _pid,RECHARGE,1,1;
           printf("Firing transition TR0");
       }
       :: d_step{
           R_WAITING >= 1 && ! gbchan??[_,RECHARGE,_,0]  ->
           sP(_pid, 3);
            gbchan!_pid,RECHARGE,1,0;
           printf("Firing transition TR0");
       }
       :: d_step{
           WORKING >= 1 && ! gbchan ?? [eval(_pid),R_BACK,_,0]  ->
           gbchan ! _pid,R_BACK,2,0
           printf("Firing transition TR1");
       }
       od}
       unless atomic{
       gbchan ?? eval(_pid),v0,it,1 ->
       if
       :: it == 0 && v0 == 255 -> break;
  :: it == 1 ->
           R_WAITING = R_WAITING - 1;
           WORKING = WORKING + 1;
           dT(it);
           printf("Firing outer loop transition TR0");
  :: it == 2 ->
           WORKING = WORKING - 1;
           R_WAITING = R_WAITING + 1;
           printf("Firing outer loop transition TR1");
         fi; sP(_pid, 1);   }
   od; sP(_pid, 1);  }

proctype A (chan pc){
   byte nt;
   byte v0;
   byte OPEN = 1;
   byte WASTE = 0;
   byte BROKE = 0;
   byte A_READY = 0;
   byte it;
   atomic{
       printf("A setting initial marking\n\n");
   }
   do::{
    do
       :: d_step{
           OPEN >= 1  ->
           sP(_pid, 3);
           OPEN = OPEN - 1;
           ORDERS = ORDERS + 1;
           WASTE = WASTE + 1;
           printf("Firing transition TA0");
       }
       :: d_step{
           WASTE >= 5 && ! gbchan ?? [eval(_pid),BERECHARGED,_,0]  ->
           gbchan ! _pid,BERECHARGED,2,0
           printf("Firing transition TA1");
       }
       :: d_step{
           BROKE >= 1 && ! gbchan??[eval(_pid),RECHARGE,_,0] && gbchan??[_,RECHARGE,_,0]  ->

           invertMsg(nt, RECHARGE, gbchan);
           sP(nt, 3);
           gbchan ! _pid,RECHARGE,3,0;
           gbchan ! _pid,RECHARGE,3,1;
           printf("Firing transition TA2");
       }
       :: d_step{
           BROKE >= 1 && ! gbchan??[_,RECHARGE,_,0]  ->
           sP(_pid, 3);
            gbchan!_pid,RECHARGE,3,0;
           printf("Firing transition TA2");
       }
       :: d_step{
           A_READY >= 1 && ! gbchan ?? [eval(_pid),BACK,_,0]  ->
           gbchan ! _pid,BACK,4,0
           printf("Firing transition TA3");
       }
       od}
       unless atomic{
       gbchan ?? eval(_pid),v0,it,1 ->
       if
       :: it == 0 && v0 == 255 -> break;
  :: it == 2 ->
           WASTE = WASTE - 5;
           BROKE = BROKE + 1;
           printf("Firing outer loop transition TA1");
  :: it == 3 ->
           BROKE = BROKE - 1;
           A_READY = A_READY + 1;
           dT(it);
           printf("Firing outer loop transition TA2");
  :: it == 4 ->
           A_READY = A_READY - 1;
           OPEN = OPEN + 5;
           printf("Firing outer loop transition TA3");
         fi; sP(_pid, 1);   }
   od; sP(_pid, 1);  }

