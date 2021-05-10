#!/usr/bin/env python3

import sys

def reformat(inputfile, inputconfig):
	with open(inputfile, 'r') as infile:
		sample_dict = {}
		for line in infile:
			columns = line.strip().split(',')
			samplename = columns[0]
			deidentified = columns[1]
			collection = columns[4]
			leftread = columns[3]
			rightread = columns[4]
#			json_line = f'{"left":{"{samplename}","{deidentified}","{collection}}","right":{"left": "{leftread}", "right": "{rightread}"}}'
			json_line = '    {"left": ["' + samplename + '","' + deidentified + '","' + collection +'"],\n    "right": {\n        "left": "' + leftread + '",\n        "right": "' + rightread + '"}}'
			sample_dict[samplename] = json_line
	outfile = open('input_samples.json', 'w')
	outstring = '{"refbased_viral_assembly.inputSamples": [\n'
	for samplename,sampleinfo in sample_dict.items():
#		print(f'{sampleinfo},')
#		outfile.write(f'{sampleinfo},\n')
		outstring += f'{sampleinfo},\n'
	outstring = outstring[:-2]
	outstring += '\n    ]'
	outfile.write(outstring)

	with open(inputconfig, 'r') as configfile:
		for line in configfile:
			outfile.write(line)
	outfile.write('}hello')
	configfile.close()
	infile.close()
	outfile.close()

infile = sys.argv[1]
config = sys.argv[2]

reformat(infile, config)
