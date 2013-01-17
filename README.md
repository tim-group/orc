  * Orc: [![Orc Build Status](https://travis-ci.org/youdevise/orc.png)](https://travis-ci.org/youdevise/orc)

  * Deployapp: [![Deployapp Build Status](https://travis-ci.org/youdevise/deployapp.png)](https://travis-ci.org/youdevise/deployapp)

Description
-----------

Orc is a model driven orchestration tool for the deployment of application clusters.

It is written in ruby and currently uses MCollective as its transport for communication with its agents.

You can read more about how it's designed, and problems it's meant to solve in a series of blog posts on our company tech blog:

  * [Standardized application infrastructure contracts](https://devblog.timgroup.com/2012/07/17/standardized-application-infrastructure-contracts/)
  * [part 2 - towards continuous deployment](https://devblog.timgroup.com/2012/09/03/standardized-application-infrastructure-contracts-part-2-towards-continuous-deployment/)
  * [Introducing Orc and it's agents](https://devblog.timgroup.com/2012/12/20/introducing-orc-and-its-agents/)

Dependencies
------------

It is expected to be used with the mcollective agent found here:

  * https://github.com/youdevise/deployapp

and the tatin service here:

  * https://github.com/netmelody/tatin

Installation
------------

FIXME - todo!

Roadmap
-------

Orc
===

  * Fix looping 100 times by failing fast if an instance doesn't start.

  * Factor out WebApp as a type so that we can support database migrations

  * Flatten with deployapp code so that the CLI is the same implementation as
    Deployapp just with a remote engine, rather than the same logic re-implemented
    for remote and local cases.

Deployapp
=========

   * Fix to run on ruby 1.9.3

   * Fix namespacing / installation (gem package?)

   * Fix artifact resolver to be pluggable (other backends, and other artifact types)

   * Fix application launcher to be pluggable (able to launch non-java apps)

   * Make participation service pluggable, and implement other examples

   * Fix / cleanup configuration file parsing + defaults so that they're passed in properly from config.

