Orc
===

[![Orc Build Status](https://travis-ci.org/youdevise/orc.png)](https://travis-ci.org/youdevise/orc)

[![Deployapp Build Status](https://travis-ci.org/youdevise/deployapp.png)](https://travis-ci.org/youdevise/deployapp)

Description
-----------

Orc is a model driven orchestration tool for the deployment of application clusters.

It is written in ruby and currently uses MCollective as its transport for communication with its agents.

You can read more about how it's designed, and problems it's meant to solve in a series of blog posts on our company tech blog:

  https://devblog.timgroup.com/2012/07/17/standardized-application-infrastructure-contracts/

  https://devblog.timgroup.com/2012/09/03/standardized-application-infrastructure-contracts-part-2-towards-continuous-deployment/

  https://devblog.timgroup.com/2012/12/20/introducing-orc-and-its-agents/

Dependencies
------------

It is expected to be used with the mcollective agent found here:

  https://github.com/youdevise/deployapp

and the tatin service here:

  https://github.com/netmelody/tatin

Roadmap
-------

Merge transient state with live state when forming model, so that more intelligent decisions can be made (ie dont loop forever)

Use health from WebApps to determine whether to enable participation (depends on above)

Factor out WebApp as a type so that we can support databases


