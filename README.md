ohm-sorted
==========

[![Gem Version](https://badge.fury.io/rb/ohm-sorted.png)](http://badge.fury.io/rb/ohm-sorted)
[![Build Status](https://travis-ci.org/educabilia/ohm-sorted.png?branch=master)](https://travis-ci.org/educabilia/ohm-sorted)
[![Code Climate](https://codeclimate.com/github/educabilia/ohm-sorted.png)](https://codeclimate.com/github/educabilia/ohm-sorted)

Sorted indexes for Ohm


Setup
-----

1. Include the `Callbacks` and `Sorted` modules in your model:

		include Ohm::Callbacks 
		include Ohm::Sorted

2. Add the sorted indices you want to your model:

    - If you want a complete index:

    		sorted :ranking

    - If you want to partition the index based on an attribute:

    		sorted :ranking, :group_by => :status


You will need to resave every model if they already exist.

Usage
-----

To query the sorted index, use the `sorted_find` class method.

    >> Post.sorted_find(:ranking, status: "draft")


This returns an Ohm::SortedSet, similiar to an Ohm::Set but backed by a sorted
set. Both Ohm::SortedSet and Ohm::Set share the Ohm::BasicSet base class.


Requirements
------------

This plugin works with Ohm versions higher than 0.1.3.


Acknowledgements
----------------

Many thanks to Damian Janowski (https://github.com/djanowski)
