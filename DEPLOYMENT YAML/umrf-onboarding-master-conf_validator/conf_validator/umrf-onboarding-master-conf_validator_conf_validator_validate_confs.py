from __future__ import print_function
import os, sys, re
import datetime as dt
import pytz
from time import time, localtime, gmtime, strftime, strptime
from pprint import pprint

def makedict(stanza):
	d = {}
	for line in stanza:
		if '=' in line:
			l = line.strip().split('=')
			d[l[0].strip(' ')] = l[1].strip(' ')
	return d

def parsefile(file):
	with open(file) as f:
		lines = f.read()

	lines = lines.strip().split('\n\n')
	for i in range(len(lines)):
		lines[i] = lines[i].split('\n')

	return lines

def utctime():
	return pytz.utc.localize(dt.datetime.utcnow())

def csttime():
	csttime = utctime().astimezone(pytz.timezone("US/Central"))
	return csttime

def currenttime():
	return csttime().strftime('%F %T %z')

if __name__ == '__main__':

	print(currenttime(),'INFO: Checking arguments')

	# check that script is given proper arguments of one inputs and one props
	try:
		inputs = sys.argv[1]
		props = sys.argv[2]
	except:
		err = ('ERROR: Usage is `python ' + sys.argv[0].split('/')[-1] + 
			' inputs.conf props.conf`')
		print(currenttime(),err)
		print(currenttime(),'INFO: Exiting program')
		exit()
	if not (os.path.exists(inputs) and os.path.exists(props)):
		print(currenttime(),'ERROR: File not found')
		print(currenttime(),'INFO: Exiting program')
		exit()

	print(currenttime(),'INFO: Checking inputs')

	inputs = parsefile(inputs)

	# check each stanza for monitor statement 
	# create dictionaries of fields and values
	inputs_dicts = []
	for line in inputs:
		if not re.search('\[monitor\:\/\/\/.+\]',line[0]):
			print(currenttime(),'ERROR: Incorrect monitor statement')
		d = makedict(line[1:])
		inputs_dicts.append(d)		
		# check that all fields have values
		if '' in d.values():
			print(currenttime(),
				'ERROR: Must have values for all fields')

	# check that each stanza has index, sourcetype, and disabled fields
	dictsets = [set(d.keys()) for d in inputs_dicts]
	if set.intersection(*dictsets) != set(['index','sourcetype','disabled']):
		print(currenttime(),'ERROR: Required fields not present')
		print(currenttime(),'INFO: Exiting program')
		exit()

	# add each inputs sourcetype to set to later check against sourcetypes in props
	inputs_srctypes = set([d['sourcetype'] for d in inputs_dicts])

	# check indexes are the same across stanzas
	if len(set([d['index'] for d in inputs_dicts])) != 1:
		print(currenttime(),
			'ERROR: Different indexes across stanzas')
	disabled = set([d['disabled'] for d in inputs_dicts])
	# check that disabled=false for all stanzas
	if len(disabled) != 1 or disabled.pop() != 'false':
		print(currenttime(),
			'ERROR: "disabled" should be set to "false" for all stanzas')

	# pprint(inputs)

	print(currenttime(),'INFO: Checking props')

	props = parsefile(props)

	fields = ['ADD_EXTRA_TIME_FIELDS', 'ANNOTATE_PUNCT', 'AUTO_KV_JSON', 
	'BREAK_ONLY_BEFORE', 'BREAK_ONLY_BEFORE_DATE', 'CHARSET', 'CHECK_FOR_HEADER', 
	'CHECK_METHOD', 'CURRENT', 'DATETIME_CONFIG', 'DEPTH_LIMIT', 'EVENT_BREAKER', 
	'EVENT_BREAKER_ENABLE', 'FIELD_DELIMITER', 'FIELD_HEADER_REGEX', 'FIELD_NAMES', 
	'FIELD_QUOTE', 'HEADER_FIELD_ACCEPTABLE_SPECIAL_CHARACTERS', 
	'HEADER_FIELD_DELIMITER', 'HEADER_FIELD_LINE_NUMBER', 'HEADER_FIELD_QUOTE', 
	'HEADER_MODE', 'INDEXED_EXTRACTIONS', 'JSON_TRIM_BRACES_IN_ARRAY_NAMES', 
	'KV_MODE', 'KV_TRIM_SPACES', 'LEARN_MODEL', 'LEARN_SOURCETYPE', 'LINE_BREAKER', 
	'LINE_BREAKER_LOOKBEHIND', 'MATCH_LIMIT', 'MAX_DAYS_AGO', 'MAX_DAYS_HENCE', 
	'MAX_DIFF_SECS_AGO', 'MAX_DIFF_SECS_HENCE', 'MAX_EVENTS', 
	'MAX_TIMESTAMP_LOOKAHEAD', 'METRICS_PROTOCOL', 'MISSING_VALUE_REGEX', 
	'MUST_BREAK_AFTER', 'MUST_NOT_BREAK_AFTER', 'MUST_NOT_BREAK_BEFORE', 
	'NO_BINARY_CHECK', 'PREAMBLE_REGEX', 'PREFIX_SOURCETYPE', 'SEGMENTATION', 
	'SHOULD_LINEMERGE', 'TIMESTAMP_FIELDS', 'TIME_FORMAT', 'TIME_PREFIX', 
	'TRUNCATE', 'TZ', 'TZ_ALIAS']

	# check first line of each stanza for proper sourcetype format
	# add each props sourcetype to set to check against sourcetypes in inputs
	props_dicts = []
	props_srctypes = set()
	for line in props:
		if not re.search('\[fedex\:[a-z]+\:[a-z]+\]',line[0]):
			print(currenttime(),
				'ERROR: Incorrect sourcetype format')
		d = makedict(line[1:])
		props_dicts.append(d)
		props_srctypes.add(line[0].strip('[]'))
		# check that all fields have values
		if '' in d.values():
			print(currenttime(),
				'ERROR: Must have values for all fields')

	# print(props_dicts)

	for d in props_dicts:
		# check all props stanzas have a line breaker
		if 'LINE_BREAKER' not in d.keys():
			print(currenttime(),
				'ERROR: LINE_BREAKER not present in props stanza')
		# check all field names are valid in props stanza
		for field in d.keys():
			if field not in fields:
				print(currenttime(),
					'ERROR: Incorrect field name in props stanza')

	# check for consistency in sourcetypes across inputs and props
	if inputs_srctypes != props_srctypes:
		print(currenttime(),
			'ERROR: Sourcetypes inconsistent across inputs and props')

	# pprint(props)

	print(currenttime(),'INFO: Exiting program')
