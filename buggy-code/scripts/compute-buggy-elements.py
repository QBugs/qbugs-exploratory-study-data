#!/usr/bin/env python
#
# ------------------------------------------------------------------------------
# This script computes the set of buggy components (as the ones described in the
# [Python's AST](https://docs.python.org/3/library/ast.html) documentation) per # buggy line of code of a given buggy file.  The set of buggy components is then
# written to the provided output file.  The structure of the output file is the
# following:
#     buggy_line_number,buggy_component
#     149,List
#     151,Constant
#     151,List
#     151,Call
#     151,Expr
#     151,Name
#     151,Attribute
#     152,Constant
#     ...
#
# Usage:
# compute-buggy-elements.py
#   --buggy-file-path <path>
#   --buggy-lines-file-path <path>
#   --output-file <path>
# ------------------------------------------------------------------------------

import argparse
import ast
import os
import pathlib
import re
import sys

# ------------------------------------------------------------------------- Args

parser = argparse.ArgumentParser(description='Computes set of buggy components.')
parser.add_argument('--buggy-file-path', action='store', help="File path with the buggy source code", required=True, type=pathlib.Path)
parser.add_argument('--buggy-lines-file-path', action='store', help="File path with the set of buggy line numbers", required=True, type=pathlib.Path)
parser.add_argument('--output-file', action='store', help="Output file path", required=True, type=pathlib.Path)
args = parser.parse_args()

buggy_file = os.path.abspath(args.buggy_file_path.as_posix())
buggy_line_numbers_file = os.path.abspath(args.buggy_lines_file_path.as_posix())
output_file = args.output_file.as_posix()

# ------------------------------------------------------------------------- Main

# Read buggy line numbers
buggy_line_numbers = set()
with open(buggy_line_numbers_file, 'r') as f:
  for line in f:
    buggy_line_numbers.add(int(line.rstrip()))
  f.close()

# Load buggy file and compute the set of buggy components per buggy line
buggy_components = {}
with open(buggy_file, 'r') as f:
  for node in ast.walk(ast.parse(f.read())):
    if isinstance(node, ast.expr) or isinstance(node, ast.stmt):
      start_line_number = node.lineno
      if start_line_number in buggy_line_numbers:
        if start_line_number not in buggy_components:
            buggy_components[start_line_number] = set()
        node_type = str(type(node))
        node_simple_name = re.findall(r"_ast.(.*)'", node_type)[0]
        buggy_components[start_line_number].add(node_simple_name)
  f.close()

# Write set of buggy line numbers and correspondent buggy components to the output file
with open(output_file, 'w') as f:
  f.write('buggy_line_number,buggy_component\n')
  for buggy_line_number in sorted(buggy_components.keys()):
    for buggy_component in buggy_components[buggy_line_number]:
      f.write('%d,%s\n' %(buggy_line_number, buggy_component))
  f.close()

sys.exit()

# EOF
