# participatory-disinformation-abm
A NetLog agent-based model simulating participatory disinformation

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

The original real-world particpiatory disinformation phenomenon also contains other dynamics such as the audience building a sense of collective grievance, and political elites mobilizing their agrieved audiences into collective action. These features are out of the scope of this model and are not represented in the simulation.

## HOW IT WORKS

### Agents

This model contains three types of agent breeds: elites, regulars, and influencers.

`Elites` represent the political elite agents whose rumors are adopted by the audience (`regular` and `influencer`) agents.

`Regulars` represent the audience agents who generate and spread new rumors amongst each other in a network.

`Influencers` represent different audience agents whose rumors will be adopted by the `elites`, and also who also spread rumors amongst the network.

### Agent properties

Every agent, regardless of its breed, posesses a property called `rumors-heard?`.



[describe agent properties]

[describe agent actions]

[describe model environment]

[describe order of events in SETUP]

[describe order of events in GO]

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

[describe inputs]

[describe outputs]

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

[staggered regimes of mass adoption of newly generated rumors after they have been traded up by the influencers and broadcasted by the elites]
[repeated adoption of rumors by agents who have exposure to elite influence reinforces the frame of the rumors and counteracts dissipation of rumors displayed by non-exposed agents]
[sometimes specific rumors won't catch on or get traded up

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

[change the elite exposure distribution]
[change the relative balance of elite and social influence]
[turn rumor dissipation down to zero or up high]

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

[explicitly model the process of trading up newly generated rumors through the network itself in order to reach the elites, instead of this happening "outside" of the network environment of the model]
[include elites as both part of the network and as a disconnected media force]
[change the way influencers are modeled so that it more closely matches real-world patterns of influencers, for example by making it more likely that agents that are selected as influencers are the ones with a higher degree of connection within the network]

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

[network extension]
[bitstring extension to model different rumors]

netlogo-bitstring documentation: https://github.com/garypolhill/netlogo-bitstring/tree/nl6


## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

The Spread of a Meme Across a Social Network by Kristen Amaddio

http://modelingcommons.org/browse/one_model/4424#model_tabs_browse_info

Correcting Information - delay and media effects by Kjirste Morrell

http://modelingcommons.org/browse/one_model/5125#model_tabs_browse_info

[spread of a meme in a social network]
[correcting information]

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)

[participatory disinformation studies]
[related models]