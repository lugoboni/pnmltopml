import sys, re
from xml.etree import ElementTree
EXTENSION_FORMAT_ERROR_MESSAGE = "This script works only with pnml files"
TRANSITION_TAG_MODEL_STRING = '{NestedSpin}transition'
PLACE_TAG_MODEL_STRING = '{NestedSpin}place'
ARC_TAG_MODEL_STRING = '{NestedSpin}arc'
BLACK_TOKEN = '[]'

def extract_feature(thing, feature):
    feature_string = '{NestedSpin}' + feature
    if thing.find(feature_string) is not None:
        features = thing.findall(feature_string)
        return [item.find('{NestedSpin}text').text for item in features]
    else:
        return []

def create_nets_info(nets):
    nets_info = dict()
    net_label = 1
    for net in nets:
        if 'SN' not in net:
            nets_info[net] = dict()
            nets_info[net]['label'] = net_label
            net_label += 1
            nets_info[net]['tokens'] = set()
            nets_info[net]['transitions_labels'] = set()
        else:
            nets_info[net] = dict() if net not in nets_info.keys() else None
            nets_info[net]['tokens'] = set()
            nets_info[net]['transitions_labels'] = set()
        nets_info[net]['id'] = 0
    return nets_info

def parse_transitions_and_labels(root, transition_dicts, nets_info, uplink, downlink, horizontal, only_transitions_dict):
    transition_dict = dict()
    raw_transition_elements = list(root[0].iter(TRANSITION_TAG_MODEL_STRING))
    promela_id = 1

    parsed_transition_elements = [
        (
            nets_info[root[1]]['id'] + raw_transition_elements[i].attrib['id'],
            extract_feature(raw_transition_elements[i], 'name'),
            extract_feature(raw_transition_elements[i], 'downlink_label'),
            extract_feature(raw_transition_elements[i], 'uplink_label'),
            extract_feature(raw_transition_elements[i], 'horizontal_label')
        )
        for i in range(0, len(raw_transition_elements))]

    for transition in parsed_transition_elements:
        downlink_label = transition[2][0] if transition[2] else None
        uplink_label = transition[3][0] if transition[3] else None
        horizontal_label = transition[4][0] if transition[4] else None
        transition_id = transition[0]


        if downlink_label and downlink_label in downlink.keys():
            downlink[downlink_label].append(transition_id)
            nets_info[root[1]]["transitions_labels"].add(downlink_label)
        elif downlink_label:
            downlink[downlink_label] = [transition_id]
            nets_info[root[1]]["transitions_labels"].add(downlink_label)

        if uplink_label and uplink_label in uplink.keys():
            uplink[uplink_label].append(transition_id)
            nets_info[root[1]]["transitions_labels"].add(uplink_label)
        elif uplink_label:
            uplink[uplink_label] = [transition_id]
            nets_info[root[1]]["transitions_labels"].add(uplink_label)

        if horizontal_label and horizontal_label in horizontal.keys():
            horizontal[horizontal_label].append(transition_id)
            nets_info[root[1]]["transitions_labels"].add(horizontal_label)
        elif horizontal_label:
            horizontal[horizontal_label] = [transition_id]
            nets_info[root[1]]["transitions_labels"].add(horizontal_label)

        transition_dict[transition[0]] = dict(
            [
                ('name', transition[1]),
                ('downlink_label', transition[2]),
                ('uplink_label', transition[3]),
                ('horizontal_label', transition[4]),
                ('promela_id', promela_id)
            ])
        promela_id = promela_id + 1
    only_transitions_dict.update(transition_dict)
    transition_dicts[root[1]] = transition_dict

def parse_places(root, place_dicts, nets_info, shared_places, only_places_dict):
    place_dict = dict()
    raw_place_elements = list(root[0].iter(PLACE_TAG_MODEL_STRING))

    parsed_place_elements = [
        [
            nets_info[root[1]]['id'] + raw_place_elements[i].attrib['id'],
            extract_feature(raw_place_elements[i], 'name'),
            extract_feature(raw_place_elements[i], 'initialMarking'),
            extract_feature(raw_place_elements[i], 'type'),
        ]
        for i in range(0, len(raw_place_elements))]

    for place in parsed_place_elements:
        marking = dict()
        if place[2]:
            for mark in place[2]:
                if mark in marking.keys():
                    marking[mark] = marking[mark] + 1
                else:
                    marking[mark] = 1
                nets_info[root[1]]['tokens'].add(mark)
        place[2] = marking

        if place[3] and place[3][0] == "shared":
            if BLACK_TOKEN in place[2].keys():
                shared_places.add((place[1][0], place[2][BLACK_TOKEN]))
            else:
                shared_places.add((place[1][0], 0))
        place_dict[place[0]] = dict(
            [
                ('name', place[1]),
                ('marking', place[2]),
                ('type', place[3])
            ])
    only_places_dict.update(place_dict)
    place_dicts[root[1]] = place_dict

def parse_arcs(root, arc_dicts, nets_info, arc_variables, only_arcs_dict):
    arc_dict = dict()
    raw_arc_elements = list(root[0].iter(ARC_TAG_MODEL_STRING))

    def make_mark_dict(arc):
        mark_dict = dict()
        for mark in arc.findall('{NestedSpin}inscription'):
            if mark.find('{NestedSpin}text').text in mark_dict.keys():
                mark_dict[mark.find('{NestedSpin}text').text] += 1
            else:
                mark_dict[mark.find('{NestedSpin}text').text] = 1
        return mark_dict
    parsed_arc_elements = [
        (
            nets_info[root[1]]['id'] + raw_arc_elements[i].attrib['id'],
            nets_info[root[1]]['id'] + raw_arc_elements[i].attrib['source'],
            nets_info[root[1]]['id'] + raw_arc_elements[i].attrib['target'],
            make_mark_dict(raw_arc_elements[i]),
            extract_feature(raw_arc_elements[i], 'type')
        )
        for i in range(0, len(raw_arc_elements))]

    for arc in parsed_arc_elements:
        for var in arc[3].keys():
            if not re.search("^[0-9]+", var) and var != BLACK_TOKEN:
                arc_variables.add(var)

        element = dict(
                    [
                        ('id', arc[0]),
                        ('target', arc[2]),
                        ('marking', arc[3]),
                        ('type', arc[4])
                    ])

        if arc[1] in arc_dict.keys():
            arc_dict[arc[1]].append(element)

        else:
            arc_dict[arc[1]] = [element]
    only_arcs_dict.update(arc_dict)
    arc_dicts[root[1]] = arc_dict

def create_sync_tag_in_labels(uplink, horizontal):
    vlabels = dict.fromkeys(uplink.keys())
    hlabels = dict.fromkeys(horizontal.keys())
    count = 1
    for key in vlabels:
        vlabels[key] = count
        count = count + 1

    count = 254

    for key in hlabels:
        hlabels[key] = count
        count = count - 1

    return vlabels, hlabels


# def link_vars_to_net_tokens(channel_places, arcs, places):
#     tokens = dict()
#     marks = dict()
#     for place in channel_places:
#         if places[place]['marking']:
#             for mark in places[place]['marking'].keys():
#                 if mark in marks.keys():
#                     marks[mark] = marks[mark] + places[place]['marking'][mark]
#                 else:
#                     marks[mark] = places[place]['marking'][mark]
#             output_arcs = arcs[place]
#             for output_arc in output_arcs:
#                 if output_arc['marking']:
#                     for mark in output_arc['marking'].keys():
#                         if mark in tokens.keys():
#                             tokens[mark] = tokens[mark] + output_arc['marking'][mark]
#                         else:
#                             tokens[mark] = output_arc['marking'][mark]
#
#     tokens = sorted(tokens.items(), key=lambda x: x[1])
#     marks = sorted(marks.items(), key=lambda x: x[1])
#     var_for_marks = dict(zip(marks.keys(), tokens.keys()))
#
#     return var_for_marks





def init():
    args = sys.argv[1:]

    INPUT_FILES = [str(arg) for arg in args]
    splited_filenames = [INPUT_FILE.split('.') for INPUT_FILE in INPUT_FILES]

    for splited_filename in splited_filenames:
        if len(splited_filename) < 2:
            raise Exception(EXTENSION_FORMAT_ERROR_MESSAGE)

    BASE_FILENAMES = [splited_filename[0]
                      for splited_filename in splited_filenames]
    EXTENSIONS_FILENAMES = set([splited_filename[1]
                  for splited_filename in splited_filenames])

    if len(EXTENSIONS_FILENAMES) != 1 and EXTENSIONS_FILENAMES[0] != "pnml":
        raise Exception(EXTENSION_FORMAT_ERROR_MESSAGE)


    transition_dicts = dict.fromkeys(BASE_FILENAMES, 0)
    place_dicts = dict.fromkeys(BASE_FILENAMES, 0)
    only_places_dict = dict()
    arc_dicts = dict.fromkeys(BASE_FILENAMES, 0)
    only_arcs_dict = dict()
    only_transitions_dict = dict()
    nets_info = create_nets_info(BASE_FILENAMES)
    uplink = dict()
    downlink = dict()
    horizontal = dict()
    shared_places = set()
    arc_variables = set()

    initial_trees = [(ElementTree.parse(INPUT_FILE), INPUT_FILE.split('.')[0])
                     for INPUT_FILE in INPUT_FILES]

    for tree in initial_trees:
        nets_info[tree[1]]['id'] = tree[0].find('{NestedSpin}net').attrib['id']

    roots = [(initial_tree[0].getroot()[0], initial_tree[1]) for initial_tree in initial_trees]

    for root in roots:
        parse_transitions_and_labels(root, transition_dicts, nets_info, uplink, downlink, horizontal, only_transitions_dict)
        parse_places(root, place_dicts, nets_info, shared_places, only_places_dict)
        parse_arcs(root, arc_dicts, nets_info, arc_variables, only_arcs_dict)

    vlabels, hlabels = create_sync_tag_in_labels(uplink, horizontal)

    return BASE_FILENAMES[0], place_dicts, transition_dicts, arc_dicts, nets_info, uplink, downlink, horizontal, vlabels, hlabels, shared_places, arc_variables, only_places_dict, only_arcs_dict, only_transitions_dict