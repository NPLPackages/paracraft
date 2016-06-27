---+ Neuron Block System
| Author(s)	|  LiXizhi  |
| Date		| 2013/3/17 |

---++ Introduction 

---++ Data Design
Each neuron consists of a position, axon/dendrites connections, a coding model, and a neuron state. 
Neuron parameters:
| *name*	| *desc* | 
| x, y, z	| block space position that uniquely identified the neuron | 
| filename  | npl filename associated |
| type		| if not specified, it default to default neuron template |
| mem		| memory table | 
| axon		| all connections to down stream neurons are written here.  | 
| dendrite(d)	| Each axon-dendrite synpase is saved here |
| dendrite.dist	| distance from this neuron nuclear to the synapse. This is a precaculated value. |

<neurons offsets="0,0,0" >
	<neuron  x="128" y="0" z="128" filename="neuron_file.lua">
		<mem></mem>
		<axon>
			<d x="128" y="1" z="128" dist="1"/>
			<d x="128" y="2" z="128" dist="2"/>
		</axon>
	</neuron>
</neurons>

---++ Neuron script file associated 

Each block can be associated with a script file as defined in neuron.filename attribute. 
The filename is relative path to "[world_dir]/scripts/block/". So if the filename is "neuron_file.lua", the actual file is located in 
"[world_dir]/scripts/block/neuron_file.lua"

Each block's neuron script has its own scope even they share the same script file on disk. Any global function or variable defined is local to that neuron. 
Each neuron have a "main" function like below. This function is called whenever the block is activated in the scene. 

<verbatim>

local abc=1;
global_variable_a = "abc";

function main(msg)
	echo(msg);
end

</verbatim>

It is possible to access global variables in block script by its block position. 

See NeuronAPISandbox.lua for a complete list of API
---++ Sim design

