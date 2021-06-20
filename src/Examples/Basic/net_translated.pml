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

#define Theta 254


/*#########SHARED PLACES##############*/

NetPlace PSN2;
byte PSN1 = 1;
byte PSN3 = 0;
init {

byte nt;
   atomic{
       printf("SN setting initial marking\n\n");
       byte it;
   }

   end: do
   :: atomic{
       PSN1 > 0  ->
       sP(_pid, 3);
       PSN1 = PSN1 - 1;
       nt = run B(PSN2.d);
       PSN2.d ! nt,255,0,0;
       nt = run A(PSN2.d);
       PSN2.d ! nt,255,0,0;
       printf("Firing transition TSN1");
       sP(_pid, 1);
   }
   :: atomic{
       nempty(PSN2.d) && gbchan ?? [_,Lambda,_,0]  ->
       sP(_pid, 3);
       invertMsg(nt, Lambda, gbchan);
       sP(nt, 3);
       PSN2.d ?? nt,255,_,0;
       sP(nt, 3);
       consNetTok(PSN2.d,nt);
       PSN3 = PSN3 + 1;
       printf("Firing transition TSN2");
       sP(_pid, 1);
   }
   od}
proctype A (chan pc){
   byte nt;
   byte v0;
   byte PA2 = 0;
   byte PA1 = 1;
   byte PA3 = 0;
   byte it;
   atomic{
       printf("A setting initial marking\n\n");
   }
   end: do::{
   end1: do
       :: d_step{
           PA1 > 0 && ! gbchan??[eval(_pid),Theta,_,0] && gbchan??[_,Theta,_,0]  ->
           sP(_pid, 3);
           invertMsg(nt, Theta, gbchan);
           sP(nt, 3);
           gbchan ! _pid,Theta,1,0;
           gbchan ! _pid,Theta,1,1;
           printf("Firing transition TA1");
       }
       :: d_step{
           PA1 > 0 && ! gbchan??[_,Theta,_,0]  ->
           sP(_pid, 3);
            gbchan!_pid,Theta,1,0;
           printf("Firing transition TA1");
       }
       :: d_step{
           PA2 > 0 && ! gbchan ?? [eval(_pid),Lambda,_,0]  ->
           gbchan ! _pid,Lambda,2,0
           printf("Firing transition TA2");
       }
       od}
       unless atomic{
       gbchan ?? eval(_pid),v0,it,1 -> 
       if
       :: it == 0 && v0 == 255 -> break;
  :: it == 1 ->
           PA1 = PA1 - 1;
           PA2 = PA2 + 1;
           dT(it);
           printf("Firing outer loop transition TA1");
  :: it == 2 ->
           PA2 = PA2 - 1;
           PA3 = PA3 + 1;
           printf("Firing outer loop transition TA2");
         fi; sP(_pid, 1);   }
   od; sP(_pid, 1);  }

proctype B (chan pc){
   byte nt;
   byte v0;
   byte PB2 = 0;
   byte PB1 = 1;
   byte it;
   atomic{
       printf("B setting initial marking\n\n");
   }
   end: do::{
   end1: do
       :: d_step{
           PB1 > 0 && ! gbchan??[eval(_pid),Theta,_,0] && gbchan??[_,Theta,_,0]  ->
           sP(_pid, 3);
           invertMsg(nt, Theta, gbchan);
           sP(nt, 3);
           gbchan ! _pid,Theta,1,0;
           gbchan ! _pid,Theta,1,1;
           printf("Firing transition TB1");
       }
       :: d_step{
           PB1 > 0 && ! gbchan??[_,Theta,_,0]  ->
           sP(_pid, 3);
            gbchan!_pid,Theta,1,0;
           printf("Firing transition TB1");
       }
       od}
       unless atomic{
       gbchan ?? eval(_pid),v0,it,1 -> 
       if
       :: it == 0 && v0 == 255 -> break;
  :: it == 1 ->
           PB1 = PB1 - 1;
           PB2 = PB2 + 1;
           dT(it);
           printf("Firing outer loop transition TB1");
         fi; sP(_pid, 1);   }
   od; sP(_pid, 1);  }

