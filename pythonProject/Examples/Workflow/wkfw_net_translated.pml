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

#define Lambda 1


/*#####TRANSITION HORIZONTAL LABELS#######*/

#define L2 254
#define L6 253
#define L5 252
#define L4 251
#define L8 250
#define L7 249
#define L1 248
#define L3 247


/*#########SHARED PLACES##############*/
ltl s { <>(p4>0)}
NetPlace p2;
byte p1 = 1;
byte p3 = 0;
byte p4 = 0;
init {

byte nt;
   atomic{
       printf("SN setting initial marking\n\n");
       byte it;
   }

   end: do
   :: atomic{
       p1 > 0  ->
       sP(_pid, 3);
       p1 = p1 - 1;
       nt = run LWF2(p2.d);
       p2.d ! nt,255,0,0;
       nt = run AC(p2.d);
       p2.d ! nt,255,0,0;
       nt = run LWF1(p2.d);
       p2.d ! nt,255,0,0;
       printf("Firing transition T1");
       sP(_pid, 1);
   }
   :: atomic{
       nempty(p2.d) && gbchan ?? [_,Lambda,_,0]  ->
       sP(_pid, 3);
       invertMsg(nt, Lambda, gbchan);
       sP(nt, 3);
       p2.d ?? nt,255,_,0;
       sP(nt, 3);
       consNetTok(p2.d,nt);
       p3 = p3 + 1;
       printf("Firing transition T2");
       sP(_pid, 1);
   }
   :: atomic{
       nempty(p2.d) && p3 >= 2  ->
       sP(_pid, 3);
       p3 = p3 - 2;
       p2.d ?? nt,255,_,0;
       sP(nt, 3);
       consNetTok(p2.d,nt);
       rmConf(Lambda, gbchan)
       p4 = p4 + 1;
       printf("Firing transition T3");
       sP(_pid, 1);
   }
   od}
proctype AC (chan pc){
   byte nt;
   byte v0;
   byte ACP1 = 0;
   byte ACP2 = 0;
   byte ACP3 = 0;
   byte it;
   atomic{
       printf("AC setting initial marking\n\n");
   }
   end: do::{
   end1: do
       :: d_step{
           ACP1 > 0 && ! gbchan??[eval(_pid),L2,_,0] && gbchan??[_,L2,_,0]  ->
           sP(_pid, 3);
           invertMsg(nt, L2, gbchan);
           sP(nt, 3);
           gbchan ! _pid,L2,1,0;
           gbchan ! _pid,L2,1,1;
           printf("Firing transition ACT2");
       }
       :: d_step{
           ACP1 > 0 && ! gbchan??[_,L2,_,0]  ->
           sP(_pid, 3);
            gbchan!_pid,L2,1,0;
           printf("Firing transition ACT2");
       }
       :: d_step{
           ACP2 > 0 && ! gbchan??[eval(_pid),L6,_,0] && gbchan??[_,L6,_,0]  ->
           sP(_pid, 3);
           invertMsg(nt, L6, gbchan);
           sP(nt, 3);
           rmConf(L5, gbchan)
           gbchan ! _pid,L6,2,0;
           gbchan ! _pid,L6,2,1;
           printf("Firing transition ACT5");
       }
       :: d_step{
           ACP2 > 0 && ! gbchan??[_,L6,_,0]  ->
           sP(_pid, 3);
            gbchan!_pid,L6,2,0;
           printf("Firing transition ACT5");
       }
       :: d_step{
           ACP2 > 0 && ! gbchan??[eval(_pid),L5,_,0] && gbchan??[_,L5,_,0]  ->
           sP(_pid, 3);
           invertMsg(nt, L5, gbchan);
           sP(nt, 3);
           rmConf(L6, gbchan)
           gbchan ! _pid,L5,3,0;
           gbchan ! _pid,L5,3,1;
           printf("Firing transition ACT4");
       }
       :: d_step{
           ACP2 > 0 && ! gbchan??[_,L5,_,0]  ->
           sP(_pid, 3);
            gbchan!_pid,L5,3,0;
           printf("Firing transition ACT4");
       }
       :: d_step{
           ! gbchan??[eval(_pid),L4,_,0] && gbchan??[_,L4,_,0]  ->
           sP(_pid, 3);
           invertMsg(nt, L4, gbchan);
           sP(nt, 3);
           gbchan ! _pid,L4,4,0;
           gbchan ! _pid,L4,4,1;
           printf("Firing transition ACT3");
       }
       :: d_step{
           ! gbchan??[_,L4,_,0]  ->
           sP(_pid, 3);
            gbchan!_pid,L4,4,0;
           printf("Firing transition ACT3");
       }
       :: d_step{
           ACP3 > 0 && ! gbchan??[eval(_pid),L8,_,0] && gbchan??[_,L8,_,0]  ->
           sP(_pid, 3);
           invertMsg(nt, L8, gbchan);
           sP(nt, 3);
           gbchan ! _pid,L8,5,0;
           gbchan ! _pid,L8,5,1;
           printf("Firing transition ACT7");
       }
       :: d_step{
           ACP3 > 0 && ! gbchan??[_,L8,_,0]  ->
           sP(_pid, 3);
            gbchan!_pid,L8,5,0;
           printf("Firing transition ACT7");
       }
       :: d_step{
           ! gbchan??[eval(_pid),L7,_,0] && gbchan??[_,L7,_,0]  ->
           sP(_pid, 3);
           invertMsg(nt, L7, gbchan);
           sP(nt, 3);
           gbchan ! _pid,L7,6,0;
           gbchan ! _pid,L7,6,1;
           printf("Firing transition ACT6");
       }
       :: d_step{
           ! gbchan??[_,L7,_,0]  ->
           sP(_pid, 3);
            gbchan!_pid,L7,6,0;
           printf("Firing transition ACT6");
       }
       :: d_step{
           ! gbchan??[eval(_pid),L1,_,0] && gbchan??[_,L1,_,0]  ->
           sP(_pid, 3);
           invertMsg(nt, L1, gbchan);
           sP(nt, 3);
           gbchan ! _pid,L1,7,0;
           gbchan ! _pid,L1,7,1;
           printf("Firing transition ACT1");
       }
       :: d_step{
           ! gbchan??[_,L1,_,0]  ->
           sP(_pid, 3);
            gbchan!_pid,L1,7,0;
           printf("Firing transition ACT1");
       }
       od}
       unless atomic{
       gbchan ?? eval(_pid),v0,it,1 ->
       if
       :: it == 0 && v0 == 255 -> break;
  :: it == 1 ->
           ACP1 = ACP1 - 1;
           dT(it);
           printf("Firing outer loop transition ACT2");
  :: it == 2 ->
           ACP2 = ACP2 - 1;
           dT(it);
           printf("Firing outer loop transition ACT5");
  :: it == 3 ->
           ACP2 = ACP2 - 1;
           dT(it);
           printf("Firing outer loop transition ACT4");
  :: it == 4 ->
           ACP2 = ACP2 + 1;
           dT(it);
           printf("Firing outer loop transition ACT3");
  :: it == 5 ->
           ACP3 = ACP3 - 1;
           dT(it);
           printf("Firing outer loop transition ACT7");
  :: it == 6 ->
           ACP3 = ACP3 + 1;
           dT(it);
           printf("Firing outer loop transition ACT6");
  :: it == 7 ->
           ACP1 = ACP1 + 1;
           dT(it);
           printf("Firing outer loop transition ACT1");
         fi; sP(_pid, 1);   }
   od; sP(_pid, 1);  }

proctype LWF1 (chan pc){
   byte nt;
   byte v0;
   byte F1P1 = 1;
   byte F1P2 = 0;
   byte F1P3 = 0;
   byte F1P4 = 0;
   byte F1P5 = 0;
   byte it;
   atomic{
       printf("LWF1 setting initial marking\n\n");
   }
   end: do::{
   end1: do
       :: d_step{
           F1P1 > 0 && ! gbchan??[eval(_pid),L2,_,0] && gbchan??[_,L2,_,0]  ->
           sP(_pid, 3);
           invertMsg(nt, L2, gbchan);
           sP(nt, 3);
           gbchan ! _pid,L2,1,0;
           gbchan ! _pid,L2,1,1;
           printf("Firing transition F1T1");
       }
       :: d_step{
           F1P1 > 0 && ! gbchan??[_,L2,_,0]  ->
           sP(_pid, 3);
            gbchan!_pid,L2,1,0;
           printf("Firing transition F1T1");
       }
       :: d_step{
           F1P3 > 0 && ! gbchan??[eval(_pid),L6,_,0] && gbchan??[_,L6,_,0]  ->
           sP(_pid, 3);
           invertMsg(nt, L6, gbchan);
           sP(nt, 3);
           rmConf(L5, gbchan)
           gbchan ! _pid,L6,2,0;
           gbchan ! _pid,L6,2,1;
           printf("Firing transition F1T5");
       }
       :: d_step{
           F1P3 > 0 && ! gbchan??[_,L6,_,0]  ->
           sP(_pid, 3);
            gbchan!_pid,L6,2,0;
           printf("Firing transition F1T5");
       }
       :: d_step{
           F1P3 > 0 && ! gbchan??[eval(_pid),L5,_,0] && gbchan??[_,L5,_,0]  ->
           sP(_pid, 3);
           invertMsg(nt, L5, gbchan);
           sP(nt, 3);
           rmConf(L6, gbchan)
           gbchan ! _pid,L5,3,0;
           gbchan ! _pid,L5,3,1;
           printf("Firing transition F1T4");
       }
       :: d_step{
           F1P3 > 0 && ! gbchan??[_,L5,_,0]  ->
           sP(_pid, 3);
            gbchan!_pid,L5,3,0;
           printf("Firing transition F1T4");
       }
       :: d_step{
           F1P2 > 0 && ! gbchan??[eval(_pid),L3,_,0] && gbchan??[_,L3,_,0]  ->
           sP(_pid, 3);
           invertMsg(nt, L3, gbchan);
           sP(nt, 3);
           gbchan ! _pid,L3,4,0;
           gbchan ! _pid,L3,4,1;
           printf("Firing transition F1T3");
       }
       :: d_step{
           F1P2 > 0 && ! gbchan??[_,L3,_,0]  ->
           sP(_pid, 3);
            gbchan!_pid,L3,4,0;
           printf("Firing transition F1T3");
       }
       :: d_step{
           F1P2 > 0  ->
           sP(_pid, 3);
           F1P2 = F1P2 - 1;
           rmConf(L3, gbchan)
           F1P3 = F1P3 + 1;
           printf("Firing transition F1T2");
       }
       :: d_step{
           F1P5 > 0 && ! gbchan ?? [eval(_pid),Lambda,_,0]  ->
           gbchan ! _pid,Lambda,6,0
           printf("Firing transition F1T7");
       }
       :: d_step{
           F1P4 > 0 && ! gbchan??[eval(_pid),L7,_,0] && gbchan??[_,L7,_,0]  ->
           sP(_pid, 3);
           invertMsg(nt, L7, gbchan);
           sP(nt, 3);
           gbchan ! _pid,L7,7,0;
           gbchan ! _pid,L7,7,1;
           printf("Firing transition F1T6");
       }
       :: d_step{
           F1P4 > 0 && ! gbchan??[_,L7,_,0]  ->
           sP(_pid, 3);
            gbchan!_pid,L7,7,0;
           printf("Firing transition F1T6");
       }
       od}
       unless atomic{
       gbchan ?? eval(_pid),v0,it,1 ->
       if
       :: it == 0 && v0 == 255 -> break;
  :: it == 1 ->
           F1P1 = F1P1 - 1;
           F1P2 = F1P2 + 1;
           dT(it);
           printf("Firing outer loop transition F1T1");
  :: it == 2 ->
           F1P3 = F1P3 - 1;
           F1P4 = F1P4 + 1;
           dT(it);
           printf("Firing outer loop transition F1T5");
  :: it == 3 ->
           F1P3 = F1P3 - 1;
           F1P4 = F1P4 + 1;
           dT(it);
           printf("Firing outer loop transition F1T4");
  :: it == 4 ->
           F1P2 = F1P2 - 1;
           F1P3 = F1P3 + 1;
           dT(it);
           printf("Firing outer loop transition F1T3");
  :: it == 6 ->
           F1P5 = F1P5 - 1;
           printf("Firing outer loop transition F1T7");
  :: it == 7 ->
           F1P4 = F1P4 - 1;
           F1P5 = F1P5 + 1;
           dT(it);
           printf("Firing outer loop transition F1T6");
         fi; sP(_pid, 1);   }
   od; sP(_pid, 1);  }

proctype LWF2 (chan pc){
   byte nt;
   byte v0;
   byte F2P1 = 1;
   byte F2P2 = 0;
   byte F2P3 = 0;
   byte F2P4 = 0;
   byte F2P5 = 0;
   byte it;
   atomic{
       printf("LWF2 setting initial marking\n\n");
   }
   end: do::{
   end1: do
       :: d_step{
           F2P1 > 0 && ! gbchan??[eval(_pid),L1,_,0] && gbchan??[_,L1,_,0]  ->
           sP(_pid, 3);
           invertMsg(nt, L1, gbchan);
           sP(nt, 3);
           gbchan ! _pid,L1,1,0;
           gbchan ! _pid,L1,1,1;
           printf("Firing transition F2T1");
       }
       :: d_step{
           F2P1 > 0 && ! gbchan??[_,L1,_,0]  ->
           sP(_pid, 3);
            gbchan!_pid,L1,1,0;
           printf("Firing transition F2T1");
       }
       :: d_step{
           F2P3 > 0 && ! gbchan??[eval(_pid),L4,_,0] && gbchan??[_,L4,_,0]  ->
           sP(_pid, 3);
           invertMsg(nt, L4, gbchan);
           sP(nt, 3);
           gbchan ! _pid,L4,2,0;
           gbchan ! _pid,L4,2,1;
           printf("Firing transition F2T4");
       }
       :: d_step{
           F2P3 > 0 && ! gbchan??[_,L4,_,0]  ->
           sP(_pid, 3);
            gbchan!_pid,L4,2,0;
           printf("Firing transition F2T4");
       }
       :: d_step{
           F2P2 > 0 && ! gbchan??[eval(_pid),L3,_,0] && gbchan??[_,L3,_,0]  ->
           sP(_pid, 3);
           invertMsg(nt, L3, gbchan);
           sP(nt, 3);
           gbchan ! _pid,L3,3,0;
           gbchan ! _pid,L3,3,1;
           printf("Firing transition F2T3");
       }
       :: d_step{
           F2P2 > 0 && ! gbchan??[_,L3,_,0]  ->
           sP(_pid, 3);
            gbchan!_pid,L3,3,0;
           printf("Firing transition F2T3");
       }
       :: d_step{
           F2P2 > 0  ->
           sP(_pid, 3);
           F2P2 = F2P2 - 1;
           rmConf(L3, gbchan)
           F2P3 = F2P3 + 1;
           printf("Firing transition F2T2");
       }
       :: d_step{
           F2P5 > 0 && ! gbchan ?? [eval(_pid),Lambda,_,0]  ->
           gbchan ! _pid,Lambda,5,0
           printf("Firing transition F2T6");
       }
       :: d_step{
           F2P4 > 0 && ! gbchan??[eval(_pid),L8,_,0] && gbchan??[_,L8,_,0]  ->
           sP(_pid, 3);
           invertMsg(nt, L8, gbchan);
           sP(nt, 3);
           gbchan ! _pid,L8,6,0;
           gbchan ! _pid,L8,6,1;
           printf("Firing transition F2T5");
       }
       :: d_step{
           F2P4 > 0 && ! gbchan??[_,L8,_,0]  ->
           sP(_pid, 3);
            gbchan!_pid,L8,6,0;
           printf("Firing transition F2T5");
       }
       od}
       unless atomic{
       gbchan ?? eval(_pid),v0,it,1 ->
       if
       :: it == 0 && v0 == 255 -> break;
  :: it == 1 ->
           F2P1 = F2P1 - 1;
           F2P2 = F2P2 + 1;
           dT(it);
           printf("Firing outer loop transition F2T1");
  :: it == 2 ->
           F2P3 = F2P3 - 1;
           F2P4 = F2P4 + 1;
           dT(it);
           printf("Firing outer loop transition F2T4");
  :: it == 3 ->
           F2P2 = F2P2 - 1;
           F2P3 = F2P3 + 1;
           dT(it);
           printf("Firing outer loop transition F2T3");
  :: it == 5 ->
           F2P5 = F2P5 - 1;
           printf("Firing outer loop transition F2T6");
  :: it == 6 ->
           F2P4 = F2P4 - 1;
           F2P5 = F2P5 + 1;
           dT(it);
           printf("Firing outer loop transition F2T5");
         fi; sP(_pid, 1);   }
   od; sP(_pid, 1);  }

