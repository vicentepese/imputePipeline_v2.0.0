"""
scripts to parse impute2 output correct suffixes or prefixes in snpnames
@author: Aditya Ambati ambati@stanford.edu, Mignot Lab, Stanford University
"""
import re
import sys
import argparse
import gzip
import datetime
import os
import glob
dttime=datetime.datetime.now().strftime ("%Y%m%d")
parser = argparse.ArgumentParser(description='clean impute files  data')
parser.add_argument('-F', required=True, help='A single chr impute file')
parser.add_argument('-CHR', required=True, help='A numeric indicating the chromosome number')
parser.add_argument('-VAR', required=True, help='A string that has to be removed from the rsid')
### parse the arguments
args=parser.parse_args()
file_in = args.F
chrnum = args.CHR
var_name = args.VAR
def clean_impute(file_in, chrnum, var_name):
	line_n = 0
	line_buffer = 0
	snptrack = 0
	if '.gz' in file_in:
		infile = gzip.open(file_in, 'rb')
		clean_filename = file_in.replace('impute.gz', 'CLEAN.impute.gz')
		clean_file = gzip.open(clean_filename, 'wb')
	else:
		infile = open(file_in, 'rb')
		clean_filename = file_in.replace('.impute', 'CLEAN.impute')
		clean_file = open(clean_filename, 'w')
	for line in infile:
		line_n += 1
		if line_n == 10000:
			line_buffer += 10000
			line_n = 0
			print('PROCESSED LINES {} & CLEANED SNP NAMES {} '.format(line_buffer, snptrack))
		parse_line = line.split(' ')
		if var_name in parse_line[1]:
			snptrack += 1
			assert var_name in parse_line[1]
			parse_line[1] = parse_line[1].replace(var_name, '')
			parse_line[0] = chrnum
			processed_line = ' '.join(parse_line)
			clean_file.write(processed_line)
		else:
			parse_line[0] = chrnum
			processed_line = ' '.join(parse_line)
			clean_file.write(processed_line)
	clean_file.close()
	print('Processed file {} and cleaned {} snps and wrote a new file {} '.format(file_in, snptrack, clean_filename))


if __name__ == '__main__': clean_impute(file_in=file_in, chrnum=chrnum, var_name=var_name)
