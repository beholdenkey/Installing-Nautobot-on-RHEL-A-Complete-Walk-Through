# Installing Nautobot on Red Hat Enterprise Linux: A Complete Walk Through

>**A quick disclaimer I did not develop or own any rights to the Nautobot application. However I this guide is a contribution to the community that uses the Nautobot application.**

## Introduction

Initially, I didn't start out working with Nautobot. I started working with the predecessor [Netbox](https://github.com/netbox-community/netbox), which is where Nautobot was forked from. I found over time that I started working with Nautobot and integrating it within a lot of the processes in place. I found that it was just a lot friendly when it came to integrating with services such as Keycloak using python social auth and the ability to sync with a Git source which supports the ability to utilize the idealogy of infrastructure as code. Over time, I realized that what I was doing with Nautobot differed significantly from the available guides. So I decided that I would start to do my documentation. I hope that this guide proves helpful to those who may have found themselves in similar situations.

## Expectations

If you are a beginner to Linux, python, Django, Postgres, Redis, or any of the pieces that make Nautobot what it is, this guide may not be for you. However, the Network To Code team has excellent documentation. This guide serves the purpose of setting up a Production Nautobot server on a Red Hat Enterprise Linux operating system and applying various security policies such as the DISA Security Technical Implementation Guide.

## Notable Sources

- [Nautobot GitHub](https://github.com/nautobot/nautobot)
  - [Nautobot Read the Docs](https://nautobot.readthedocs.io/en/stable/)
- [Netbox](https://github.com/netbox-community/netbox)
