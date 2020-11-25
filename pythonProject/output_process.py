from tranlator import create_initial_marking
from constants import *

PROMELA_PRE_FUNCTIONS = [
    "typedef NetPlace { chan d = [255] of {byte, byte, byte, bit}}\n",
    "\n\n",
    "/*###############################################*/\n",
    "\n\n",
    "chan cha =[18] of {byte,byte}; hidden byte j, size_cha;\n",
    "\n\n",
    "\n\n",
    "byte v0,v1,v2,v3;\n",
    "\n\n",
    "/*###############################################*/\n",
    "\n\n",
    "inline consNetTok(c, p) {\n",
    "  do:: c ?? [eval(p),_,_,0] -> c ?? eval(p),_,_,0\n",
    "    :: else -> break\n",
    "  od; skip }\n",
    "\n\n",
    "inline rmConf(l, pc){\n",
    "  if :: pc ?? [eval(_pid),l,_,_] -> pc ?? eval(_pid),l,_,_\n",
    "     :: else fi\n",
    "}\n",
    "\n\n",
    "/*###############################################*/\n",
    "\n\n",
    "inline transpNetTok(ch, och, p){\n",
    "  do:: ch ?? [eval(p),_,_,_] ->\n",
    "       ch ?? eval(p),v1,v2,v3;\n",
    "       och ! p,v1,v2,v3;\n",
    "    :: else -> break\n",
    "  od; skip }\n",
    "\n\n",
    "/*###############################################*/\n",
    "hidden byte i;\n",
    "hidden unsigned nt:4,lt:4, nt1:4, lt1:4;\n",
    "\n\n",
    "inline recMsg(ch,f0,f1) {             /* ch - ordered \"channel, f0 - output variable, f1 - constant value */\n",
    "ch ! 0,f1;\n",
    "do :: ch ?? f0,f1;\n",
    "       if :: f0>0 ->   ch !  f0,f1; \n",
    "                       cha ! len(cha)+1,f0;\n",
    "          :: else -> break\n",
    "       fi\n",
    "od;\n",
    "\n\n",
    " /* select ( j : 1 .. size_cha); */\n",
    "\n\n",
    "    size_cha= len(cha);\n",
    "   j = 1;\n",
    "   do\n",
    "   :: j < size_cha -> j++\n",
    "   :: break\n",
    "   od\n",
    "\n\n",
    "cha ?? <eval(j),f0>;\n",
    "\n\n",
    " /* restoring the ordering of the input channel */\n",
    "  \n",
    "do :: len(cha)>0 -> \n",
    "   cha?_,nt1;\n",
    "   ch ?? eval(nt1),eval(f1);\n",
    "   ch !! nt1,f1;\n",
    "   :: else -> break\n",
    "od; \n",
    "\n\n",
    "ch ?? eval(f0),f1;   /* message selected by the receive */\n",
    "\n\n",
    "}\n",
    "\n\n",
    "/*###############################################*/\n",
    "\n\n",
    "#define sP(a,b)    set_priority(a,b)\n",
    "\n\n",
    "/*###############################################*/\n",
    "\n\n",
    "chan gbchan = [255] of {byte, byte, byte, bit};\n",
    "\n\n",
    "/*###############################################*/ \n"]

def generate_promela_code(
        system_net_name, places, transitions, arcs, nets, uplink, downlink, horizontal,
        vlabels, hlabels, shared_places, arc_variables, only_places_dict, only_arcs_dict,
        channel_places, enable_tests, consume, produce):
    f = open(OUTPUT_FILENAME, "w")
    for line in PROMELA_PRE_FUNCTIONS:
        f.write(line)
    f.write("\n\n/*#####TRANSITION VERTICAL LABELS#######*/\n\n")
    for label in vlabels.keys():
        line = "#define " + label + " " + str(vlabels[label]) + "\n"
        f.write(line)
    f.write("\n\n/*#####TRANSITION HORIZONTAL LABELS#######*/\n\n")
    for label in hlabels.keys():
        line = "#define " + label + " " + str(hlabels[label]) + "\n"
        f.write(line)
    f.write("\n\n/*#########SHARED PLACES##############*/\n\n")
    for shared_place in shared_places:
        line = "byte {0} =  {1}\n".format(shared_place[0], str(shared_place[1]))
        f.write(line)
    for net in nets.keys():
        initial_marking = create_initial_marking(places[net], channel_places, nets.keys(), [x[0] for x in shared_places])

        if net == system_net_name:
            for mark in initial_marking:
                if "NetPlace" in mark or "byte" in mark and "it" not in mark:
                    f.write(mark)
            f.write("init {\n\n")
            f.write("   atomic{\n")
            f.write("       printf(\"SN setting initial marking\\n\\n\");\n")
            for mark in initial_marking:
                if "run" in mark or "! nt,255,0,0" in mark or "it" in mark:
                    f.write("       ")
                    f.write(mark)
            f.write("   }\n\n")
            f.write("   do\n")
            for transition in transitions[net].keys():
                f.write("   :: atomic{\n")
                enable = ""
                for condition in enable_tests[transition]['general_condition']:
                    enable = enable + condition + " && "
                for condition in enable_tests[transition]['uplink_specific_conditions']:
                    enable = enable + condition + " && "
                for condition in enable_tests[transition]['downlink_specific_conditions']:
                    enable = enable + condition + " && "
                for condition in enable_tests[transition]['horizontal_specific_conditions_b']:
                    enable = enable + condition + " && "
                enable = enable[:-3]
                f.write("       {} ->\n".format(enable))
                f.write("       sP(_pid, 3);\n")
                for c in consume[transition]['general']:
                    f.write("       {}".format(c))
                for c in consume[transition]['consume']:
                    f.write("       {}".format(c))
                for p in produce[transition]['transport']:
                    f.write("       {}".format(p))
                for p in produce[transition]['general']:
                    if "pc" not in p: #system net não pode ter referencia a pc
                        f.write("       {}".format(p))
                for p in produce[transition]['run']:
                    f.write("       {}".format(p))
                f.write("       printf(\"Firing transition {0}\");\n".format(transitions[net][transition]['name'][0]))
                f.write("       sP(_pid, 1);\n")
                f.write("   }\n")
            f.write("   od}\n")
        else:
            net_name = net
            f.write("proctype {} (chan pc)".format(net_name))
            f.write("{\n")
            for mark in initial_marking:
                if "run" not in mark:
                    f.write("   {}".format(mark))
            f.write("   atomic{\n")
            f.write("       printf(\"{} setting initial marking\\n\\n\");\n".format(net))
            for mark in initial_marking:
                if "run" in mark:
                    f.write("       ")
                    f.write(mark)
            f.write("   }\n")
            f.write("   do::{\n")
            f.write("   do\n")
            for transition in transitions[net].keys():
                f.write("       :: d_step{\n")
                enable = ""
                for condition in enable_tests[transition]['general_condition']:
                    enable = enable + condition + " && "
                for condition in enable_tests[transition]['uplink_specific_conditions']:
                    enable = enable + condition + " && "
                for condition in enable_tests[transition]['downlink_specific_conditions']:
                    enable = enable + condition + " && "
                for condition in enable_tests[transition]['horizontal_specific_conditions_b']:
                    enable = enable + condition + " && "
                enable = enable[:-3]
                f.write("           {} ->\n".format(enable))
                if(enable_tests[transition]['uplink_specific_conditions']):
                    sentence = "gbchan ! _pid,{0},{1},0\n".format(transitions[net][transition]['uplink_label'][0],transitions[net][transition]['promela_id'])
                    f.write("           {}".format(sentence))
                    f.write("           printf(\"Firing transition {0}\");\n".format(transitions[net][transition]['name'][0]))
                    f.write("       }\n")
                else:
                    f.write("           sP(_pid, 3);\n")
                    for c in consume[transition]['general']:
                        f.write("           {}".format(c))
                    for c in consume[transition]['consume']:
                        f.write("           {}".format(c))
                    for p in produce[transition]['transport']:
                        f.write("           {}".format(p))
                    for p in produce[transition]['general']:
                        f.write("           {}".format(p))
                    f.write("           printf(\"Firing transition {0}\");\n".format(transitions[net][transition]['name'][0]))
                    f.write("           sP(_pid, 1);\n")
                    f.write("       }\n")
                if enable_tests[transition]['horizontal_specific_conditions_a']:
                    f.write("       :: d_step{\n")
                    enable = ""
                    for condition in enable_tests[transition]['general_condition']:
                        enable = enable + condition + " && "
                    for condition in enable_tests[transition]['uplink_specific_conditions']:
                        enable = enable + condition + " && "
                    for condition in enable_tests[transition]['downlink_specific_conditions']:
                        enable = enable + condition + " && "
                    for condition in enable_tests[transition]['horizontal_specific_conditions_a']:
                        enable = enable + condition + " && "
                    enable = enable[:-3]
                    f.write("           {} ->\n".format(enable))
                    f.write("           sP(_pid, 3);\n")
                    f.write("            gbchan!_pid,{0},{1},0;\n".format(transitions[net][transition]['horizontal_label'][0],transitions[net][transition]['promela_id']))
                    f.write("           printf(\"Firing transition {0}\");\n".format(
                        transitions[net][transition]['name'][0]))
                    f.write("           sP(_pid, 1);\n")
                    f.write("       }\n")

            f.write("       od}\n")
            if enable_tests[transition]['outer_loop_conditions']:
                f.write("       unless atomic{\n")
                f.write("       gbchan ?? eval(_pid),_,it,1\n         if")
                for transition in transitions[net].keys():
                    for outer_condition in enable_tests[transition]['outer_loop_conditions']:
                        f.write("  :: {} ->\n".format(outer_condition))
                        if(enable_tests[transition]['uplink_specific_conditions']):
                            for c in consume[transition]['general']:
                                f.write("           {}".format(c))
                            for c in consume[transition]['consume']:
                                f.write("           {}".format(c))
                            for p in produce[transition]['transport']:
                                f.write("           {}".format(p))
                            for p in produce[transition]['general']:
                                f.write("           {}".format(p))
                            for p in produce[transition]['run']:
                                f.write("           {}".format(p))
                        else:
                            for p in produce[transition]['run']:
                                f.write("           {}\n".format(p))
                        f.write("           printf(\"Firing outer loop transition {0}\");\n".format(
                            transitions[net][transition]['name'][0]))
            f.write("         fi; sP(_pid, 1);   }\n")
            f.write("   od; sP(_pid, 1);  }\n\n")

    f.close()