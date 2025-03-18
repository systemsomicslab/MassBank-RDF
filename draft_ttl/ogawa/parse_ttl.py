# pip install rdflib
import re
import yaml
from rdflib import Graph, URIRef, Literal, BNode

# Input Turtle file
TTL_FILE = "MSBNK-AAFC-AC000001-oka.ttl"

# Load Turtle file into RDF Graph
graph = Graph()
graph.parse(TTL_FILE, format="turtle")

# Extract prefixes from the Turtle file
prefixes = {}
with open(TTL_FILE, "r", encoding="utf-8") as f:
    for line in f:
        match = re.match(r"@prefix\s+([a-zA-Z0-9_-]+):\s+<([^>]+)>", line)
        if match:
            prefixes[match.group(1)] = f'<{match.group(2)}>'

# Save prefixes to prefix.yaml
with open("prefix.yaml", "w", encoding="utf-8") as f:
    yaml.dump(prefixes, f, allow_unicode=True, default_flow_style=False)

print("prefix.yaml has been created")


# Define Node class to store RDF objects
class RDFNode:
    # Static variable to track object name occurrences for uniqueness
    object_name_counts = {}

    def __init__(self, object_name=None, value=None, predicate=None):
        self.object_name = object_name
        self.predicate = predicate  # rdf:type, rdfs:label, etc.
        self.value = value  # URI or Literal; if blank node, value is a list

    @staticmethod
    def to_snake_case(predicate: str):
        """ Convert 'mbo:TentativeFormula' to 'tentative_formula' """
        predicate = predicate.split(":")[-1]  # Remove prefix
        predicate = re.sub(r'([a-z])([A-Z])', r'\1_\2', predicate)  # Convert CamelCase to snake_case
        return predicate.lower()

    @staticmethod
    def get_unique_object_name(base_name):
        """ Generate a unique object name by appending an index if necessary """
        if base_name not in RDFNode.object_name_counts:
            RDFNode.object_name_counts[base_name] = 0
            return base_name
        else:
            RDFNode.object_name_counts[base_name] += 1
            return f"{base_name}_{RDFNode.object_name_counts[base_name]}"

    def to_dict(self):
        assert self.predicate is not None, "Predicate is required"
        assert self.value is not None, "Value is required"

        # If predicate is rdf:type or a, do not assign an object name
        if self.predicate in ["rdf:type", "a"]:
            return {self.predicate: [self.value]}

        # Handle blank nodes
        if isinstance(self.value, list):
            return {self.predicate: [{'[]': [child.to_dict() if isinstance(child, RDFNode) else child for child in self.value]}]}

        # Assign a unique object name if not already set
        if self.object_name is None:
            base_name = RDFNode.to_snake_case(self.predicate)
            self.object_name = RDFNode.get_unique_object_name(base_name)

        return {self.predicate: [{self.object_name: self.value}]}


# Function to shorten URIs using defined prefixes
def shorten_uri(uri: str) -> str:
    for prefix, namespace in prefixes.items():
        namespace_str = namespace.replace('<', '').replace('>', '')
        if uri.startswith(namespace_str):
            return f"{prefix}:{uri[len(namespace_str):]}"
    return uri  # Return original URI if no prefix match is found


# Dictionary to store structured RDF data
rdf_data = {}
blank_nodes = {}

# Store blank nodes separately
for subject, predicate, obj in graph:
    if isinstance(subject, BNode):
        bn_id = str(subject)
        if bn_id not in blank_nodes:
            blank_nodes[bn_id] = []
        blank_nodes[bn_id].append((subject, predicate, obj))


# Recursively process blank nodes
def process_blank_node(bn_id):
    bn_triples = blank_nodes[bn_id]
    result = []
    for s, p, o in bn_triples:
        data = process_triples('[]', p, o)
        result.extend(data['[]'])
    return result


# Function to process RDF triples and structure them as hierarchical data
def process_triples(subject, predicate, obj):
    structured_data = {}
    subject = shorten_uri(str(subject))
    predicate = shorten_uri(str(predicate))

    # Initialize subject if not already present
    if subject not in structured_data:
        structured_data[subject] = []

    # Handle literals
    if isinstance(obj, Literal):
        obj_value = f'"{obj}"'  # Enclose string literals in double quotes

        # Add datatype suffix if applicable
        if obj.datatype:
            datatype_str = shorten_uri(str(obj.datatype))
            if datatype_str.endswith("decimal"):
                if str(obj.value).isdigit():
                    obj_value = int(obj.value)
                else:
                    obj_value = float(obj.value)
            else:
                obj_value = f'"{obj}"^^{datatype_str}'
            # elif datatype_str.endswith("date"):
            #     obj_value = f'"{obj}"^^xsd:date'
            # elif datatype_str.endswith("double"):
            #     obj_value = f"{obj_value}^^xsd:double"
            # elif datatype_str.endswith("integer") or isinstance(obj.value, int):
            #     obj_value = f"{obj_value}^^xsd:integer"
            # elif datatype_str.endswith("float") or isinstance(obj.value, float):
            #     obj_value = f"{obj_value}^^xsd:float"
            # else:
            #     obj_value = str(obj.value)
        else:
            # obj_value = str(obj.value)
            if not isinstance(obj_value, str) or True:
                obj_value = str(obj_value)
            

        structured_data[subject].append(RDFNode(predicate=predicate, value=obj_value).to_dict())

    # Handle URIs (links to other entities)
    elif isinstance(obj, URIRef):
        obj = shorten_uri(str(obj))
        structured_data[subject].append(RDFNode(predicate=predicate, value=obj).to_dict())

    # Handle blank nodes
    elif isinstance(obj, BNode):
        bn_id = str(obj)
        child_nodes = process_blank_node(bn_id)
        structured_data[subject].append(RDFNode(predicate=predicate, value=child_nodes).to_dict())

    return structured_data


def rdf_type_to_subject_name(rdf_type):
    """ Convert 'mbo:MassSpectrum' to 'MassSpectrum' (CamelCase) """
    rdf_type = rdf_type.split(":")[-1]  # Remove prefix (e.g., 'mbo:MassSpectrum' -> 'MassSpectrum')
    return ''.join(word.capitalize() for word in re.split(r'[_\s]+', rdf_type))  # Convert to CamelCase


# Process RDF triples and structure them
subj_names = {}
for s, p, o in graph:
    if isinstance(s, BNode):
        continue  # Skip blank nodes, handled separately

    data = process_triples(s, p, o)
    for subj, values in data.items():
        if subj not in rdf_data:
            rdf_data[subj] = []
        if 'rdf:type' in [v2 for v1 in values for v2 in v1]:
            subj_name = values[0]['rdf:type'][0]
            subj_name = rdf_type_to_subject_name(subj_name)
            subj_names[subj] = subj_name
        rdf_data[subj].extend(values)

# Convert rdf_data to the required YAML format
rdf_data = [{f'{subj_names[key]} {key}': value} for key, value in rdf_data.items()]

class CustomDumper(yaml.Dumper):
    def represent_str(self, data):
        """Convert '[]' into '- []:' format while preserving other strings."""
        if data == "[]":  # 特定のフォーマットに変換
            # return self.represent_sequence('tag:yaml.org,2002:seq', [], flow_style=True)
            return self.represent_sequence('tag:yaml.org,2002:seq', [], flow_style=True)
        elif ((data.startswith("'") and data.endswith("'")) or (data.startswith('"') and data.endswith('"'))) \
                and True:
            data = data[1:-1]  # 最初と最後の ' を除去
            return self.represent_scalar('tag:yaml.org,2002:str', data, style='"')
        
        return self.represent_scalar('tag:yaml.org,2002:str', data, style='')  # 他の文字列はクォートなしで出力

CustomDumper.add_representer(str, CustomDumper.represent_str)

# Save structured data to model.yaml ensuring correct string representation
with open("model.yaml", "w", encoding="utf-8") as f:
    yaml.dump(
        rdf_data, f, 
        allow_unicode=True, 
        default_flow_style=False, 
        indent=2, 
        width=float("inf"),  # **改行を完全に防ぐ**
        Dumper=CustomDumper)

print("model.yaml has been created")
