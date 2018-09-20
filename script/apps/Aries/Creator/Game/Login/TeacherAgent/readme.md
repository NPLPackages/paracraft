# Agent Interface for Teaching
Author: LiXizhi
Date: 2018.9.19

We will use the concepts of knowledge engine in keepwork to teach users how to use paracraft. 

An agent may be configured to teach any number of knowledge domains. 

Each domain of knowledge can be activated and taught via an agent interface. 
A knowledge domain contains a dynamic pool of persistent experiences per user and a static memory of Notes that should be taught to the user. 
Once all notes are experienced for enough number of times, we will mark the knowledge domain as mastered. 

Experience is a persistent record of performed user actions in the history. We will keep track of what experiences the
user already have, and only teach them new experiences. 

A note is text sentence that represents a significant experience that can be taught to the user. 
A note may be triggered by tags or user actions. In most cases, a note must be experienced in order to be learned by a user. 

## Agent's Observation Model
An agent observes the user actions by examine the virtual worlds near the user avatar, especially those near the mouse cursor.
We wants to make sure the agent's attention matches the attention of the real user.

In addition to 3d, an agent also pays attention to text on 2D GUI interface. This is done by inserting annotations in mcml text code. 
`pe:annotation` is a special mcml tag that is only used by an agent. 

More over, an agent also hooks to user action filters, those user actions are recognized and converted to text for matching a note in knowledge domain. 

## Knowledge Domain Storage 

Static notes memory are stored in XML file such as `codeblock.knowledgedomain.xml`
```
<KnowledgeDomains>
	<KnowledgeDomain name="Code" weight="2">
		<note id="create a code block" maxRepeats="4">
			<content>
				Code block contains code that controls actors inside nearby movie blocks. 
				Press E, under movie tag, select CodeBlock.
			</content>
			<triggers>
				<see>CodeBlock</see>
			</triggers>
			<experiences>
				<action>setblock CodeBlock</action>
			</experiences>
		</note>
		<note id="open code block" maxRepeats="4">
			<content>
				right click code block to edit it. 
			</content>
			<triggers>
				<action>setblock CodeBlock</action>
			</triggers>
			<experiences>
				<action>open CodeBlockWindow</action>
			</experiences>
		</note>
	</KnowledgeDomain>
</KnowledgeDomains>
```
Knowledge domain contains a global weight value, the higher the value, the more likely its containing notes may be activated 
compared to other knowledge domains. For example, the domain of Basic Movement may has the highest level of weight. 

Each note contains an optional id attribute that describes the significant experience. 
- Each note contains a content element, which is always a short sentence describing how to perform its associated experience
- Triggers is an optional set of triggering conditions, such as seeing a block or user just performed a given action
- Experiences are a set of conditions that must all be performed in order for the note to be considered learned.

When a note is activated, there is an interval where all other notes are inactive. When a note is experienced, the note will be 
hidden automatically and a next note is selected. 

Once a triggering condition is met, we will increase the weight of the note, but the weight will decay very fast after a certain 
mount of time and eventually to 0. 
