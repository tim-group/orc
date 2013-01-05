Orc
===

Description
-----------

Orc is a model driven orchestration tool for the deployment of application clusters.

It is written in ruby and currently uses MCollective as its transport for communication with its agents.

It is expected to be used with the mcollective agent found here:

  https://github.com/youdevise/deployapp

and the tatin service here:

  https://github.com/netmelody/tatin

Roadmap
-------

Merge transient state with live state when forming model, so that more intelligent decisions can be made (ie dont loop forever)

Use health from WebApps to determine whether to enable participation (depends on above)

Factor out WebApp as a type so that we can support databases

