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

        sorted :created_at

  - If you want to partition the index based on an attribute:

        sorted :created_at, :group_by => :site_id


You can use both indices for the same attribute, as the partition keys are
namespaced by the `group_by` attribute.

You will need to resave every model if they already exist for the index to get
built.

The ranking attribute must be of a type that responds to `to_f`.


Usage
-----

To query the sorted index, use the `sorted_find` class method.

    >> Post.sorted_find(:created_at, site_id: "ar")

This returns an `Ohm::SortedSet`, similiar to an `Ohm::Set` but backed by a sorted
set.

To limit the results to a certain score range, use the `between` method.
This and the following methods return a new copy of the set object, but data
is not read until it is necessary.

    >> Post.sorted_find(:created_at, site_id: "ar").between(start_time, end_time)

To take a slice of the results, use the `slice` method. This returns a new copy
of the set which will pass its `offset` and `count` parameters to Redis.

    >> Post.sorted_find(:created_at, site_id: "ar").slice(2, 4)


Requirements
------------

This plugin works with Ohm versions higher than 0.1.3.


Acknowledgements
----------------

Many thanks to Damian Janowski (https://github.com/djanowski)
