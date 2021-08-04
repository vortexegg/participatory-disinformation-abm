# participatory-disinformation-abm

A NetLogo agent-based model simulating participatory disinformation.

## WHAT IS IT?

The purpose of this model is to simulate the top-down/bottom-up dynamics of what has come to be known as "participatory disinformation."

See the article ["What is participatory disinformation?"](https://www.cip.uw.edu/2021/05/26/participatory-disinformation-kate-starbird/
) for a description of the real-world phenomenon. This is based on the work of researchers at the University of Washington Center for an Informed Public, et al, in the context of disinformation about the 2020 United States presidential election.

In short, participatory disinformation describes the feedback loop by which disinformation about a particular topic or "frame" is dissimenated in a top-down fashion by political elites to their audiences, who then produce their own false/misleading rumors about the topic in a bottom-up participatory manner. These new rumors are then "traded-up" the media chain by connected social media influencers in an attempt to reach the ear of the political elites. Finally the political elites echo these new rumors back to the audiences who originally created them, reinforcing the frame of the disinformation story.

### Model Scope

This NetLogo model focuses on a particular scope of the problem, specifically:

- Specific unique rumors spread by political elites in a top-down manner to their audiences
- Audience members who adopt rumors from these elites and from their peers in a social network
- The audience members sporadically generate new rumors and communicate them with each other
- The new rumors are further communmicated by influencers within the audience in an attempt to get them adopted by the elites
- Upon adoption, the elites spread the new rumors back to the audiences

The original real-world particpiatory disinformation phenomenon also contains other dynamics that are not included in this model, such as the audience building a sense of collective grievance, and political elites mobilizing their agrieved audiences into collective action. These features are out of the scope of this model and are not represented in the simulation.

## HOW IT WORKS

### Agents

This model contains three types of agent breeds: elites, regulars, and influencers.

- _elites_ -- represent the political elite agents whose rumors are adopted by the audience (`regular` and `influencer`) agents.
- _regulars_ -- represent the audience agents who generate new rumors, and adopt and spread rumors amongst each other in the network.
- _influencers_ -- represent different audience agents whose rumors will be adopted by the `elites`. They also adopt and spread rumors in the network.

_In this documentation we sometimes refer to the combined set of `regular` and `influencer` agents together as "audience" agents where it is convenient. However "audience agents" are not a specific type of named breed in the model._

### Agent Properties

Every agent, regardless of its breed, posesses a property called `rumors-heard?`.

- _rumors-heard?_ -- a bitstring (from the NetLogo _bitstring_ extension), where each bit represents one of the unique rumors that can be adopted. If the bit is `1` or true, the specific rumor has been adopted. If the bit is `0` or false, the rumor has not been adopted.

Agents adopt a rumor from another agent by looking for the first unheard rumor in another agent's bitstring and setting the corresponding bit from `0` to `1` in their own `rumors-heard?` bitstring.

_`Regular` and `influencer` agents start with no rumors heard. `Elite` agents start with a single random rumor heard._

### Agent Actions

During the execution of the model, the agents perform the following actions each step:

#### Regular and influencer agents

`Regular` agents and `influencer` agents will attempt to adopt from `elites`, adopt from the network, generate rumors, and forget rumors.

- _Adopt from elites_ -- The agent has a random chance of adopting the first undeard rumor from the elite agents, based on the agent's distribution of exposure to the elites (see Model Environment).
- _Adopt from the network_ -- The agent has a random chance of adopting the first unheard rumor from a random one of its neighbors, if any, based on the fraction of neighbors who have heard any rumors.
- _Generate rumors_ -- The agent has a random chance of spontaneously "learning" a random rumor. It is possible that this rumor was already heard before.
- _Forget rumors_ -- The agent has a random chance of spontaneously "unlearning" a random rumor.

_By default, influencers will not generate rumors, but this behavior is controlled by a switch._

_It is also possible to limit rumor generation and rumor forgetting behavior to only a single agent each step via switches._


#### Elite agents

`Elite` agents will attempt to trade-up rumors from `influencers`:

- _Trade-up to elites_: The elite will select a random influencer agent and attempt to adopt the first unherad rumor from it, if any.

### Model Environment

The model environment consists of two significan features: patch coloring to control the distribution of elite exposure to regular agents for rumor adoption from elites, and a network connecting regular and influencer agents that controls network exposure for rumor adoption from other agents in the network.

**Patch coloring** is used to indicate which audience agents have a chance of adopting rumors from the elites, which is called _elite exposure_ in the model. There are three different variations of elite exposure:

- _uniform_: all audience agents have a chance of adopting from elites
- _irregular_: only certain irregular clusters of patches are colored, based on a voting algorithm, and agents on those colored patches have a chance of adoption
- _block_: a contiguous block of patches are colored and agents on those colored patches have a chance of adoption

_Patches colored green do not have elite exposure, while patches colored light red do have elite exposure._

The **network layout** is used to connect audience agents (`regulars` and `influencers`) together in a simulation of a social network. Agents have a chance of adopting rumors from the neighbors to which they are connected in the network, with a greater chance based on the relative number of their neighbors who have also adopted any rumors. There are three different network layouts:

- Preferential attachment
- Random
- Small world (uses the Watts Strogatz algorithm to get a better small world layout)

_These different layouts do not change the functional behavior of the model, but only determine the structure and distribution of the connections between networked agents._

### Setup and Go Procedures

The **`setup`** procedure executes the following steps to initialize the model:

- Runs the `clear-all` function to clear everything between executions
- Sets a default shape for each of the three agent breeds
- Sets up the network by generating a network with `num-people` number of "audience" agents based on the `network-type` and initializes the agents' `rumors-heard?` bitstring to set all rumors to false
- Randomly selects some fraction of the agents to be influencer agents
- Sets the rest of the agents to be regular agents
- Makes visual space for the elite agent to be represented in the world by moving all of the networked agents slightly toward the bottom of the world
- Creates an elite agent separately from the networked agents and initializes the elite agent's `rumors-heard?` to have a single random rumor set to true
- Sets up the patch coloring for the distribution of elite exposure based on the `variant`
- Resets the ticks

The **`go`** procedure executes the following steps to execute agent behaviors:

- Stop the model execution if either the number of ticks has exceeded `ticks-to-end` or if there are no turtles left who have not heard all of the possible rumors (i.e. full saturation of rumor disperal)
- Optionally slow down the model execution with a fine-grained speed control based on `model-rate-1-nth`
- Ask each audience agent (`regulars` and `influencers`) to do the following behaviors:
	- Attempt to adopt an unheard rumor from the elites
	- Attempt to adopt an unheard rumor from its neighbors in the social network
	- Attempt to randomly generate a new rumor
	- Attempt to randomly forget a previously heard rumor
- Ask the elite agent to attempt to adopt a rumor from one of the influencer agents
- Finally, increment the tick

## HOW TO USE IT

### Pre-execution Controls

Use the following controls to configure how the model will be set up prior to clicking the `setup` button:

#### Population settings

- _num-people_ -- the number of audience agents in the network (not including elites)
- _frac-influencers_ -- the fraction of audience agents who are `influencers` (the remainder are `regulars`)

#### Network layout settings

- _network-type_ -- the type of network to generate (preferential, random, or small-world)

_Preferential attachment settings_

- _min-size_ -- the minimum degree of connection between nodes in the preferrential attachment network

_Random network settings_

- _network-density_ -- the density of the random network

_Small world settings_

- _neighborhood-size_ -- the number of nodes connected to each node in the small world network

#### Elite exposure settings

- _variant_ -- the distribution of the population exposed to top-down infuence from elite rumors (uniform, irregular, block)
- _initial-green-pct_ -- the percentage of patches that are not exposed to elite rumors

### Operation Controls

Use the following controls to set up and operate the model's execution:

- _setup_ -- Click the `setup` button to initialize the agents, network, and patch coloration
- _go_ -- Click the `go` button to begin the simulation
- _reinitialize_ -- Click the `reinitialize` button to reset the state of the simulation without resetting the network layout, agent placement, or patch coloration
- _ticks-to-end_ -- the number of ticks before the simulation ends (if it doesn't end earlier due to total rumor dispersal)
- _model-rate-1-nth_ -- slow down the model execution by 1 / n number of ticks, as a further refinement of the model speed slider

### Model Parameter Controls

Use the following controls to adjust behavior of agents within the simulation. It can be useful to run the simulation by clicking `go`, adjust some of these sliders, and click `reinitialize` and then `go` again to see how the settings influence the behavior using an identical network layout:


#### Influence rate settings

- elite-influence_ -- the chance for agents to be influenced by top-down elite rumor dissemination
- _social-influence_ -- the chance for agents to be influenced by adopt rumors from other agents in the network
- _trade-up-influence_ -- the chance for an influencer agent to "trade-up" a novel rumor to the elites

#### Rumor generation settings

- _rumor-generation_ -- the chance for an agent to spontaneously generate a new rumor during a tick
- _max-rumors_ -- the maximum number of different rumors that can be spread through the network; used to initialize the bitstring of rumors-heard?
- _heard-rumors-to-generate_ -- deterimines whether an agent must have already heard at least one rumor before they can generate any new rumors
- _influencers-generate-rumors_ -- determines whether influencer agents can generate rumors in addition to regulars (who always generate rumors)
- _only-one-generates_ -- determines whether only a single agent has a chance of generating a rumor in one tick, or if all agents have a chance in one tick

#### Rumor dissipation

- _dissipation-rate_ -- The chance that agents will "forget" a rumor during a tick
- _only-one-forgets_ -- determines whether only a single agent has a chance of forgetting a rumor in one tick, or if all agents have a chanced in one tick

### Model Outputs

The following outputs are used to visualize dynamics of the model's behavior:

- _Rumor counts_ -- A histogram showing each of the unique rumors on the x axis and the count of how many agents have heard that specific rumor on the y axis. This is useful for visualizing the state of rumor generation and understanding the dynamics of when a rumor "catches on" in the network.
- _Rumors heard_ -- A line chart showing the average amount of the fraction of total rumors that have been heard by each agent over time, compared to the count of times that a new rumor is successfully traded up to elites. This is useful for visualizing the relationship between when an elite adopts a traded-up rumor, and how the audience network begins to adopt that rumor once it starts getting echoed back by the elites.
- _Rumor generation_ -- A line chart showing the count of times that a new rumor is created. This is useful to see the rate of rumor generation as the baseline dynamic that drives new rumor adoption and the overall count of rumors heard.
- _Rumor source_ -- A line chart showing the relative adoption rate of audience agents for whether they adopted a rumor from an elite or from the social network. This is also compared to the chart of agents who have not yet adopted any rumors.

## THINGS TO NOTICE

It is easier to see some of the interesting behavior when you slow the model down.

As elites adopt traded-up rumors and echo them back to the audiences, you can see staggered "regimes" of mass rumor adoption that quickly spread across the entire network. A newly generated rumor might be slowly passed around the social network, but as soon as it is picked up and echoed back by the elites it gets disperesed quickly and totally to all of the elite-exposed agents. You can visually see this occur in the world, and by looking at the "Rumors heard" line chart.

When rumor dissipation is turned on, rumors in the social network fluctuate without settling into a pattern of total rumor adoption. However for audience agents who have exposure to elite influence, the repeated broadcasting of new and old rumors constantly reinforces the "frame" of rumors and counteracts the ongoing dissipation of rumors. You can visually see this in the world by comparing the color of agents with and without elite exposure.

Sometimes specific rumors don't catch on. Either they fail to get randomly generated, or they aren't traded up, or they are forgotten. It is possible that in a given execution, only a handful of the total rumors catch on and reach full information disperal, while other times all of the rumors will eventually get fully adopted. Note: It is not yet clear why this happens. It is possible that this is an artifact of the rumor creation procedure instead of being a meaningful model dyname. More testing and instrumentation is needed to better understand the behavior.

Without rumor dissipation, the model is essentially a runaway reinforcing feedback loop. It still demonstrates interesting patterns like staggered regimes, but having a countervailing stabilizing feedback loops makes the overall system dynamics more interesting.

## THINGS TO TRY

Try setting up the model with different variants of elite exposure distribution and noting the effect this has on rumor adoption.

Try changing the relative balances of `elite-influence`, `social-influence`, `trade-up-influence`, and `rumor-generation` and seeing what effect this has on adoption and dispersal through the whole network.

Try turning rumor `dissipation-rate` down to zero or up really high. How much adoption influence is necessary for the amplifying feedback loop of accumulating influence to continue dominating the stabilizing loop of rumor dissipation?

## EXTENDING THE MODEL

This model could be extended in a number of ways:

We could expliclitly model the process by which newly generated rumors are "traded up" to elite agents instead of this occurring automatically outside of the social network. We could also include the elies as part of the network itself instead of leaving them solely as a disconnected media influence.

Influencers themselves could be modeled in a manner that more closely resembles real-world patterns of social network influence. For example the set of agents that are selected to be influencers could be weighted to be drawn from the top end of the set of agents with a higher degree of connectivity within the network. Additionally we don't model influencers as having any particular influence within the context of social network adoption, but real-world influencers would certainly have more peer-to-peer influence.

The rumor generation process itself is pretty naive and not informed by any real world understanding of participatory rumors and conspiracy theories (e.g. Mike Caulfield's concept of "trope-field fit"). We could more explicitly model how rumors are created relative to events and ongoing narratives.

## NETLOGO FEATURES

This model makes use of the NetLogo network extension to simulate the social network connection between audience agents.

The model also makes significant use of the third-party NetLogo bitstring extension in order to model rumor adoption. See the [netlogo-bitstring documentation](https://github.com/garypolhill/netlogo-bitstring/tree/nl6) for more details on how this extension works.

## RELATED MODELS

This model draws from and builds on foundational mechanics for simulating information dispersal in a network from two other models from the Modeling Commons:

- [The Spread of a Meme Across a Social Network](http://modelingcommons.org/browse/one_model/4424) by Kristen Amaddio

- [Correcting Information - delay and media effects](http://modelingcommons.org/browse/one_model/5125) by Kjirste Morrell


## CREDITS AND REFERENCES

Rand, W. Introduction to Agent-Based Modeling (Summer 2017) Unit 4, Model. https://s3.amazonaws.com/complexityexplorer/ABMwithNetLogo/model-7.nlogo 7:Influentials.

Starbird, K., et al. (2021) ["What is participatory disinformation?"](https://www.cip.uw.edu/2021/05/26/participatory-disinformation-kate-starbird/
). Center for an Informed Public, University of Washington, Seattle, WA.

Wilensky, U. (2005). NetLogo Preferential Attachment model. http://ccl.northwestern.edu/netlogo/models/PreferentialAttachment. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern Institute on Complex Systems, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2021 Scott Johnson.

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

This model was submitted as a student project for the Intro to Agent-Based Modeling class, summer 2021, offered by Santa Fe Institute and taught by William Rand.
