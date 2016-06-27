---+ Cell Block System
| Author(s)	|  LiXizhi  |
| Date		| 2013/7/14 |

---++ Introduction 
A cell block is a special kind of cubic neuron block that can split into 2 cells in 26 possible directions when certain conditions. 
When splitting condition is not met, the cell functions as a normal neuron block according to internal functions. 

There may be many different kinds of cell blocks that constitute a simple growing creature (like a tree). 
The base class of all cell block is CellBlock. Most creatures start from a seed block that spawns other types of cell blocks. 
The chain of cell splitting in space is subject to DNA code and some fixed random function. 

DNA code is actually a large collection of cell block type definitions and function code. and it all start from the code represented by the seed block. 
When the seed block is put into block space, it starts to grow and unlock other new cell types and DNA codes as it splits and react to environment stimulations. 

Each cell block may send neuron msg to neary cell blocks and each cell may receive msg and other sensor input from its environment. 
How the cell reacts to the environment is defined in the check_split() function of each cell's DNA code. 
When splitting condition is met, the cell may split(may have some randomness) into two predefined new cells. 

---++ Data Design

---++ Sim design

