from process_utils import get_arc_by_target, extract_vars_from_arcs

NON_PROCESSED_TOKEN = "A not processed token was found"
COMMON_TOKEN_ON_CHANNEL_PLACE = "A channel place can not handle with a non net token"
UNBALANCED_VARS = "unbalanced variables in arcs"


def create_initial_marking(place_dict, channel_places, net_tokens_list, shared_places):
    initial_marking = list()
    for key in place_dict:
        if key in channel_places:
            create_net_place = "NetPlace {0};\n".format(
                place_dict[key]['name'][0])
            initial_marking.append(create_net_place)
            for mark in place_dict[key]['marking'].keys():
                if mark not in net_tokens_list:
                    raise Exception(NON_PROCESSED_TOKEN)
                else:
                    for i in range (0, place_dict[key]['marking'][mark]):
                        initial_marking.append("nt = run {0}({1}.d);\n".format(mark, place_dict[key]['name'][0]))
                        initial_marking.append("{}.d ! nt,255,0,0;\n".format(place_dict[key]['name'][0]))
        elif place_dict[key]['name'][0] not in shared_places:
            if place_dict[key]['marking'].keys():
                for mark in place_dict[key]['marking'].keys():
                    if mark not in net_tokens_list:
                        marking = "byte {0} = {1};\n".format(
                            place_dict[key]['name'][0],
                            place_dict[key]['marking'][mark])
                        initial_marking.append(marking)
            else:

                marking = "byte {0} = {1};\n".format(
                    place_dict[key]['name'][0],
                    0)
                initial_marking.append(marking)
    initial_marking.append("byte it;\n")

    return (initial_marking)

def create_enable_tests(only_places, only_transitions, only_arcs, channel_places, arc_variables, vlabel, hlabel, nets_info):
    enable_tests = dict.fromkeys(only_transitions)
    consume = dict.fromkeys(only_transitions)
    produce = dict.fromkeys(only_transitions)
    for transition in enable_tests.keys():
        tansition_label = ""
        sentences = dict([
        ('general_condition', list()),
        ('uplink_specific_conditions', list()),
        ('downlink_specific_conditions', list()),
        ('horizontal_specific_conditions_a', list()),
        ('horizontal_specific_conditions_b', list()),
        ('outer_loop_conditions', list())
        ])
        consume_actions = dict([
        ('general', list()),
        ('consume', list())
        ])
        arcs_out = only_arcs[transition]
        produce_actions = dict([
        ('transport', list()),
        ('run', list()),
        ('general', list())
        ])
        arcs = get_arc_by_target(transition, only_arcs)
        # vars = extract_vars_from_arcs(arcs, arc_variables)
        if only_transitions[transition]['downlink_label']:
            if arcs:
                downlink_label = only_transitions[transition]['downlink_label'][0]
                tansition_label = downlink_label
                origins = list()
                for arc in arcs:
                    if arc[0] in channel_places:
                        origin = only_places[arc[0]]['name'][0]
                        origins.append(origin)
                for origin in origins:
                    downlink_condition = "gbchan ?? [_,{1},_,0]".format(origin ,downlink_label)
                    sentences['downlink_specific_conditions'].append(downlink_condition)
            else:
                pass
        elif only_transitions[transition]['uplink_label']:
            if arcs:
                uplink_label = only_transitions[transition]['uplink_label'][0]
                tansition_label = uplink_label
                fire_uplink_condition = "it == {0}".format(only_transitions[transition]['promela_id'])
                sentences['outer_loop_conditions'].append(fire_uplink_condition)

                condition = "! gbchan ?? [_,{0},_,0]".format(uplink_label)
                sentences['uplink_specific_conditions'].append(condition)
                # sentence = "pc ! _pid,{0},{1},1;\n".format(uplink_label, only_transitions[transition]['promela_id'])
                # produce_actions['general'].append(sentence)

            else:
                pass

        elif only_transitions[transition]['horizontal_label']:
            if arcs:
                horizontal_label = only_transitions[transition]['horizontal_label'][0]
                tansition_label = horizontal_label
                sentences['horizontal_specific_conditions_a'].append("! gbchan??[_,{0},_,0]".format(horizontal_label))
                sentences['horizontal_specific_conditions_b'].append("! gbchan??[eval(_pid),{0},_,0] && gbchan??[_,{0},_,0]".format(horizontal_label))
                sentences['outer_loop_conditions'].append("it == {0}".format(only_transitions[transition]['promela_id']))
                sentence = "gbchan ! _pid,{0},{1},0;\n".format(horizontal_label, only_transitions[transition]['promela_id'])
                produce_actions['general'].append(sentence)
        else:
            pass

        if arcs:
            for arc in arcs:
                if arc[1]['marking'].keys():
                    for mark in arc[1]['marking'].keys():
                        if mark not in arc_variables:
                            origin = only_places[arc[0]]['name'][0]
                            condition = origin + " >= " + \
                                list(arc[1]['marking'].keys())[0]
                            sentences['general_condition'].append(condition)

                        elif mark in arc_variables and arc[0] in channel_places:
                            arity = sum(arc[1]['marking'].values())
                            if arity > 1:
                                condition = "c_expr{{numMsg(qptr(LocalVar->{0}.d-1),{1})>={2}}}".format(only_places[arc[0]]['name'][0], "255", arity)
                                sentences['general_condition'].append(condition)
                            else:
                                # condition = "{0}.d ?? [_,{1},_,0]".format(only_places[arc[0]]['name'][0], "255")
                                # sentences['general_condition'].append(condition)
                                condition = "nempty({0}.d)".format(only_places[arc[0]]['name'][0])
                                sentences['general_condition'].append(condition)
                                pass
                        elif mark not in arc_variables and arc[0] in channel_places:
                            raise Exception(COMMON_TOKEN_ON_CHANNEL_PLACE)
                        else:
                            raise Exception(NON_PROCESSED_TOKEN)

                else:
                    if arc[0] not in channel_places:
                        origin = only_places[arc[0]]['name'][0]
                        condition = origin + " > " + '0'
                        sentences['general_condition'].append(condition)

                    else:
                        sentences['general_condition'].append("1")  # avaliar
        else:  # If there's no arc inciding on the transition
            condition = "1"
            sentences['general_condition'].append(condition)

        enable_tests[transition] = sentences


        arcs_out = only_arcs[transition]

        for arc in arcs:
            if arc[0] in channel_places and arc[1]['marking'].keys():
                marks_count = arc[1]['marking']
                for mark in marks_count.keys():
                    for out_arc in arcs_out:
                        out_marks_count = out_arc['marking']
                        while marks_count[mark] > 0 and mark in out_marks_count.keys() and out_marks_count[mark] > 0:
                            if tansition_label:
                                sentence = "gbchan ?? nt,{1},_,0;\n".format(only_places[arc[0]]['name'][0], tansition_label)
                            else:
                                sentence = "gbchan ?? nt,_,_,0;\n"
                            if sentence not in produce_actions['transport']:
                                produce_actions['transport'].append(sentence)

                            if tansition_label:
                                sentence = "gbchan ! nt,{1},{2},1;\n".format(only_places[arc[0]]['name'][0], tansition_label, only_transitions[transition]['promela_id'])
                            else:
                                sentence = "gbchan ! nt,0,{1},1;\n".format(only_places[arc[0]]['name'][0], only_transitions[transition]['promela_id'])

                            if sentence not in produce_actions['transport']:
                                produce_actions['transport'].append(sentence)

                            sentence_b = "{0}.d ! nt,255,0,0;\n".format(only_places[arc[0]]['name'][0])
                            # produce_actions['transport'].append(sentence)
                            produce_actions['transport'].append(sentence_b)


                            sentence = "transpNetTok({0}.d, {1}.d, nt);\n".format(only_places[arc[0]]['name'][0], only_places[out_arc['target']]['name'][0])
                            produce_actions['transport'].append(sentence)
                            # if tansition_label:
                            #     sentence = "{0}.d ! nt,{1},{2},1;\n".format(only_places[out_arc['target']]['name'][0], tansition_label, only_transitions[transition]['promela_id'])
                            # else:
                            #     sentence = "{0}.d ! nt,_,{1},1;\n".format(only_places[out_arc['target']]['name'][0], only_transitions[transition]['promela_id'])
                            # sentence_b = "{0}.d ! nt,255,0,0;\n".format(only_places[out_arc['target']]['name'][0])
                            # produce_actions['transport'].append(sentence)
                            # produce_actions['transport'].append(sentence_b)
                            marks_count[mark] = marks_count[mark] - 1
                            out_marks_count[mark] = out_marks_count[mark] - 1


        for arc in arcs:
            if arc[0] in channel_places and arc[1]['marking'].keys():
                marks_count = arc[1]['marking']
                for mark in marks_count.keys():
                    if marks_count[mark] > 0:
                        for i in range(0, marks_count[mark]):
                            sentence = "gbchan ?? nt,{1},{2},0;\n".format(only_places[arc[0]]['name'][0], tansition_label, only_transitions[transition]['promela_id'])
                            consume_actions['consume'].append(sentence)
                            sentence = "consNetTok({0}.d,nt);\n".format(only_places[arc[0]]['name'][0])
                            consume_actions['consume'].append(sentence)
                            sentence = "gbchan ! nt,{1},{2},1;\n".format(only_places[arc[0]]['name'][0], tansition_label, only_transitions[transition]['promela_id'])
                            consume_actions['consume'].append(sentence)
            else:
                if arc[1]['marking'].keys():
                    for mark in arc[1]['marking'].keys():
                        if arc[1]['marking'][mark] not in arc_variables:
                            sentence = "{0} = {0} - {1};\n".format(only_places[arc[0]]['name'][0], list(arc[1]['marking'].keys())[0])
                            consume_actions['general'].append(sentence)

                else:
                    sentence = "{0} = {0} - 1;\n".format(only_places[arc[0]]['name'][0])
                    consume_actions['general'].append(sentence)

            origin_places = [k[0] for k in arcs]
            for origin_place in origin_places:
                origin_arcs = only_arcs[origin_place]
                for origin_arc in origin_arcs:
                    brother_transition = only_transitions[origin_arc['target']]
                    if origin_arc['target'] != arc[1]['target'] and (brother_transition['uplink_label'] or brother_transition['downlink_label'] or brother_transition['horizontal_label']):
                        brother_transition_label = ""
                        if brother_transition['uplink_label']:
                            brother_transition_label = brother_transition['uplink_label'][0]
                        elif brother_transition['downlink_label']:
                            brother_transition_label = brother_transition['downlink_label'][0]
                        elif brother_transition['horizontal_label']:
                            brother_transition_label = brother_transition['horizontal_label'][0]
                        else:
                            raise Exception
                        if origin_arc['marking'].keys():
                            for mark in origin_arc['marking'].keys():
                                sentence = "rmConf({0}, gbchan)\n".format(brother_transition_label,
                                                                         only_places[origin_place]['name'][0])
                                if mark in arc[1]['marking'].keys() and mark in arc_variables and origin_place in channel_places:
                                    consume_actions['consume'].append(sentence)
                                elif sentence not in consume_actions['consume'] and origin_place != arc[0]:
                                    sentence = "rmConf({0}, gbchan)\n".format(brother_transition_label)
                                    consume_actions['consume'].append(sentence)
                        else:
                            sentence = "rmConf({0}, gbchan)\n".format(brother_transition_label,
                                                                     only_places[origin_place]['name'][0])
                            base_sentence = "rmConf({0}, gbchan)\n".format(brother_transition_label)
                            if sentence not in consume_actions['consume'] and base_sentence not in consume_actions['consume']:
                                consume_actions['consume'].append(base_sentence)




        for arc in arcs_out:
            if arc['marking'].keys():
                for mark in arc['marking'].keys():
                    if mark in arc_variables and mark not in nets_info.keys() and arc['marking'][mark] > 0:
                        raise Exception(UNBALANCED_VARS)

                    elif mark in nets_info.keys():
                        sentence = "nt = run {0}({1}.d);\n".format(mark, only_places[arc['target']]['name'][0])
                        produce_actions['run'].append(sentence)
                        sentence = "{0}.d ! nt,255,0,0;\n".format(only_places[arc['target']]['name'][0])
                        produce_actions['run'].append(sentence)
                        if tansition_label:
                            sentence = "gbchan ! _pid,{0},{1},0;\n".format(tansition_label,
                                                                   only_transitions[transition]['promela_id'])
                        else:
                            sentence = "gbchan ! _pid,0,{0},0;\n".format(only_transitions[transition]['promela_id'])
                        produce_actions['general'].append(sentence)

                        if not sentences['outer_loop_conditions']:
                            sentences['outer_loop_conditions'].append("it == {0}".format(only_transitions[transition]['promela_id']))

                    elif mark not in arc_variables:
                        sentence = "{0} = {0} + {1};\n".format(only_places[arc['target']]['name'][0], mark)
                        produce_actions['general'].append(sentence)
            else:
                sentence = "{0} = {0} + 1;\n".format(only_places[arc['target']]['name'][0])
                produce_actions['general'].append(sentence)

        consume[transition] = consume_actions
        produce[transition] = produce_actions

    return enable_tests, consume, produce

