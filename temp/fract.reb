rebol [
	name: fract
	type: module
	exports: [
		fract
	]
]

fract: function [
	{turns the fraction of a decimal into 0-99}
	d [decimal!]
][
	d: d + .001
	to integer! 100 * (d - to integer! d)
]
