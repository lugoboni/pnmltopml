NON_CHANNEL_WITH_BLACK_DOT = "A black dot was found in channel place "

def get_arc_by_target(target, arcs):
    out = list()
    for arc_key in arcs.keys():
        for arc in arcs[arc_key]:
            if arc['target'] == target:
                out.append((arc_key, arc))
    return out


def check_channel_non_channel_places(non_channel, channel_places):
    for place in non_channel:
        if place in channel_places:
            raise Exception(NON_CHANNEL_WITH_BLACK_DOT + place)


def parse_channel_places(places, arc_dicts, system_net, arc_variables):
    not_channel = set()
    channel_places = set()
    for place in places.keys():
        arcs = get_arc_by_target(place, arc_dicts)
        for arc in arcs:
            for token in arc[1]['marking'].keys():
                if token in arc_variables:
                    channel_places.add(place)
                else:
                    not_channel.add(place)
    check_channel_non_channel_places(not_channel, channel_places)
    return channel_places, not_channel


def extract_vars_from_arcs(arcs, arc_variables):
    vars_in_arc = dict().fromkeys(arc_variables, 0)
    for key in arcs.keys():
        for element in arcs[key]:
            for mark in element['marking'].keys():
                if mark in arc_variables:
                    vars_in_arc[mark] = vars_in_arc[mark] + element['marking'][mark]

    return vars_in_arc


