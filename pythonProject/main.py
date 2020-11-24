from input_process import init
from output_process import generate_promela_code
from process_utils import parse_channel_places, extract_vars_from_arcs
from tranlator import create_enable_tests

system_net_name, places, transitions, arcs, nets, uplink, downlink, horizontal, vlabels, hlabels, shared_places, arc_variables, only_places_dict, only_arcs_dict, only_transitions_dict = init()
channel_places, non_channel_places = parse_channel_places(only_places_dict, only_arcs_dict, system_net_name, arc_variables)

print("Places: ", places)
print("Transitions: ", transitions)
# print("Arcs: ", arcs)
print("Nets: ", nets)
# print("Uplink: ", uplink)
# print("Downlink: ", downlink)
# print("Horizontal: ", horizontal)
print("Vlabels: ", vlabels)
print("Hlabels: ", hlabels)
# print("Shares: ", shared_places)
# print("Arc_variables: ", arc_variables)
# print("channel_places", channel_places)
# print("Not_channel_places", non_channel_places)
# print("only_transitions", only_transitions_dict)
# print("only_arcs_dict", only_arcs_dict)


enable_tests, consume, produce = create_enable_tests(only_places_dict, only_transitions_dict, only_arcs_dict, channel_places, arc_variables, vlabels, hlabels, nets)
print(consume)
print(produce)
generate_promela_code(system_net_name, places, transitions, arcs, nets, uplink, downlink, horizontal, vlabels, hlabels, shared_places, arc_variables, only_places_dict, only_arcs_dict, channel_places, enable_tests, consume, produce)
